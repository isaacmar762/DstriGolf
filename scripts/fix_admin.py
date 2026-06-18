import urllib.request, json
URL = 'https://wsohgkyrtskshbinlfeg.supabase.co'
KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indzb2hna3lydHNrc2hiaW5sZmVnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MDg3MzM1OCwiZXhwIjoyMDk2NDQ5MzU4fQ.kCpMuu-2VxdNhuZVoxcPKBPX2y74TZH4W5x6eGEYhx4'
H = {'apikey': KEY, 'Authorization': 'Bearer ' + KEY, 'Content-Type': 'application/json'}

# Reset admin password
admin_id = 'fbcf827d-374b-43c8-b2cf-7a9cf7b00387'
body = json.dumps({'password': 'admin123'}).encode()
req = urllib.request.Request(URL + '/auth/v1/admin/users/' + admin_id, data=body, headers=H, method='PUT')
resp = urllib.request.urlopen(req)
print('Contrasena actualizada a: admin123')

# Test login with new password
body2 = json.dumps({'email': 'admin@distrigolf.com', 'password': 'admin123'}).encode()
req2 = urllib.request.Request(URL + '/auth/v1/token?grant_type=password', data=body2, headers={
    'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indzb2hna3lydHNrc2hiaW5sZmVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA4NzMzNTgsImV4cCI6MjA5NjQ0OTM1OH0.dI7gPifxB0PCojH-oYUAkPbTsIVrPtV82378mjmN6NE',
    'Content-Type': 'application/json'
}, method='POST')
resp2 = urllib.request.urlopen(req2)
data = json.loads(resp2.read().decode())
print('Login OK:', data['user']['email'])
