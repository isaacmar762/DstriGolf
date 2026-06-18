"""
Script optimizado para importar datos desde Excel a Supabase.
Usa inserción por lotes (batch) para ser más rápido.
"""

import os
import json
import urllib.request
import pandas as pd

SUPABASE_URL = "https://wsohgkyrtskshbinlfeg.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indzb2hna3lydHNrc2hiaW5sZmVnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MDg3MzM1OCwiZXhwIjoyMDk2NDQ5MzU4fQ.kCpMuu-2VxdNhuZVoxcPKBPX2y74TZH4W5x6eGEYhx4"

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLIENTES_PATH = os.path.join(BASE_DIR, "BASE DE DATOS CLIENTES.xlsx")
MAYORISTAS_PATH = os.path.join(BASE_DIR, "LISTA DE PRECIOS MAYORISTAS.xls")
TAT_PATH = os.path.join(BASE_DIR, "LISTA DE PRECIOS TAT.xls")

HEADERS = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=minimal",
}


def rest_post(path, data):
    url = f"{SUPABASE_URL}/rest/v1/{path}"
    body = json.dumps(data).encode("utf-8")
    req = urllib.request.Request(url, data=body, headers=HEADERS, method="POST")
    try:
        urllib.request.urlopen(req)
    except urllib.error.HTTPError as e:
        print(f"  Error HTTP {e.code}: {e.read().decode()[:200]}")
        raise


def rest_delete(path):
    url = f"{SUPABASE_URL}/rest/v1/{path}"
    req = urllib.request.Request(url, headers=HEADERS, method="DELETE")
    try:
        urllib.request.urlopen(req)
    except urllib.error.HTTPError as e:
        if e.code != 404:
            print(f"  Error HTTP {e.code}: {e.read().decode()[:200]}")


def rest_get(path):
    url = f"{SUPABASE_URL}/rest/v1/{path}"
    req = urllib.request.Request(url, headers=HEADERS, method="GET")
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError:
        return []


def importar_clientes():
    print("Importando clientes...")

    # Leer Excel
    df = pd.read_excel(CLIENTES_PATH, header=None, dtype=str)

    # Obtener zonas existentes
    existing = rest_get("zonas?select=id,nombre")
    zona_map = {z["nombre"]: z["id"] for z in existing}

    clientes = []
    current_zona = None

    for _, row in df.iterrows():
        col0 = str(row.iloc[0]).strip() if pd.notna(row.iloc[0]) else ""

        if col0 == "-":
            zona_nombre = str(row.iloc[1]).strip() if pd.notna(row.iloc[1]) else ""
            if zona_nombre and "NOMBRE ZONA :" in zona_nombre:
                current_zona = zona_nombre.replace("NOMBRE ZONA :", "").strip()
            continue

        cliente_id = str(row.iloc[1]).strip() if pd.notna(row.iloc[1]) else ""
        if not cliente_id or not cliente_id.isdigit():
            continue

        nombre = str(row.iloc[3]).strip() if pd.notna(row.iloc[3]) else ""
        if not nombre:
            continue

        clientes.append({
            "codigo": str(row.iloc[0]).strip() if pd.notna(row.iloc[0]) else None,
            "dv": str(row.iloc[2]).strip() if pd.notna(row.iloc[2]) else None,
            "nombre": nombre,
            "direccion": str(row.iloc[4]).strip() if pd.notna(row.iloc[4]) else None,
            "email": str(row.iloc[5]).strip() if pd.notna(row.iloc[5]) else None,
            "ciudad": str(row.iloc[6]).strip() if pd.notna(row.iloc[6]) else None,
            "zona_id": zona_map.get(current_zona) if current_zona else None,
        })

    print(f"  Leyendo {len(clientes)} clientes...")

    # Insertar en lotes de 500
    BATCH = 500
    for i in range(0, len(clientes), BATCH):
        batch = clientes[i:i + BATCH]
        rest_post("clientes", batch)
        print(f"  Insertados {min(i+BATCH, len(clientes))}/{len(clientes)}")

    print(f"  {len(clientes)} clientes importados correctamente")


