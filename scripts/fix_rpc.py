import urllib.request, json
URL = 'https://wsohgkyrtskshbinlfeg.supabase.co'
KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indzb2hna3lydHNrc2hiaW5sZmVnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MDg3MzM1OCwiZXhwIjoyMDk2NDQ5MzU4fQ.kCpMuu-2VxdNhuZVoxcPKBPX2y74TZH4W5x6eGEYhx4'
H = {'apikey': KEY, 'Authorization': 'Bearer ' + KEY, 'Content-Type': 'application/json'}

print("Ve al SQL Editor de Supabase y ejecuta esto:\n")

sql = """
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
DECLARE
    tiene_asignaciones BOOLEAN;
BEGIN
    -- Verificar si el vendedor tiene asignaciones
    SELECT EXISTS(
        SELECT 1 FROM vendedor_zonas WHERE vendedor_id = p_vendedor_id
        UNION ALL
        SELECT 1 FROM vendedor_clientes WHERE vendedor_id = p_vendedor_id
    ) INTO tiene_asignaciones;

    IF tiene_asignaciones THEN
        -- Solo clientes asignados
        RETURN QUERY
        SELECT DISTINCT
            c.id, c.codigo, c.dv, c.nombre, c.direccion,
            c.email, c.ciudad, c.zona_id, z.nombre
        FROM clientes c
        LEFT JOIN zonas z ON z.id = c.zona_id
        WHERE c.activo = true
        AND (
            c.zona_id IN (SELECT vz.zona_id FROM vendedor_zonas vz WHERE vz.vendedor_id = p_vendedor_id)
            OR c.id IN (SELECT vc.cliente_id FROM vendedor_clientes vc WHERE vc.vendedor_id = p_vendedor_id)
        )
        ORDER BY c.nombre;
    ELSE
        -- Sin asignaciones: devolver todos los clientes
        RETURN QUERY
        SELECT c.id, c.codigo, c.dv, c.nombre, c.direccion,
               c.email, c.ciudad, c.zona_id, z.nombre
        FROM clientes c
        LEFT JOIN zonas z ON z.id = c.zona_id
        WHERE c.activo = true
        ORDER BY c.nombre;
    END IF;
END;
$$;
"""

print(sql)
