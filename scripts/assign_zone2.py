import urllib.request, json
URL = 'https://wsohgkyrtskshbinlfeg.supabase.co'
KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indzb2hna3lydHNrc2hiaW5sZmVnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MDg3MzM1OCwiZXhwIjoyMDk2NDQ5MzU4fQ.kCpMuu-2VxdNhuZVoxcPKBPX2y74TZH4W5x6eGEYhx4'
H = {'apikey': KEY, 'Authorization': 'Bearer ' + KEY, 'Content-Type': 'application/json'}

# Asignar vendedor a zona
v_id = 'b5a32aee-0ac3-46bb-b619-2a80d4303628'
body = json.dumps({'vendedor_id': v_id, 'zona_id': 1}).encode()
req = urllib.request.Request(URL + '/rest/v1/vendedor_zonas', data=body, headers=H, method='POST')
try:
    urllib.request.urlopen(req)
    print('Vendedor asignado a zona MAICAO CENTRO Y MERCADO')
except urllib.error.HTTPError as e:
    print('Error: ' + e.read().decode()[:200])

# Verificar
req2 = urllib.request.Request(URL + '/rest/v1/vendedor_zonas?select=*,zonas(nombre)&vendedor_id=eq.' + v_id, headers=H)
resp2 = urllib.request.urlopen(req2)
data = json.loads(resp2.read().decode())
print('Asignaciones del vendedor:')
for d in data:
    print('  Zona ID:', d['zona_id'], '-', d.get('zonas', {}).get('nombre', ''))
