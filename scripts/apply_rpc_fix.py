"""
Aplica el fix permanente al RPC obtener_clientes_vendedor.
Si no puede ejecutar SQL directamente, abre el navegador al SQL Editor de Supabase.
"""
import urllib.request, json
from urllib.error import HTTPError
import webbrowser
import subprocess, sys

URL = 'https://wsohgkyrtskshbinlfeg.supabase.co'
KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indzb2hna3lydHNrc2hiaW5sZmVnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MDg3MzM1OCwiZXhwIjoyMDk2NDQ5MzU4fQ.kCpMuu-2VxdNhuZVoxcPKBPX2y74TZH4W5x6eGEYhx4'
H = {'apikey': KEY, 'Authorization': 'Bearer ' + KEY, 'Content-Type': 'application/json'}

SQL = """
CREATE OR REPLACE FUNCTION obtener_clientes_vendedor(p_vendedor_id UUID)
RETURNS TABLE(
    id INTEGER, codigo TEXT, dv TEXT, nombre TEXT,
    direccion TEXT, email TEXT, ciudad TEXT,
    zona_id INTEGER, zona_nombre TEXT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    tiene_asignaciones BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM vendedor_zonas WHERE vendedor_id = p_vendedor_id
        UNION ALL
        SELECT 1 FROM vendedor_clientes WHERE vendedor_id = p_vendedor_id
    ) INTO tiene_asignaciones;

    IF tiene_asignaciones THEN
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

print("=== FIX PERMANENTE: RPC obtener_clientes_vendedor ===\n")
print("Este fix modifica la funcion RPC para que:")
print("  - Si el vendedor tiene zonas/clientes asignados -> solo ve esos")
print("  - Si NO tiene asignaciones -> ve TODOS los clientes")
print()

# Try to execute SQL via supabase-py
try:
    from supabase import create_client
    supabase = create_client(URL, KEY)
    
    # Try using the internal postgrest client to execute raw SQL
    # Supabase-py uses postgrest-py under the hood
    try:
        # Attempt to use the postgrest client directly
        postgrest = supabase.postgrest
        if hasattr(postgrest, 'request'):
            # postgrest-py >= 0.14
            print("Intentando ejecutar SQL via postgrest...")
            res = postgrest.request('POST', '/rpc/pgexecute', json={'query': SQL})
            print("  SQL ejecutado exitosamente!")
            print("Fix aplicado!")
            sys.exit(0)
    except Exception as e:
        print(f"  No se pudo ejecutar via postgrest: {e}")
except ImportError:
    print("supabase-py no disponible")

print("\nNo se pudo ejecutar el SQL automaticamente.")
print()

# Open Supabase dashboard SQL Editor
dashboard_url = "https://supabase.com/dashboard/project/wsohgkyrtskshbinlfeg/sql/new"
print(f"Abre el SQL Editor de Supabase en tu navegador:")
print(f"  {dashboard_url}")
print()

try:
    webbrowser.open(dashboard_url)
    print("Navegador abierto. Copia y pega el siguiente SQL:")
except Exception:
    print("Copia y pega el siguiente SQL en el SQL Editor:")

print()
print("=" * 70)
print(SQL)
print("=" * 70)
print()

# Alternative: also try to copy to clipboard
try:
    import pyperclip
    pyperclip.copy(SQL)
    print("SQL copiado al portapapeles! Solo pegalo en el SQL Editor y ejecutalo.")
except ImportError:
    print("Selecciona y copia el SQL de arriba, pegalo en el SQL Editor y ejecutalo.")