def importar_precios(filepath: str, tipo: str):
    tabla = "precios_mayorista" if tipo == "MAYORISTA" else "precios_tat"
    print(f"Importando precios {tipo}...")

    df = pd.read_excel(filepath, dtype=str)
    total = len(df)
    print(f"  Leyendo {total} registros...")

    # Primero creamos todos los productos únicos
    productos_dict = {}
    for _, row in df.iterrows():
        ref = str(row["REFERENCIA"]).strip() if pd.notna(row.get("REFERENCIA")) else ""
        if not ref:
            continue
        if ref not in productos_dict:
            productos_dict[ref] = {
                "referencia": ref,
                "nombre": str(row.get("NOMBRE_REFERENCIA", "")).strip() if pd.notna(row.get("NOMBRE_REFERENCIA")) else "",
                "cod_linea": str(row.get("CODLINEA", "")).strip() if pd.notna(row.get("CODLINEA")) else None,
                "nombre_linea": str(row.get("NOMBRE_LINEA", "")).strip() if pd.notna(row.get("NOMBRE_LINEA")) else None,
                "cod_medida": str(row.get("CODMEDIDA", "")).strip() if pd.notna(row.get("CODMEDIDA")) else None,
            }

    print(f"  Importando {len(productos_dict)} productos únicos...")

    # Verificar productos existentes
    existing_products = {}
    offset = 0
    limit = 1000
    while True:
        batch = rest_get(f"productos?select=id,referencia&limit={limit}&offset={offset}")
        if not batch:
            break
        for p in batch:
            existing_products[p["referencia"]] = p["id"]
        offset += limit
    print(f"  {len(existing_products)} productos existentes en BD")

    # Insertar solo productos nuevos
    productos_list = [p for p in productos_dict.values() if p["referencia"] not in existing_products]
    print(f"  Insertando {len(productos_list)} productos nuevos...")

    BATCH = 200
    for i in range(0, len(productos_list), BATCH):
        batch = productos_list[i:i + BATCH]
        rest_post("productos", batch)

    # Obtener todos los productos con sus IDs
    product_id_map = dict(existing_products)
    offset = 0
    while True:
        batch = rest_get(f"productos?select=id,referencia&limit={limit}&offset={offset}")
        if not batch:
            break
        for p in batch:
            product_id_map[p["referencia"]] = p["id"]
        offset += limit
    print(f"  {len(product_id_map)} productos totales en BD")

    print(f"  {len(product_id_map)} productos sincronizados")

    # Insertar precios
    precios = []
    for _, row in df.iterrows():
        ref = str(row["REFERENCIA"]).strip() if pd.notna(row.get("REFERENCIA")) else ""
        if not ref or ref not in product_id_map:
            continue

        precios.append({
            "producto_id": product_id_map[ref],
            "esquema": str(row.get("ESQUEMA", "")).strip() if pd.notna(row.get("ESQUEMA")) else None,
            "bruto": _parse_precio(row.get("BRUTO")),
            "unitario": _parse_precio(row.get("UNITARIO")),
            "max_descuento": _parse_precio(row.get("MAXDESCUENTO")),
            "minimo": _parse_precio(row.get("MINIMO")),
            "impuestos": _parse_precio(row.get("IMPTOS")),
        })

    # Verificar precios existentes
    existing_prices = 0
    offset = 0
    while True:
        batch = rest_get(f"{tabla}?select=producto_id&limit={limit}&offset={offset}")
        if not batch:
            break
        existing_prices += len(batch)
        offset += limit
    print(f"  {existing_prices} precios existentes en BD")

    if existing_prices > 0:
        print(f"  Eliminando {existing_prices} precios existentes...")
        rest_delete(f"{tabla}?producto_id=neq.0")

    print(f"  Insertando {len(precios)} precios en lotes...")
    BATCH2 = 500
    for i in range(0, len(precios), BATCH2):
        batch = precios[i:i + BATCH2]
        rest_post(tabla, batch)
        print(f"  Precios: {min(i+BATCH2, len(precios))}/{len(precios)}")

    print(f"  Total {tipo}: {len(precios)} precios importados")


def _parse_precio(valor) -> float:
    if pd.isna(valor):
        return 0.0
    if isinstance(valor, (int, float)):
        return float(valor)
    valor_str = str(valor).replace("$", "").replace(",", "").strip()
    try:
        return float(valor_str)
    except ValueError:
        return 0.0


def main():
    print("=== IMPORTADOR EXCEL -> SUPABASE ===")
    print()

    importar_clientes()
    importar_precios(MAYORISTAS_PATH, "MAYORISTA")
    importar_precios(TAT_PATH, "TAT")

    print()
    print("=== IMPORTACIÓN COMPLETADA ===")


if __name__ == "__main__":
    main()
