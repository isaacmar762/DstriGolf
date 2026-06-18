import urllib.request, json
from urllib.error import HTTPError

URL = 'https://wsohgkyrtskshbinlfeg.supabase.co'
KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indzb2hna3lydHNrc2hiaW5sZmVnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MDg3MzM1OCwiZXhwIjoyMDk2NDQ5MzU4fQ.kCpMuu-2VxdNhuZVoxcPKBPX2y74TZH4W5x6eGEYhx4'
H = {'apikey': KEY, 'Authorization': 'Bearer ' + KEY, 'Content-Type': 'application/json'}

print("=== DIAGNOSTICO DE ASIGNACIONES ===\n")

# 1. Perfiles
req = urllib.request.Request(URL + '/rest/v1/perfiles?select=id,email,nombre,tipo_vendedor,activo&order=nombre.asc', headers=H)
resp = urllib.request.urlopen(req)
perfiles = json.loads(resp.read().decode())
print(f"Total perfiles: {len(perfiles)}")
for p in perfiles:
    print(f"  - {p['email']} ({p['nombre']}) | tipo={p['tipo_vendedor']} | activo={p['activo']}")

print()

# 2. Zonas
req = urllib.request.Request(URL + '/rest/v1/zonas?select=id,nombre', headers=H)
resp = urllib.request.urlopen(req)
zonas = json.loads(resp.read().decode())
print(f"Total zonas: {len(zonas)}")
for z in zonas:
    print(f"  - ID {z['id']}: {z['nombre']}")

print()

# 3. Asignaciones por vendedor
for p in perfiles:
    vid = p['id']
    emails = []
    
    # Zonas asignadas
    req2 = urllib.request.Request(URL + f'/rest/v1/vendedor_zonas?select=zona_id&vendedor_id=eq.{vid}', headers=H)
    resp2 = urllib.request.urlopen(req2)
    zonas_asignadas = json.loads(resp2.read().decode())
    
    # Clientes asignados individualmente
    req3 = urllib.request.Request(URL + f'/rest/v1/vendedor_clientes?select=cliente_id&vendedor_id=eq.{vid}', headers=H)
    resp3 = urllib.request.urlopen(req3)
    clientes_asignados = json.loads(resp3.read().decode())
    
    print(f"{p['email']}: {len(zonas_asignadas)} zonas, {len(clientes_asignados)} clientes directos")

print()

# 4. Probar RPC para un vendedor TAT (si existe)
tat_vendors = [p for p in perfiles if p['tipo_vendedor'] == 'TAT']
if tat_vendors:
    v = tat_vendors[0]
    print(f"Probando RPC para {v['email']}...")
    body = json.dumps({'p_vendedor_id': v['id']}).encode()
    req4 = urllib.request.Request(URL + '/rest/v1/rpc/obtener_clientes_vendedor', data=body, headers={**H, 'Content-Type': 'application/json'}, method='POST')
    try:
        resp4 = urllib.request.urlopen(req4)
        clientes = json.loads(resp4.read().decode())
        print(f"  RPC devuelve {len(clientes)} clientes")
        if len(clientes) == 0:
            print(f"  PROBLEMA: El vendedor TAT no tiene clientes asignados!")
    except HTTPError as e:
        print(f"  Error RPC: {e.read().decode()[:200]}")

print()

# 5. Total clientes en BD
req5 = urllib.request.Request(URL + '/rest/v1/clientes?select=id&activo=eq.true', headers=H)
resp5 = urllib.request.urlopen(req5)
total_clientes = json.loads(resp5.read().decode())
print(f"Total clientes activos en BD: {len(total_clientes)}")
