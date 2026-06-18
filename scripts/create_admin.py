import urllib.request, json

URL = 'https://wsohgkyrtskshbinlfeg.supabase.co'
KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indzb2hna3lydHNrc2hiaW5sZmVnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MDg3MzM1OCwiZXhwIjoyMDk2NDQ5MzU4fQ.kCpMuu-2VxdNhuZVoxcPKBPX2y74TZH4W5x6eGEYhx4'
H = {'apikey': KEY, 'Authorization': 'Bearer ' + KEY, 'Content-Type': 'application/json'}

# Crear usuario admin en Auth
body = json.dumps({'email': 'admin@distrigolf.com', 'password': 'admin1', 'email_confirm': True}).encode()
req = urllib.request.Request(URL + '/auth/v1/admin/users', data=body, headers=H, method='POST')
resp = urllib.request.urlopen(req)
user = json.loads(resp.read().decode())
admin_id = user['id']
print('Admin creado: ' + admin_id)

# Crear perfil admin
body2 = json.dumps({
    'id': admin_id,
    'email': 'admin@distrigolf.com',
    'nombre': 'Administrador',
    'tipo_vendedor': 'ADMIN',
    'activo': True
}).encode()
req2 = urllib.request.Request(URL + '/rest/v1/perfiles', data=body2, headers=H, method='POST')
urllib.request.urlopen(req2)
print('Perfil admin creado')

# Activar vendedores pendientes
req3 = urllib.request.Request(URL + '/rest/v1/perfiles?select=id,email,nombre&activo=eq.false', headers=H)
resp3 = urllib.request.urlopen(req3)
inactivos = json.loads(resp3.read().decode())
print('Vendedores pendientes: ' + str(len(inactivos)))

for v in inactivos:
    body3 = json.dumps({'activo': True}).encode()
    req4 = urllib.request.Request(URL + '/rest/v1/perfiles?id=eq.' + v['id'], data=body3, headers=H, method='PATCH')
    urllib.request.urlopen(req4)
    print('  Activado: ' + v['nombre'] + ' (' + v['email'] + ')')

print('---')
print('Admin: admin@distrigolf.com / admin1')
print('Tu vendedor ya fue activado.')
