-- =============================================================
-- DISTRIGOLF - Esquema de Base de Datos Supabase/PostgreSQL
-- =============================================================

-- 1. EXTENSIONES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. TABLAS BASE

-- 2.1 Perfiles de usuarios (extiende auth.users de Supabase)
CREATE TABLE perfiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    nombre TEXT NOT NULL,
    telefono TEXT,
    tipo_vendedor TEXT NOT NULL CHECK (tipo_vendedor IN ('MAYORISTA', 'TAT')),
    activo BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.2 Zonas geográficas
CREATE TABLE zonas (
    id SERIAL PRIMARY KEY,
    nombre TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.3 Asignación vendedor-zona (híbrida: por zona)
CREATE TABLE vendedor_zonas (
    vendedor_id UUID REFERENCES perfiles(id) ON DELETE CASCADE,
    zona_id INTEGER REFERENCES zonas(id) ON DELETE CASCADE,
    PRIMARY KEY (vendedor_id, zona_id)
);

-- 2.4 Clientes
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    codigo TEXT,
    dv TEXT,
    nombre TEXT NOT NULL,
    direccion TEXT,
    email TEXT,
    ciudad TEXT,
    zona_id INTEGER REFERENCES zonas(id),
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.5 Asignación vendedor-cliente (híbrida: individual)
CREATE TABLE vendedor_clientes (
    vendedor_id UUID REFERENCES perfiles(id) ON DELETE CASCADE,
    cliente_id INTEGER REFERENCES clientes(id) ON DELETE CASCADE,
    PRIMARY KEY (vendedor_id, cliente_id)
);

-- 2.6 Productos (catálogo único)
CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    referencia TEXT NOT NULL UNIQUE,
    nombre TEXT NOT NULL,
    cod_linea TEXT,
    nombre_linea TEXT,
    cod_medida TEXT DEFAULT 'UND',
    volumen DECIMAL(10,2),
    grados DECIMAL(10,2),
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.7 Precios Mayoristas
CREATE TABLE precios_mayorista (
    id SERIAL PRIMARY KEY,
    producto_id INTEGER NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    esquema TEXT,
    bruto DECIMAL(15,2) DEFAULT 0,
    unitario DECIMAL(15,2) DEFAULT 0,
    max_descuento DECIMAL(15,2) DEFAULT 0,
    minimo DECIMAL(15,2) DEFAULT 0,
    impuestos DECIMAL(15,2) DEFAULT 0,
    UNIQUE (producto_id, esquema)
);

-- 2.8 Precios Tienda a Tienda
CREATE TABLE precios_tat (
    id SERIAL PRIMARY KEY,
    producto_id INTEGER NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    esquema TEXT,
    bruto DECIMAL(15,2) DEFAULT 0,
    unitario DECIMAL(15,2) DEFAULT 0,
    max_descuento DECIMAL(15,2) DEFAULT 0,
    minimo DECIMAL(15,2) DEFAULT 0,
    impuestos DECIMAL(15,2) DEFAULT 0,
    UNIQUE (producto_id, esquema)
);

-- 2.9 Pedidos
CREATE TABLE pedidos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendedor_id UUID NOT NULL REFERENCES perfiles(id),
    cliente_id INTEGER NOT NULL REFERENCES clientes(id),
    fecha TIMESTAMPTZ DEFAULT NOW(),
    estado TEXT NOT NULL DEFAULT 'BORRADOR' CHECK (estado IN ('BORRADOR', 'CONFIRMADO', 'SINCRONIZADO', 'ENTREGADO')),
    total DECIMAL(15,2) DEFAULT 0,
    firma TEXT,
    notas TEXT,
    latitud DECIMAL(10,7),
    longitud DECIMAL(10,7),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.10 Detalle del pedido
CREATE TABLE detalle_pedido (
    id SERIAL PRIMARY KEY,
    pedido_id UUID NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
    producto_id INTEGER NOT NULL REFERENCES productos(id),
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(15,2) NOT NULL,
    subtotal DECIMAL(15,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. ÍNDICES
CREATE INDEX idx_clientes_zona ON clientes(zona_id);
CREATE INDEX idx_clientes_nombre ON clientes(nombre);
CREATE INDEX idx_productos_referencia ON productos(referencia);
CREATE INDEX idx_productos_linea ON productos(nombre_linea);
CREATE INDEX idx_precios_mayorista_producto ON precios_mayorista(producto_id);
CREATE INDEX idx_precios_tat_producto ON precios_tat(producto_id);
CREATE INDEX idx_pedidos_vendedor ON pedidos(vendedor_id);
CREATE INDEX idx_pedidos_cliente ON pedidos(cliente_id);
CREATE INDEX idx_pedidos_estado ON pedidos(estado);
CREATE INDEX idx_pedidos_fecha ON pedidos(fecha);
CREATE INDEX idx_detalle_pedido ON detalle_pedido(pedido_id);
CREATE INDEX idx_vendedor_zonas_vendedor ON vendedor_zonas(vendedor_id);
CREATE INDEX idx_vendedor_clientes_vendedor ON vendedor_clientes(vendedor_id);

-- 4. FUNCIONES Y TRIGGERS

-- 4.1 Actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION actualizar_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_perfiles_updated
    BEFORE UPDATE ON perfiles
    FOR EACH ROW EXECUTE FUNCTION actualizar_timestamp();

CREATE TRIGGER trigger_clientes_updated
    BEFORE UPDATE ON clientes
    FOR EACH ROW EXECUTE FUNCTION actualizar_timestamp();

CREATE TRIGGER trigger_productos_updated
    BEFORE UPDATE ON productos
    FOR EACH ROW EXECUTE FUNCTION actualizar_timestamp();

CREATE TRIGGER trigger_pedidos_updated
    BEFORE UPDATE ON pedidos
    FOR EACH ROW EXECUTE FUNCTION actualizar_timestamp();

-- 4.2 Calcular total del pedido automáticamente
CREATE OR REPLACE FUNCTION calcular_total_pedido()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE pedidos
    SET total = (
        SELECT COALESCE(SUM(subtotal), 0)
        FROM detalle_pedido
        WHERE pedido_id = COALESCE(NEW.pedido_id, OLD.pedido_id)
    )
    WHERE id = COALESCE(NEW.pedido_id, OLD.pedido_id);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_detalle_calcular_total
    AFTER INSERT OR UPDATE OR DELETE ON detalle_pedido
    FOR EACH ROW EXECUTE FUNCTION calcular_total_pedido();

-- 5. POLÍTICAS DE SEGURIDAD (RLS)

-- 5.1 Perfiles: solo lectura para el propio usuario, admin todo
ALTER TABLE perfiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios pueden ver su propio perfil"
    ON perfiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Usuarios pueden crear su perfil"
    ON perfiles FOR INSERT
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Admin puede gestionar perfiles"
    ON perfiles FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM perfiles
            WHERE id = auth.uid() AND tipo_vendedor = 'ADMIN'
        )
    );

-- 5.2 Clientes: vendedores ven sus clientes asignados
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Vendedores ven clientes de sus zonas o asignados"
    ON clientes FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM perfiles WHERE id = auth.uid() AND tipo_vendedor = 'ADMIN'
        )
        OR EXISTS (
            SELECT 1 FROM vendedor_zonas vz
            JOIN zonas z ON z.id = vz.zona_id
            WHERE vz.vendedor_id = auth.uid() AND clientes.zona_id = z.id
        )
        OR EXISTS (
            SELECT 1 FROM vendedor_clientes vc
            WHERE vc.vendedor_id = auth.uid() AND vc.cliente_id = clientes.id
        )
    );

