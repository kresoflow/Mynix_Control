from app.main import app
for r in app.routes:
    if 'tenant' in r.path:
        methods = getattr(r, 'methods', 'WS')
        print(f"{methods} {r.path}")
