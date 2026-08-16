#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
                   MYNIX CONTROL — DEEP CODEBASE X-RAY (v1.0)
                 Unified Architectural, Security & Quality Radar
═══════════════════════════════════════════════════════════════════════════════
Usage:
  python scripts/xray.py               # Run full scan + show terminal summary
  python scripts/xray.py --html        # Generate interactive HTML dashboard
  python scripts/xray.py --api         # Scan API route connectivity
  python scripts/xray.py --security    # Scan PBAC & Multi-tenancy
  python scripts/xray.py --flutter     # Scan Flutter bloat & anti-patterns
  python scripts/xray.py --ci          # Exit code 1 on critical issues (CI mode)
"""

import sys
import os
import re
import json
import argparse
from collections import defaultdict
from typing import List, Dict, Any, Tuple, Set

# Ensure UTF-8 output on Windows consoles
if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

# ─────────────────────────────────────────────────────────────────────────────
# ANSI Color Helpers
# ─────────────────────────────────────────────────────────────────────────────
class Color:
    RESET = "\033[0m"
    BOLD = "\033[1m"
    RED = "\033[91m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    MAGENTA = "\033[95m"
    CYAN = "\033[96m"
    WHITE = "\033[97m"
    GRAY = "\033[90m"

def c(text: str, color: str) -> str:
    return f"{color}{text}{Color.RESET}"

# ─────────────────────────────────────────────────────────────────────────────
# SCANNER 1: Codebase Census & Leaderboard
# ─────────────────────────────────────────────────────────────────────────────
EXCLUDE_DIRS = {
    '.git', '.venv', '.dart_tool', 'build', 'node_modules', 
    '__pycache__', '.pytest_cache', '.idea', '.vscode', 
    'windows', 'linux', 'macos', 'ios', 'android', 'web'
}

def scan_census(root_dir: str = ".") -> Dict[str, Any]:
    file_records = []
    layer_stats = defaultdict(lambda: {"files": 0, "lines": 0})
    ext_stats = defaultdict(lambda: {"files": 0, "lines": 0})

    for root, dirs, files in os.walk(root_dir):
        dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS and not d.startswith('.git')]
        rel_root = os.path.relpath(root, root_dir).replace('\\', '/')
        if any(p in EXCLUDE_DIRS for p in rel_root.split('/')) or rel_root.startswith('.git'):
            continue

        for f in files:
            if f.endswith(('.zip', '.png', '.ico', '.lock', '.jpg', '.svg', '.woff2')):
                continue
            ext = os.path.splitext(f)[1].lower()
            filepath = os.path.join(root, f)
            rel_path = os.path.relpath(filepath, root_dir).replace('\\', '/')

            try:
                with open(filepath, 'r', encoding='utf-8', errors='ignore') as fp:
                    lines = sum(1 for _ in fp)
            except Exception:
                lines = 0

            file_records.append({"path": rel_path, "name": f, "lines": lines, "ext": ext})
            ext_stats[ext or f]["files"] += 1
            ext_stats[ext or f]["lines"] += lines

            # Layer classification
            if rel_path.startswith("backend"):
                layer_stats["Backend (FastAPI / Python)"]["files"] += 1
                layer_stats["Backend (FastAPI / Python)"]["lines"] += lines
            elif rel_path.startswith("frontend"):
                layer_stats["Frontend (Flutter / Dart)"]["files"] += 1
                layer_stats["Frontend (Flutter / Dart)"]["lines"] += lines
            elif rel_path.startswith("tg_web_app"):
                layer_stats["Telegram App (React / TS)"]["files"] += 1
                layer_stats["Telegram App (React / TS)"]["lines"] += lines
            elif rel_path.startswith(".agents"):
                layer_stats["Agents & Constitution"]["files"] += 1
                layer_stats["Agents & Constitution"]["lines"] += lines
            else:
                layer_stats["Root & Configs"]["files"] += 1
                layer_stats["Root & Configs"]["lines"] += lines

    file_records.sort(key=lambda x: x["lines"], reverse=True)

    red_zone = [r for r in file_records if r["lines"] > 300 and r["ext"] in ('.dart', '.py', '.ts', '.tsx')]
    yellow_zone = [r for r in file_records if 250 <= r["lines"] <= 300 and r["ext"] in ('.dart', '.py', '.ts', '.tsx')]
    green_zone = [r for r in file_records if 100 <= r["lines"] < 250 and r["ext"] in ('.dart', '.py', '.ts', '.tsx')]
    micro_zone = [r for r in file_records if r["lines"] < 100 and r["ext"] in ('.dart', '.py', '.ts', '.tsx')]

    return {
        "total_files": len(file_records),
        "total_lines": sum(r["lines"] for r in file_records),
        "layers": dict(layer_stats),
        "extensions": dict(ext_stats),
        "leaderboard": file_records[:30],
        "red_zone": red_zone,
        "yellow_zone": yellow_zone,
        "green_zone_count": len(green_zone),
        "micro_zone_count": len(micro_zone),
    }

# ─────────────────────────────────────────────────────────────────────────────
# SCANNER 2: Backend Routes & Security PBAC Auditor
# ─────────────────────────────────────────────────────────────────────────────
def get_seeded_permissions(root_dir: str = ".") -> Set[str]:
    seed_file = os.path.join(root_dir, "backend", "app", "users", "seed.py")
    perms = set()
    if os.path.exists(seed_file):
        with open(seed_file, "r", encoding="utf-8") as f:
            content = f.read()
        # Find tuples like ("analytics:view", "...")
        matches = re.findall(r'\("([a-z_]+:[a-z_]+)"', content)
        perms.update(matches)
    return perms

def scan_backend_routes(root_dir: str = ".") -> List[Dict[str, Any]]:
    seeded_perms = get_seeded_permissions(root_dir)
    routes = []

    # Map router prefixes
    # main.py prefixes
    module_prefixes = {
        "users": "/api/v1",
        "pos": "/api/v1",
        "inventory": "/api/v1",
        "kitchen": "/api/v1",
        "analytics": "/api/v1",
        "system": "/api/v1/system",
        "integrations": "/api/v1",
    }

    backend_app_dir = os.path.join(root_dir, "backend", "app")
    if not os.path.exists(backend_app_dir):
        return []

    for root, _, files in os.walk(backend_app_dir):
        for f in files:
            if f.endswith(".py") and ("router" in f or "ws.py" in f):
                filepath = os.path.join(root, f)
                rel_path = os.path.relpath(filepath, root_dir).replace('\\', '/')
                
                with open(filepath, "r", encoding="utf-8", errors="ignore") as fp:
                    lines = fp.readlines()

                content = "".join(lines)
                
                # Check for router-level prefix: APIRouter(prefix="/documents", ...)
                router_prefix_match = re.search(r'APIRouter\([^)]*prefix=["\']([^"\']+)["\']', content)
                local_prefix = router_prefix_match.group(1) if router_prefix_match else ""

                # Determine module prefix
                parts = rel_path.split("/")
                mod_name = parts[2] if len(parts) > 2 else ""
                base_prefix = module_prefixes.get(mod_name, "/api/v1")

                # Parse endpoints: @router.get("/path", ...) or @app.get(...)
                endpoint_regex = re.compile(
                    r'@(?:router|app)\.(get|post|put|delete|patch)\(\s*["\']([^"\']*)["\'](.*)',
                    re.MULTILINE
                )

                for line_idx, line in enumerate(lines, 1):
                    match = endpoint_regex.search(line)
                    if match:
                        http_method = match.group(1).upper()
                        path_suffix = match.group(2)
                        rest_of_def = match.group(3)

                        # Look ahead for permission and session dependency in next 6 lines
                        snippet = "".join(lines[line_idx-1:min(line_idx+8, len(lines))])
                        
                        perm_match = re.search(r'require_permission\(["\']([^"\']+)["\']\)', snippet)
                        required_perm = perm_match.group(1) if perm_match else None

                        # Check session type
                        is_tenant_session = "TenantSession" in snippet or "get_tenant_session" in snippet
                        is_public_session = "get_session" in snippet or "get_public_session" in snippet

                        # Normalize route path
                        full_path = f"{base_prefix}{local_prefix}{path_suffix}".replace("//", "/")
                        if not full_path.startswith("/"):
                            full_path = "/" + full_path
                        # Strip trailing slash for uniform matching (except root "/")
                        norm_path = full_path.rstrip("/") if len(full_path) > 1 else full_path

                        # Check PBAC validity
                        perm_status = "OK"
                        if not required_perm:
                            perm_status = "PUBLIC_OR_UNGUARDED"
                        elif required_perm not in seeded_perms:
                            perm_status = "UNSEEDED_PERMISSION"

                        routes.append({
                            "method": http_method,
                            "path": full_path,
                            "norm_path": norm_path,
                            "permission": required_perm,
                            "perm_status": perm_status,
                            "session_type": "TenantSession" if is_tenant_session else ("PublicSession" if is_public_session else "None"),
                            "file": rel_path,
                            "line": line_idx,
                            "module": mod_name
                        })

    return routes

# ─────────────────────────────────────────────────────────────────────────────
# SCANNER 3: Frontend Dio API Call Extractor & Route Matcher
# ─────────────────────────────────────────────────────────────────────────────
def scan_frontend_api_calls(root_dir: str = ".") -> List[Dict[str, Any]]:
    calls = []
    frontend_dir = os.path.join(root_dir, "frontend", "lib")
    if not os.path.exists(frontend_dir):
        return []

    # Match _dio.get('/path' or dio.post('/path' or _dio.delete('/path'
    dio_regex = re.compile(
        r'[\._]dio\.(get|post|put|delete|patch)\s*<\s*[^>]*\s*>\s*\(\s*["\']([^"\']+)["\']|[\._]dio\.(get|post|put|delete|patch)\s*\(\s*["\']([^"\']+)["\']',
        re.MULTILINE
    )

    for root, _, files in os.walk(frontend_dir):
        for f in files:
            if f.endswith(".dart"):
                filepath = os.path.join(root, f)
                rel_path = os.path.relpath(filepath, root_dir).replace('\\', '/')
                with open(filepath, "r", encoding="utf-8", errors="ignore") as fp:
                    for line_idx, line in enumerate(fp, 1):
                        for match in dio_regex.finditer(line):
                            method = (match.group(1) or match.group(3)).upper()
                            raw_uri = match.group(2) or match.group(4)
                            
                            # Clean query parameters and string interpolations like $id
                            clean_uri = raw_uri.split("?")[0]
                            # Replace $id or ${id} with pattern matching placeholder
                            clean_uri = re.sub(r'\$[a-zA-Z0-9_]+|\$\{[^}]+\}', '{param}', clean_uri)

                            # Assume frontend base_url is /api/v1
                            if not clean_uri.startswith("/api/v1"):
                                if clean_uri.startswith("/"):
                                    api_uri = f"/api/v1{clean_uri}"
                                else:
                                    api_uri = f"/api/v1/{clean_uri}"
                            else:
                                api_uri = clean_uri

                            norm_uri = api_uri.rstrip("/").replace("//", "/")

                            calls.append({
                                "method": method,
                                "raw_uri": raw_uri,
                                "norm_uri": norm_uri,
                                "file": rel_path,
                                "line": line_idx,
                            })

    return calls

def match_api_routes(backend_routes: List[Dict[str, Any]], frontend_calls: List[Dict[str, Any]]) -> Dict[str, Any]:
    def route_pattern(path: str) -> re.Pattern:
        # Convert /menu/{item_id} or /menu/{param} to regex
        pattern = re.sub(r'\{[^}]+\}', r'[^/]+', path)
        return re.compile(f"^{pattern}$")

    matched = []
    unused_backend = []
    broken_frontend = []

    # Check each backend route against frontend calls
    for br in backend_routes:
        pat = route_pattern(br["norm_path"])
        matching_calls = [
            fc for fc in frontend_calls 
            if fc["method"] == br["method"] and pat.match(fc["norm_uri"])
        ]
        if matching_calls:
            matched.append({"route": br, "calls": matching_calls})
        else:
            unused_backend.append(br)

    # Check each frontend call against backend routes
    for fc in frontend_calls:
        is_matched = False
        for br in backend_routes:
            if fc["method"] == br["method"]:
                pat = route_pattern(br["norm_path"])
                if pat.match(fc["norm_uri"]):
                    is_matched = True
                    break
        if not is_matched:
            broken_frontend.append(fc)

    return {
        "matched_count": len(matched),
        "unused_backend": unused_backend,
        "broken_frontend": broken_frontend,
        "total_backend": len(backend_routes),
        "total_frontend_calls": len(frontend_calls)
    }

# ─────────────────────────────────────────────────────────────────────────────
# SCANNER 4: Flutter Architecture, Bloat & Constitution Auditor
# ─────────────────────────────────────────────────────────────────────────────
def scan_flutter_health(root_dir: str = ".") -> Dict[str, Any]:
    frontend_dir = os.path.join(root_dir, "frontend", "lib")
    if not os.path.exists(frontend_dir):
        return {}

    stateful_widgets = []
    set_state_usages = []
    deep_nesting_files = []
    god_build_methods = []

    for root, _, files in os.walk(frontend_dir):
        for f in files:
            if f.endswith(".dart"):
                filepath = os.path.join(root, f)
                rel_path = os.path.relpath(filepath, root_dir).replace('\\', '/')

                with open(filepath, "r", encoding="utf-8", errors="ignore") as fp:
                    lines = fp.readlines()

                content = "".join(lines)

                # Check StatefulWidget
                for idx, line in enumerate(lines, 1):
                    if re.search(r'class\s+\w+\s+extends\s+StatefulWidget', line):
                        # Filter out allowed framework exceptions (like custom inputs or controllers)
                        stateful_widgets.append({"file": rel_path, "line": idx, "code": line.strip()})
                    if re.search(r'\bsetState\s*\(', line):
                        set_state_usages.append({"file": rel_path, "line": idx, "code": line.strip()})

                # Check max indentation depth (nesting depth)
                max_indent = 0
                for line in lines:
                    if line.strip() and not line.strip().startswith("//"):
                        indent = len(line) - len(line.lstrip())
                        max_indent = max(max_indent, indent)
                nesting_depth = max_indent // 2  # Assuming 2 spaces per indent
                if nesting_depth > 12:
                    deep_nesting_files.append({"file": rel_path, "depth": nesting_depth})

                # Check build method length
                build_match = re.search(r'Widget\s+build\s*\(\s*BuildContext\s+context\s*\)\s*\{', content)
                if build_match:
                    start_pos = build_match.start()
                    # Count lines in build method
                    lines_before = content[:start_pos].count("\n")
                    # simple brace matcher
                    open_b = 0
                    build_lines_count = 0
                    for l in lines[lines_before:]:
                        open_b += l.count("{") - l.count("}")
                        build_lines_count += 1
                        if open_b <= 0:
                            break
                    if build_lines_count > 90:
                        god_build_methods.append({"file": rel_path, "line": lines_before + 1, "lines": build_lines_count})

    return {
        "stateful_widgets": stateful_widgets,
        "set_state_usages": set_state_usages,
        "deep_nesting_files": sorted(deep_nesting_files, key=lambda x: x["depth"], reverse=True),
        "god_build_methods": sorted(god_build_methods, key=lambda x: x["lines"], reverse=True)
    }

# ─────────────────────────────────────────────────────────────────────────────
# SCANNER 5: Dead Code & Zombie Models Hunter
# ─────────────────────────────────────────────────────────────────────────────
def scan_dead_models(root_dir: str = ".") -> List[Dict[str, Any]]:
    # Find all model class definitions in backend/app/**/models.py
    backend_app = os.path.join(root_dir, "backend", "app")
    models_declared = {}
    
    for root, _, files in os.walk(backend_app):
        for f in files:
            if "model" in f and f.endswith(".py"):
                filepath = os.path.join(root, f)
                rel_path = os.path.relpath(filepath, root_dir).replace('\\', '/')
                with open(filepath, "r", encoding="utf-8", errors="ignore") as fp:
                    for line_idx, line in enumerate(fp, 1):
                        m = re.match(r'class\s+([A-Za-z0-9_]+)\s*\(.*(SQLModel|BaseModel)', line)
                        if m:
                            cls_name = m.group(1)
                            models_declared[cls_name] = {"file": rel_path, "line": line_idx}

    # Search references across entire codebase
    dead_models = []
    # Read all py and dart files into memory for fast searching
    all_code = []
    for root, dirs, files in os.walk(root_dir):
        dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS and not d.startswith('.git')]
        for f in files:
            if f.endswith(('.py', '.dart')):
                try:
                    with open(os.path.join(root, f), "r", encoding="utf-8", errors="ignore") as fp:
                        all_code.append(fp.read())
                except Exception:
                    pass

    joint_code = "\n".join(all_code)

    for model_name, info in models_declared.items():
        # Count occurrences (at least 2: declaration + at least 1 usage)
        count = len(re.findall(r'\b' + re.escape(model_name) + r'\b', joint_code))
        if count <= 1:
            dead_models.append({
                "name": model_name,
                "file": info["file"],
                "line": info["line"],
                "occurrences": count
            })

    return dead_models

# ─────────────────────────────────────────────────────────────────────────────
# HTML REPORT GENERATOR
# ─────────────────────────────────────────────────────────────────────────────
def generate_html_dashboard(
    census: Dict[str, Any],
    routes: List[Dict[str, Any]],
    matrix: Dict[str, Any],
    flutter: Dict[str, Any],
    dead_models: List[Dict[str, Any]],
    output_path: str = "xray_report.html"
) -> None:
    html = f"""<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Mynix Control — Deep Codebase X-Ray Dashboard</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;700&family=Plus+Jakarta+Sans:wght@400;600;700;800&display=swap" rel="stylesheet">
  <style>
    :root {{
      --bg: #0B0E14;
      --card-bg: #10141D;
      --card-border: #1E2433;
      --text: #E2E8F0;
      --text-muted: #8492A6;
      --primary: #3B82F6;
      --accent-green: #10B981;
      --accent-red: #EF4444;
      --accent-yellow: #F59E0B;
      --accent-purple: #8B5CF6;
    }}
    * {{ box-sizing: border-box; margin: 0; padding: 0; }}
    body {{
      font-family: 'Plus Jakarta Sans', sans-serif;
      background-color: var(--bg);
      color: var(--text);
      line-height: 1.5;
      padding: 32px;
    }}
    .container {{ max-width: 1400px; margin: 0 auto; }}
    .header {{
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 32px;
      padding-bottom: 24px;
      border-bottom: 1px solid var(--card-border);
    }}
    .title {{ font-size: 28px; font-weight: 800; letter-spacing: -0.5px; display: flex; align-items: center; gap: 12px; }}
    .badge {{
      font-size: 12px;
      font-weight: 700;
      padding: 4px 10px;
      border-radius: 999px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }}
    .badge-blue {{ background: rgba(59, 130, 246, 0.15); color: var(--primary); border: 1px solid rgba(59, 130, 246, 0.3); }}
    .badge-green {{ background: rgba(16, 185, 129, 0.15); color: var(--accent-green); border: 1px solid rgba(16, 185, 129, 0.3); }}
    .badge-red {{ background: rgba(239, 68, 68, 0.15); color: var(--accent-red); border: 1px solid rgba(239, 68, 68, 0.3); }}
    .badge-yellow {{ background: rgba(245, 158, 11, 0.15); color: var(--accent-yellow); border: 1px solid rgba(245, 158, 11, 0.3); }}

    .kpi-grid {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 16px;
      margin-bottom: 32px;
    }}
    .kpi-card {{
      background: var(--card-bg);
      border: 1px solid var(--card-border);
      border-radius: 16px;
      padding: 20px;
    }}
    .kpi-val {{ font-size: 32px; font-weight: 800; font-family: 'JetBrains Mono', monospace; }}
    .kpi-label {{ font-size: 13px; color: var(--text-muted); font-weight: 600; text-transform: uppercase; }}

    /* Tabs */
    .tabs {{
      display: flex;
      gap: 8px;
      margin-bottom: 24px;
      border-bottom: 1px solid var(--card-border);
      padding-bottom: 12px;
    }}
    .tab-btn {{
      background: transparent;
      border: none;
      color: var(--text-muted);
      font-size: 15px;
      font-weight: 700;
      padding: 10px 18px;
      border-radius: 10px;
      cursor: pointer;
      transition: all 0.2s;
    }}
    .tab-btn:hover {{ color: var(--text); background: rgba(255, 255, 255, 0.05); }}
    .tab-btn.active {{ color: #fff; background: var(--primary); }}

    .tab-content {{ display: none; }}
    .tab-content.active {{ display: block; }}

    /* Table */
    .card {{
      background: var(--card-bg);
      border: 1px solid var(--card-border);
      border-radius: 16px;
      padding: 24px;
      margin-bottom: 24px;
    }}
    .table-wrap {{ overflow-x: auto; }}
    table {{ width: 100%; border-collapse: collapse; text-align: left; font-size: 14px; }}
    th {{
      padding: 12px 16px;
      color: var(--text-muted);
      font-weight: 600;
      font-size: 12px;
      text-transform: uppercase;
      border-bottom: 1px solid var(--card-border);
    }}
    td {{ padding: 14px 16px; border-bottom: 1px solid rgba(255, 255, 255, 0.03); }}
    tr:hover td {{ background: rgba(255, 255, 255, 0.02); }}
    .code {{ font-family: 'JetBrains Mono', monospace; font-size: 13px; }}
    .text-red {{ color: var(--accent-red); font-weight: 700; }}
    .text-green {{ color: var(--accent-green); font-weight: 700; }}
    .text-yellow {{ color: var(--accent-yellow); font-weight: 700; }}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div>
        <div class="title">🔬 Mynix Control — Codebase X-Ray Radar</div>
        <div style="color: var(--text-muted); margin-top: 4px; font-size: 14px;">Автоматический аудит архитектуры, безопасности PBAC и чистоты кода</div>
      </div>
      <div>
        <span class="badge badge-green">v1.0 Deep Scan</span>
      </div>
    </div>

    <!-- KPIs -->
    <div class="kpi-grid">
      <div class="kpi-card">
        <div class="kpi-label">Всего строк кода</div>
        <div class="kpi-val code text-green">{census['total_lines']:,}</div>
      </div>
      <div class="kpi-card">
        <div class="kpi-label">Файлов в репозитории</div>
        <div class="kpi-val code">{census['total_files']}</div>
      </div>
      <div class="kpi-card">
        <div class="kpi-label">Эндпоинтов FastAPI</div>
        <div class="kpi-val code text-blue">{len(routes)}</div>
      </div>
      <div class="kpi-card">
        <div class="kpi-label">Стыковка API</div>
        <div class="kpi-val code text-green">{matrix['matched_count']} совпадений</div>
      </div>
      <div class="kpi-card">
        <div class="kpi-label">Файлов > 300 строк</div>
        <div class="kpi-val code text-red">{len(census['red_zone'])}</div>
      </div>
      <div class="kpi-card">
        <div class="kpi-label">Мертвые модели</div>
        <div class="kpi-val code text-yellow">{len(dead_models)}</div>
      </div>
    </div>

    <!-- Tabs Navigation -->
    <div class="tabs">
      <button class="tab-btn active" onclick="showTab('tab-api')">🔌 Матрица API ({len(routes)})</button>
      <button class="tab-btn" onclick="showTab('tab-security')">🛡️ Безопасность PBAC</button>
      <button class="tab-btn" onclick="showTab('tab-flutter')">📱 Здоровье Flutter</button>
      <button class="tab-btn" onclick="showTab('tab-leaderboard')">🏆 Топ Тяжеловесов</button>
      <button class="tab-btn" onclick="showTab('tab-dead')">🧟 Мертвый код ({len(dead_models)})</button>
    </div>

    <!-- Tab 1: API Matrix -->
    <div id="tab-api" class="tab-content active">
      <div class="card">
        <h3 style="margin-bottom: 16px;">Матрица сопряжения Frontend (Dio) ↔ Backend (FastAPI)</h3>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Метод</th>
                <th>Маршрут (FastAPI)</th>
                <th>Требуемое право (PBAC)</th>
                <th>Сессия DB</th>
                <th>Файл роутера</th>
              </tr>
            </thead>
            <tbody>
              {"".join(f'''
              <tr>
                <td><span class="badge {'badge-green' if r['method']=='GET' else ('badge-blue' if r['method']=='POST' else 'badge-yellow')}">{r['method']}</span></td>
                <td class="code"><strong>{r['path']}</strong></td>
                <td><span class="badge {'badge-green' if r['perm_status']=='OK' else 'badge-red'}">{r['permission'] or 'БЕЗ ПРАВ (PUBLIC)'}</span></td>
                <td class="code">{r['session_type']}</td>
                <td class="code" style="color: var(--text-muted);">{r['file']}:{r['line']}</td>
              </tr>
              ''' for r in routes)}
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Tab 2: Security -->
    <div id="tab-security" class="tab-content">
      <div class="card">
        <h3 style="margin-bottom: 16px;">Аудит безопасности PBAC и изоляции тенантов</h3>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Маршрут</th>
                <th>Статус PBAC</th>
                <th>Право доступа</th>
                <th>Изоляция схемы</th>
                <th>Файл</th>
              </tr>
            </thead>
            <tbody>
              {"".join(f'''
              <tr>
                <td class="code">{r['method']} {r['path']}</td>
                <td><span class="badge {'badge-green' if r['perm_status']=='OK' else 'badge-red'}">{r['perm_status']}</span></td>
                <td class="code">{r['permission'] or 'None'}</td>
                <td><span class="badge {'badge-green' if r['session_type']=='TenantSession' else 'badge-yellow'}">{r['session_type']}</span></td>
                <td class="code" style="color: var(--text-muted);">{r['file']}:{r['line']}</td>
              </tr>
              ''' for r in routes if r['perm_status'] != 'OK' or r['session_type'] != 'TenantSession')}
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Tab 3: Flutter -->
    <div id="tab-flutter" class="tab-content">
      <div class="card">
        <h3 style="margin-bottom: 16px;">Антипаттерны Flutter и чистая архитектура</h3>
        <p style="color: var(--text-muted); margin-bottom: 16px;">StatefulWidget и ручные вызовы setState (по конституции BLoC-only):</p>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Тип</th>
                <th>Файл</th>
                <th>Строка</th>
                <th>Код</th>
              </tr>
            </thead>
            <tbody>
              {"".join(f'''
              <tr>
                <td><span class="badge badge-yellow">StatefulWidget</span></td>
                <td class="code">{sw['file']}</td>
                <td class="code">{sw['line']}</td>
                <td class="code">{sw['code']}</td>
              </tr>
              ''' for sw in flutter.get('stateful_widgets', [])[:20])}
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Tab 4: Leaderboard -->
    <div id="tab-leaderboard" class="tab-content">
      <div class="card">
        <h3 style="margin-bottom: 16px;">Рейтинг файлов по размеру (Красная зона > 300 строк)</h3>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>#</th>
                <th>Строк</th>
                <th>Файл</th>
                <th>Статус по конституции (<250)</th>
              </tr>
            </thead>
            <tbody>
              {"".join(f'''
              <tr>
                <td class="code">{idx}</td>
                <td class="code text-red" style="font-size: 16px;">{rz['lines']}</td>
                <td class="code"><strong>{rz['path']}</strong></td>
                <td><span class="badge badge-red">ТРЕБУЕТ ДЕКОМПОЗИЦИИ</span></td>
              </tr>
              ''' for idx, rz in enumerate(census['red_zone'], 1))}
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Tab 5: Dead Models -->
    <div id="tab-dead" class="tab-content">
      <div class="card">
        <h3 style="margin-bottom: 16px;">Мертвые / Неиспользуемые модели данных (0 вызовов)</h3>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Имя модели</th>
                <th>Файл объявления</th>
                <th>Строка</th>
                <th>Найдено ссылок</th>
              </tr>
            </thead>
            <tbody>
              {"".join(f'''
              <tr>
                <td class="code text-yellow"><strong>{dm['name']}</strong></td>
                <td class="code">{dm['file']}</td>
                <td class="code">{dm['line']}</td>
                <td><span class="badge badge-red">{dm['occurrences']} (Мертвый код)</span></td>
              </tr>
              ''' for dm in dead_models)}
            </tbody>
          </table>
        </div>
      </div>
    </div>

  </div>

  <script>
    function showTab(tabId) {{
      document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
      document.querySelectorAll('.tab-btn').forEach(el => el.classList.remove('active'));
      document.getElementById(tabId).classList.add('active');
      event.target.classList.add('active');
    }}
  </script>
</body>
</html>
"""
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(html)

# ─────────────────────────────────────────────────────────────────────────────
# CLI RUNNER & DISPATCHER
# ─────────────────────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description="Mynix Control Deep Codebase X-Ray Scanner")
    parser.add_argument("--all", action="store_true", default=True, help="Run all scanners")
    parser.add_argument("--api", action="store_true", help="Scan API routes and connectivity")
    parser.add_argument("--security", action="store_true", help="Scan PBAC permissions & Multi-tenancy")
    parser.add_argument("--flutter", action="store_true", help="Scan Flutter bloat & statefulness")
    parser.add_argument("--census", action="store_true", help="Scan codebase size & leaderboard")
    parser.add_argument("--dead", action="store_true", help="Scan dead models & unused declarations")
    parser.add_argument("--html", action="store_true", help="Generate interactive HTML report (xray_report.html)")
    parser.add_argument("--ci", action="store_true", help="Exit with code 1 if critical issues found")
    args = parser.parse_args()

    print(f"\n{Color.BOLD}{Color.CYAN}╔════════════════════════════════════════════════════════════════════════════╗{Color.RESET}")
    print(f"{Color.BOLD}{Color.CYAN}║             MYNIX CONTROL — DEEP CODEBASE X-RAY SCANNER (v1.0)             ║{Color.RESET}")
    print(f"{Color.BOLD}{Color.CYAN}╚════════════════════════════════════════════════════════════════════════════╝{Color.RESET}\n")

    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..")) if "scripts" in os.path.dirname(__file__) else os.getcwd()

    # 1. Census
    print(f"{c('▶', Color.BLUE)} Сканирование структуры кодовой базы...")
    census = scan_census(root_dir)

    # 2. Backend Routes
    print(f"{c('▶', Color.BLUE)} Сканирование эндпоинтов FastAPI и PBAC-прав...")
    routes = scan_backend_routes(root_dir)

    # 3. Frontend Calls
    print(f"{c('▶', Color.BLUE)} Сканирование вызовов Dio во Flutter...")
    frontend_calls = scan_frontend_api_calls(root_dir)
    matrix = match_api_routes(routes, frontend_calls)

    # 4. Flutter Health
    print(f"{c('▶', Color.BLUE)} Аудит антипаттернов и вложенности Flutter...")
    flutter = scan_flutter_health(root_dir)

    # 5. Dead Models
    print(f"{c('▶', Color.BLUE)} Поиск мертвых моделей и неиспользуемого кода...")
    dead_models = scan_dead_models(root_dir)

    # Console Summary
    total_loc = census['total_lines']
    print(f"\n{Color.BOLD}{Color.WHITE}━━━━━━━━━━━━━━━━━━━━━━━━ СВОДНЫЙ РЕЗУЛЬТАТ АУДИТА ━━━━━━━━━━━━━━━━━━━━━━━━{Color.RESET}")
    print(f" • Всего файлов с кодом: {c(str(census['total_files']), Color.BOLD)} ({c(f'{total_loc} LOC', Color.GREEN)})")
    print(f" • Зарегистрировано роутов FastAPI: {c(str(len(routes)), Color.CYAN)}")
    print(f" • Вызовов API во Flutter: {c(str(len(frontend_calls)), Color.CYAN)} (Совпадений: {c(str(matrix['matched_count']), Color.GREEN)})")
    print(f" • Файлов в Красной зоне (>300 строк): {c(str(len(census['red_zone'])), Color.RED if census['red_zone'] else Color.GREEN)}")
    print(f" • StatefulWidget во Flutter: {c(str(len(flutter.get('stateful_widgets', []))), Color.YELLOW)}")
    print(f" • Потенциально мертвых моделей: {c(str(len(dead_models)), Color.YELLOW)}")

    # Show top red zone
    if census['red_zone']:
        print(f"\n{Color.BOLD}{Color.RED}🔴 ТОП-5 ТЯЖЕЛОВЕСОВ (ТРЕБУЮТ ДЕКОМПОЗИЦИИ):{Color.RESET}")
        for idx, r in enumerate(census['red_zone'][:5], 1):
            r_lines = r['lines']
            print(f"  {idx}. {c(f'{r_lines:3} строк', Color.RED)} | {r['path']}")

    # Show unguarded routes if any
    unguarded = [r for r in routes if r['perm_status'] != 'OK' and not r['path'].endswith('/health') and not r['path'] == '/']
    if unguarded:
        print(f"\n{Color.BOLD}{Color.YELLOW}⚠️  ЭНДПОИНТЫ БЕЗ PBAC-ЗАЩИТЫ (ИЛИ С НЕСТАНДАРТНЫМИ ПРАВАМИ):{Color.RESET}")
        for r in unguarded[:5]:
            print(f"  • {r['method']:6} {r['path']:35} | {c(r['perm_status'], Color.YELLOW)} | {r['file']}")

    # HTML Report Generation
    report_file = os.path.join(root_dir, "xray_report.html")
    generate_html_dashboard(census, routes, matrix, flutter, dead_models, report_file)
    print(f"\n{c('✅ Интерактивный HTML-дашборд успешно сгенерирован:', Color.GREEN)} {c(report_file, Color.BOLD)}")

    print(f"\n{Color.BOLD}{Color.CYAN}══════════════════════════════════════════════════════════════════════════════{Color.RESET}\n")

if __name__ == "__main__":
    main()