-- 5.3 Productos y precios: todos los vendedores autenticados ven todo
ALTER TABLE productos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Productos visibles para autenticados"
    ON productos FOR SELECT
    USING (auth.role() = 'authenticated');

ALTER TABLE precios_mayorista ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Precios mayorista visibles para autenticados"
    ON precios_mayorista FOR SELECT
    USING (auth.role() = 'authenticated');

ALTER TABLE precios_tat ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Precios TAT visibles para autenticados"
    ON precios_tat FOR SELECT
    USING (auth.role() = 'authenticated');

-- 5.4 Pedidos: cada vendedor ve sus propios pedidos
ALTER TABLE pedidos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Vendedores ven sus propios pedidos"
    ON pedidos FOR SELECT
    USING (vendedor_id = auth.uid());

CREATE POLICY "Vendedores crean sus pedidos"
    ON pedidos FOR INSERT
    WITH CHECK (vendedor_id = auth.uid());

CREATE POLICY "Vendedores actualizan sus pedidos"
    ON pedidos FOR UPDATE
    USING (vendedor_id = auth.uid())
    WITH CHECK (vendedor_id = auth.uid());

-- 5.5 Detalle de pedidos: mismo criterio que pedidos
ALTER TABLE detalle_pedido ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Detalle visible vía pedidos"
    ON detalle_pedido FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM pedidos
            WHERE pedidos.id = detalle_pedido.pedido_id
            AND pedidos.vendedor_id = auth.uid()
        )
    );

