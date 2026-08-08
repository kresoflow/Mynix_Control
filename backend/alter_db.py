import sqlite3

conn = sqlite3.connect('app.db')
cursor = conn.cursor()
try:
    cursor.execute("ALTER TABLE menu_items ADD COLUMN type VARCHAR DEFAULT 'dish'")
    conn.commit()
    print("Column added successfully")
except sqlite3.OperationalError as e:
    print("Error:", e)
finally:
    conn.close()
