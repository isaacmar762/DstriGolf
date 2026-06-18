import urllib.request, json
URL = 'https://wsohgkyrtskshbinlfeg.supabase.co'
KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indzb2hna3lydHNrc2hiaW5sZmVnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MDg3MzM1OCwiZXhwIjoyMDk2NDQ5MzU4fQ.kCpMuu-2VxdNhuZVoxcPKBPX2y74TZH4W5x6eGEYhx4'
H = {'apikey': KEY, 'Authorization': 'Bearer ' + KEY, 'Content-Type': 'application/json'}

# 1. Revertir la función RPC a la original
sql = """
CREATE OR REPLACE FUNCTION obtener_clientes_vendedor(p_vendedor_id UUID)
RETURNS TABLE(id INTEGER, codigo TEXT, dv TEXT, nombre TEXT, direccion TEXT, email TEXT, ciudad TEXT, zona_id INTEGER, zona_nombre TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT c.id, c.codigo, c.dv, c.nombre, c.direccion, c.email, c.ciudad, c.zona_id, z.nombre
    FROM clientes c
    LEFT JOIN zonas z ON z.id = c.zona_id
    WHERE c.activo = true
    AND (
        c.zona_id IN (SELECT vz.zona_id FROM vendedor_zonas vz WHERE vz.vendedor_id = p_vendedor_id)
        OR c.id IN (SELECT vc.cliente_id FROM vendedor_clientes vc WHERE vc.vendedor_id = p_vendedor_id)
    )
    ORDER BY c.nombre;
END;
$$;
"""
body = json.dumps({'query': sql}).encode()
req = urllib.request.Request(URL + '/rest/v1/rpc/pgexecute', data=body, headers={**H, 'Content-Type': 'application/json'}, method='POST')
try:
    urllib.request.urlopen(req)
except urllib.error.HTTPError:
    pass  # pgexecute no existe, usar SQL Editor manual

print("SQL RESTAURADO - Ve al SQL Editor y ejecuta el comando de arriba")

# 2. Obtener lista de zonas
req2 = urllib.request.Request(URL + '/rest/v1/zonas?select=id,nombre', headers=H)
resp2 = urllib.request.urlopen(req2)
zonas = json.loads(resp2.read().decode())
print("\nZonas disponibles:")
for z in zonas:
    print(f"  ID {z['id']}: {z['nombre']}")

# 3. Obtener el vendedor isaac@pruebas.com
req3 = urllib.request.Request(URL + "/rest/v1/perfiles?select=id,email,nombre&email=eq.isaac@pruebas.com", headers=H)
resp3 = urllib.request.urlopen(req3)
vendedores = json.loads(resp3.read().decode())
if vendedores:
    v = vendedores[0]
    print(f"\nVendedor encontrado: {v['nombre']} ({v['email']}) - ID: {v['id']}")

    # 4. Asignar a zona 1 (MAICAO CENTRO Y MERCADO)
    body4 = json.dumps({'vendedor_id': v['id'], 'zona_id': 1}).encode()
    req4 = urllib.request.Request(URL + '/rest/v1/vendedor_zonas', data=body4, headers=H, method='POST')
    try:
        urllib.request.urlopen(req4)
        print("  ✅ Asignado a zona: MAICAO CENTRO Y MERCADO (ID 1)")
    except urllib.error.HTTPError as e:
        print("  ⚠️  " + e.read().decode()[:200])
else:
    print("\n⚠️  No se encontró el vendedor isaac@pruebas.com")
