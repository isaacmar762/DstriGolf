import urllib.request, json
URL = 'https://wsohgkyrtskshbinlfeg.supabase.co'
KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indzb2hna3lydHNrc2hiaW5sZmVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA4NzMzNTgsImV4cCI6MjA5NjQ0OTM1OH0.dI7gPifxB0PCojH-oYUAkPbTsIVrPtV82378mjmN6NE'
H = {'apikey': KEY, 'Authorization': 'Bearer ' + KEY}

print('=== TEST API ===')
# Test 1: Obtener clientes via RPC
body = json.dumps({'p_vendedor_id': 'b5a32aee-0ac3-46bb-b619-2a80d4303628'}).encode()
req = urllib.request.Request(URL + '/rest/v1/rpc/obtener_clientes_vendedor', data=body, headers={**H, 'Content-Type': 'application/json'}, method='POST')
try:
    resp = urllib.request.urlopen(req)
    data = json.loads(resp.read().decode())
    print('Clientes por RPC: ' + str(len(data)) + ' registros')
except Exception as e:
    print('Error RPC clientes: ' + str(e))

# Test 2: Obtener productos
req2 = urllib.request.Request(URL + '/rest/v1/productos?select=id,referencia,nombre&limit=5', headers=H)
resp2 = urllib.request.urlopen(req2)
data2 = json.loads(resp2.read().decode())
print('Productos (directo): ' + str(len(data2)) + ' registros')
for p in data2[:3]:
    print('  - ' + p['referencia'] + ': ' + p['nombre'][:50])

# Test 3: Obtener precios mayorista
req3 = urllib.request.Request(URL + '/rest/v1/precios_mayorista?select=id,producto_id,unitario&limit=3', headers=H)
resp3 = urllib.request.urlopen(req3)
data3 = json.loads(resp3.read().decode())
print('Precios Mayorista: ' + str(len(data3)) + ' registros (primeros 3)')
