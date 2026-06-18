import urllib.request, json
URL = 'https://wsohgkyrtskshbinlfeg.supabase.co'

# Test admin login via Supabase Auth
body = json.dumps({'email': 'admin@distrigolf.com', 'password': 'admin1', 'gotrue_meta_security': {}}).encode()
req = urllib.request.Request(URL + '/auth/v1/token?grant_type=password', data=body, headers={
    'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indzb2hna3lydHNrc2hiaW5sZmVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA4NzMzNTgsImV4cCI6MjA5NjQ0OTM1OH0.dI7gPifxB0PCojH-oYUAkPbTsIVrPtV82378mjmN6NE',
    'Content-Type': 'application/json'
}, method='POST')
try:
    resp = urllib.request.urlopen(req)
    data = json.loads(resp.read().decode())
    print('Login exitoso!')
    print('Usuario:', data['user']['email'])
    print('Token:', data['access_token'][:20] + '...')
except urllib.error.HTTPError as e:
    error = json.loads(e.read().decode())
    print('Error de login:', error.get('error_description', error.get('msg', 'desconocido')))