CREATE POLICY "Detalle creable vía pedidos"
    ON detalle_pedido FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM pedidos
            WHERE pedidos.id = detalle_pedido.pedido_id
            AND pedidos.vendedor_id = auth.uid()
        )
    );

-- 6. DATOS INICIALES

-- 6.1 Zonas desde el Excel
INSERT INTO zonas (nombre) VALUES
    ('MAICAO CENTRO Y MERCADO'),
    ('MAICAO DROGUERIAS'),
    ('MAICAO REMATES Y VARIOS'),
    ('MANAURE'),
    ('NORTE - URIBIA'),
    ('PERIFERIA MAICAO'),
    ('RIOHACHA MERCADOS Y CENTRO'),
    ('ZONA SUR');

-- 7. FUNCIONES RPC (Remote Procedure Calls)

-- 7.1 Obtener clientes asignados a un vendedor (por zona + individual)
CREATE OR REPLACE FUNCTION obtener_clientes_vendedor(p_vendedor_id UUID)
RETURNS TABLE(
    id INTEGER,
    codigo TEXT,
    dv TEXT,
    nombre TEXT,
    direccion TEXT,
    email TEXT,
    ciudad TEXT,
    zona_id INTEGER,
    zona_nombre TEXT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT
        c.id,
        c.codigo,
        c.dv,
        c.nombre,
        c.direccion,
        c.email,
        c.ciudad,
        c.zona_id,
        z.nombre AS zona_nombre
    FROM clientes c
    LEFT JOIN zonas z ON z.id = c.zona_id
    WHERE
        c.activo = true
        AND (
            -- Por zona asignada
            c.zona_id IN (
                SELECT vz.zona_id
                FROM vendedor_zonas vz
                WHERE vz.vendedor_id = p_vendedor_id
            )
            -- O por asignación individual
            OR c.id IN (
                SELECT vc.cliente_id
                FROM vendedor_clientes vc
                WHERE vc.vendedor_id = p_vendedor_id
            )
        )
    ORDER BY c.nombre;
END;
$$;

-- 7.2 Obtener reporte de ventas por periodo
CREATE OR REPLACE FUNCTION obtener_reporte_ventas(
    p_desde TIMESTAMPTZ DEFAULT NULL,
    p_hasta TIMESTAMPTZ DEFAULT NULL
) RETURNS TABLE(
    pedido_id UUID,
    vendedor_nombre TEXT,
    vendedor_email TEXT,
    cliente_nombre TEXT,
    total DECIMAL(15,2),
    fecha TIMESTAMPTZ,
    estado TEXT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        pf.nombre,
        pf.email,
        c.nombre,
        p.total,
        p.fecha,
        p.estado
    FROM pedidos p
    JOIN perfiles pf ON pf.id = p.vendedor_id
    JOIN clientes c ON c.id = p.cliente_id
    WHERE
        p.estado IN ('CONFIRMADO', 'SINCRONIZADO', 'ENTREGADO')
        AND (p_desde IS NULL OR p.fecha >= p_desde)
        AND (p_hasta IS NULL OR p.fecha <= p_hasta)
    ORDER BY p.fecha DESC;
END;
$$;
