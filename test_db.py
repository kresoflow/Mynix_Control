import psycopg2
import sys

sys.stdout.reconfigure(encoding='utf-8')

try:
    conn = psycopg2.connect('postgresql://mynix:mynix_secret@127.0.0.1:5444/mynix_control')
    cur = conn.cursor()
    cur.execute("SELECT schema_name FROM information_schema.schemata WHERE schema_name LIKE 'tenant_%'")
    schemas = cur.fetchall()
    for s in schemas:
        schema = s[0]
        cur.execute(f"SELECT id, name, type, attributes FROM {schema}.menu_items ORDER BY id DESC LIMIT 5")
        rows = cur.fetchall()
        print(f'SCHEMA {schema}:')
        for r in rows:
            print(f'  ID: {r[0]}, Name: {r[1]}, Type: {r[2]}, Attr: {r[3]}')
except Exception as e:
    print('DB Error:', e)
