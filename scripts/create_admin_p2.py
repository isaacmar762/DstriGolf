import urllib.request, json

URL = 'https://wsohgkyrtskshbinlfeg.supabase.co'
KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indzb2hna3lydHNrc2hiaW5sZmVnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MDg3MzM1OCwiZXhwIjoyMDk2NDQ5MzU4fQ.kCpMuu-2VxdNhuZVoxcPKBPX2y74TZH4W5x6eGEYhx4'
H = {'apikey': KEY, 'Authorization': 'Bearer ' + KEY, 'Content-Type': 'application/json'}

# Try using the SQL query via the auth endpoint
# Actually, just use the PG REST endpoint to execute
# We'll update the constraint using the management API

# First, let's try using the pg database for direct execution
# The only way is to use the SQL Editor in the dashboard.
# Let me instead do a PATCH to insert the admin profile,
# first dropping the constraint

# Actually we can't drop constraints via REST API easily.
# Let me try a different approach - send raw SQL

print('Ve al SQL Editor de Supabase y ejecuta:')
print()
print('ALTER TABLE perfiles DROP CONSTRAINT perfiles_tipo_vendedor_check;')
print()
print("ALTER TABLE perfiles ADD CONSTRAINT perfiles_tipo_vendedor_check CHECK (tipo_vendedor IN ('MAYORISTA', 'TAT', 'ADMIN'));")
print()
print('INSERT INTO perfiles (id, email, nombre, tipo_vendedor, activo)')
print("VALUES ('fbcf827d-374b-43c8-b2cf-7a9cf7b00387', 'admin@distrigolf.com', 'Administrador', 'ADMIN', true);")
print()
print('---')
print('Despues, activa los vendedores pendientes:')
print("UPDATE perfiles SET activo = true WHERE activo = false;")
