import urllib.request, json
URL = 'https://wsohgkyrtskshbinlfeg.supabase.co'
KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indzb2hna3lydHNrc2hiaW5sZmVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA4NzMzNTgsImV4cCI6MjA5NjQ0OTM1OH0.dI7gPifxB0PCojH-oYUAkPbTsIVrPtV82378mjmN6NE'
H = {'apikey': KEY, 'Authorization': 'Bearer ' + KEY, 'Content-Type': 'application/json'}

# Test RPC function
v_id = 'b5a32aee-0ac3-46bb-b619-2a80d4303628'
body = json.dumps({'p_vendedor_id': v_id}).encode()
req = urllib.request.Request(URL + '/rest/v1/rpc/obtener_clientes_vendedor', data=body, headers=H, method='POST')
try:
    resp = urllib.request.urlopen(req)
    data = json.loads(resp.read().decode())
    print('Clientes del vendedor: ' + str(len(data)))
    for c in data[:5]:
        print('  - ' + c['nombre'] + ' | ' + c.get('ciudad', ''))
except urllib.error.HTTPError as e:
    print('Error: ' + e.read().decode()[:300])
