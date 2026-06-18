"""
Asigna todas las zonas al vendedor TAT para que pueda ver clientes.
Ejecuta esto cuando crees un nuevo vendedor y no pueda ver la lista de clientes.
"""
import urllib.request, json
from urllib.error import HTTPError

URL = 'https://wsohgkyrtskshbinlfeg.supabase.co'
KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indzb2hna3lydHNrc2hiaW5sZmVnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MDg3MzM1OCwiZXhwIjoyMDk2NDQ5MzU4fQ.kCpMuu-2VxdNhuZVoxcPKBPX2y74TZH4W5x6eGEYhx4'
H = {'apikey': KEY, 'Authorization': 'Bearer ' + KEY, 'Content-Type': 'application/json'}

# 1. Get all vendedores (non-admin)
req = urllib.request.Request(URL + '/rest/v1/perfiles?select=id,email,nombre,tipo_vendedor,activo&tipo_vendedor=neq.ADMIN&order=nombre.asc', headers=H)
resp = urllib.request.urlopen(req)
vendedores = json.loads(resp.read().decode())

print("Vendedores disponibles:")
for i, v in enumerate(vendedores):
    print(f"  {i+1}. {v['nombre']} ({v['email']}) - {v['tipo_vendedor']}")

# 2. Let user choose which one to fix
# For now, fix the TAT one automatically
tat_vendors = [v for v in vendedores if v['tipo_vendedor'] == 'TAT']

if not tat_vendors:
    print("\nNo se encontraron vendedores TAT. Asignando a todos los vendedores sin zonas...")
    for v in vendedores:
        req_check = urllib.request.Request(URL + f"/rest/v1/vendedor_zonas?select=zona_id&vendedor_id=eq.{v['id']}", headers=H)
        resp_check = urllib.request.urlopen(req_check)
        zonas_asignadas = json.loads(resp_check.read().decode())
        if len(zonas_asignadas) == 0:
            tat_vendors.append(v)
else:
    print(f"\nVendedor TAT encontrado: {tat_vendors[0]['nombre']}")

# 3. Get all zones
req = urllib.request.Request(URL + '/rest/v1/zonas?select=id,nombre', headers=H)
resp = urllib.request.urlopen(req)
zonas = json.loads(resp.read().decode())

# 4. Assign all zones to each vendor without assignments
for v in tat_vendors:
    print(f"\nAsignando zonas a {v['nombre']} ({v['email']})...")
    asignadas = 0
    for z in zonas:
        body = json.dumps({'vendedor_id': v['id'], 'zona_id': z['id']}).encode()
        req_assign = urllib.request.Request(URL + '/rest/v1/vendedor_zonas', data=body, headers=H, method='POST')
        try:
            urllib.request.urlopen(req_assign)
            print(f"  [OK] Zona: {z['nombre']}")
            asignadas += 1
        except HTTPError as e:
            err = e.read().decode()
            if 'duplicate' in err.lower() or 'already exists' in err.lower():
                print(f"  [SKIP] Zona: {z['nombre']} (ya asignada)")
                asignadas += 1
            else:
                print(f"  [ERR] Zona: {z['nombre']} - Error: {err[:100]}")
    print(f"  Total: {asignadas}/{len(zonas)} zonas asignadas")

# 5. Verify
print("\n=== VERIFICACION ===")
for v in vendedores:
    req_check = urllib.request.Request(URL + f"/rest/v1/vendedor_zonas?select=zona_id&vendedor_id=eq.{v['id']}", headers=H)
    resp_check = urllib.request.urlopen(req_check)
    zonas_asignadas = json.loads(resp_check.read().decode())
    print(f"  {v['email']}: {len(zonas_asignadas)} zonas")

# 6. Test RPC for TAT
if tat_vendors:
    v = tat_vendors[0]
    body_rpc = json.dumps({'p_vendedor_id': v['id']}).encode()
    req_rpc = urllib.request.Request(URL + '/rest/v1/rpc/obtener_clientes_vendedor', data=body_rpc, headers={**H, 'Content-Type': 'application/json'}, method='POST')
    try:
        resp_rpc = urllib.request.urlopen(req_rpc)
        clientes = json.loads(resp_rpc.read().decode())
        print(f"\n  RPC para {v['email']}: {len(clientes)} clientes visibles")
    except HTTPError as e:
        print(f"\n  Error RPC: {e.read().decode()[:200]}")

print("\nListo! Ahora el vendedor TAT deberia poder ver los clientes.")
