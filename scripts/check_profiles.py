import urllib.request, json
URL = 'https://wsohgkyrtskshbinlfeg.supabase.co'
KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indzb2hna3lydHNrc2hiaW5sZmVnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MDg3MzM1OCwiZXhwIjoyMDk2NDQ5MzU4fQ.kCpMuu-2VxdNhuZVoxcPKBPX2y74TZH4W5x6eGEYhx4'
H = {'apikey': KEY, 'Authorization': 'Bearer ' + KEY}

req = urllib.request.Request(URL + '/rest/v1/perfiles?select=id,email,nombre,tipo_vendedor,activo&limit=10', headers=H)
resp = urllib.request.urlopen(req)
perfiles = json.loads(resp.read().decode())
print('Perfiles en BD:')
for p in perfiles:
    print('  ' + p['email'] + ' | tipo: ' + p['tipo_vendedor'] + ' | activo: ' + str(p['activo']))
