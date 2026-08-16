#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
                   MYNIX CONTROL — INTERACTIVE CODEBASE X-RAY (v2.0)
                     Unified Architectural & Security Console
═══════════════════════════════════════════════════════════════════════════════
"""

import sys
import os
import re
import json
import argparse
import webbrowser
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

EXCLUDE_DIRS = {
    '.git', '.venv', '.dart_tool', 'build', 'node_modules', 
    '__pycache__', '.pytest_cache', '.idea', '.vscode', 
    'windows', 'linux', 'macos', 'ios', 'android', 'web'
}

# ─────────────────────────────────────────────────────────────────────────────
# SCANNER ENGINE
# ─────────────────────────────────────────────────────────────────────────────
class XRayEngine:
    def __init__(self, root_dir: str):
        self.root_dir = root_dir
        self.census = {}
        self.routes = []
        self.frontend_calls = []
        self.matrix = {}
        self.flutter = {}
        self.dead_models = []
        self.backend_modules = defaultdict(lambda: {"files": [], "lines": 0})
        self.frontend_features = defaultdict(lambda: {"files": [], "lines": 0})
        self.rescan()

    def rescan(self):
        self.census = self._scan_census()
        self.routes = self._scan_backend_routes()
        self.frontend_calls = self._scan_frontend_api_calls()
        self.matrix = self._match_api_routes()
        self.flutter = self._scan_flutter_health()
        self.dead_models = self._scan_dead_models()

    def _scan_census(self) -> Dict[str, Any]:
        file_records = []
        layer_stats = defaultdict(lambda: {"files": 0, "lines": 0})
        ext_stats = defaultdict(lambda: {"files": 0, "lines": 0})
        self.backend_modules.clear()
        self.frontend_features.clear()

        for root, dirs, files in os.walk(self.root_dir):
            dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS and not d.startswith('.git')]
            rel_root = os.path.relpath(root, self.root_dir).replace('\\', '/')
            if any(p in EXCLUDE_DIRS for p in rel_root.split('/')) or rel_root.startswith('.git'):
                continue

            for f in files:
                if f.endswith(('.zip', '.png', '.ico', '.lock', '.jpg', '.svg', '.woff2')):
                    continue
                ext = os.path.splitext(f)[1].lower()
                filepath = os.path.join(root, f)
                rel_path = os.path.relpath(filepath, self.root_dir).replace('\\', '/')

                try:
                    with open(filepath, 'r', encoding='utf-8', errors='ignore') as fp:
                        lines = sum(1 for _ in fp)
                except Exception:
                    lines = 0

                record = {"path": rel_path, "name": f, "lines": lines, "ext": ext}
                file_records.append(record)
                ext_stats[ext or f]["files"] += 1
                ext_stats[ext or f]["lines"] += lines

                # Layer and Module classification
                if rel_path.startswith("backend/app/"):
                    parts = rel_path.split("/")
                    mod_name = parts[2] if len(parts) > 2 else "core"
                    self.backend_modules[mod_name]["files"].append(record)
                    self.backend_modules[mod_name]["lines"] += lines
                    layer_stats["Backend (FastAPI / Python)"]["files"] += 1
                    layer_stats["Backend (FastAPI / Python)"]["lines"] += lines
                elif rel_path.startswith("backend"):
                    layer_stats["Backend (FastAPI / Python)"]["files"] += 1
                    layer_stats["Backend (FastAPI / Python)"]["lines"] += lines
                elif rel_path.startswith("frontend/lib/features/"):
                    parts = rel_path.split("/")
                    feat_name = parts[3] if len(parts) > 3 else "other"
                    self.frontend_features[feat_name]["files"].append(record)
                    self.frontend_features[feat_name]["lines"] += lines
                    layer_stats["Frontend (Flutter / Dart)"]["files"] += 1
                    layer_stats["Frontend (Flutter / Dart)"]["lines"] += lines
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
            "leaderboard": file_records,
            "red_zone": red_zone,
            "yellow_zone": yellow_zone,
            "green_zone_count": len(green_zone),
            "micro_zone_count": len(micro_zone),
        }

    def _get_seeded_permissions(self) -> Set[str]:
        seed_file = os.path.join(self.root_dir, "backend", "app", "users", "seed.py")
        perms = set()
        if os.path.exists(seed_file):
            import ast
            try:
                with open(seed_file, "r", encoding="utf-8") as f:
                    tree = ast.parse(f.read(), filename=seed_file)
                for node in ast.walk(tree):
                    if isinstance(node, ast.Constant) and isinstance(node.value, str):
                        if ":" in node.value and not node.value.startswith("http"):
                            perms.add(node.value)
            except Exception:
                pass
        return perms

    def _scan_backend_routes(self) -> List[Dict[str, Any]]:
        import ast
        seeded_perms = self._get_seeded_permissions()
        routes = []
        module_prefixes = {
            "users": "/api/v1",
            "pos": "/api/v1",
            "inventory": "/api/v1",
            "kitchen": "/api/v1",
            "analytics": "/api/v1",
            "system": "/api/v1/system",
            "integrations": "/api/v1",
        }
        backend_app_dir = os.path.join(self.root_dir, "backend", "app")
        if not os.path.exists(backend_app_dir):
            return []

        http_methods = {"get", "post", "put", "delete", "patch"}

        for root, _, files in os.walk(backend_app_dir):
            for f in files:
                if f.endswith(".py") and ("router" in f or "ws.py" in f):
                    filepath = os.path.join(root, f)
                    rel_path = os.path.relpath(filepath, self.root_dir).replace('\\', '/')
                    try:
                        with open(filepath, "r", encoding="utf-8", errors="ignore") as fp:
                            source = fp.read()
                        tree = ast.parse(source, filename=filepath)
                    except Exception:
                        continue

                    # 1. Collect APIRouter prefixes from AST assignment nodes
                    router_prefixes = {"router": "", "app": ""}
                    for node in ast.walk(tree):
                        if isinstance(node, ast.Assign) and isinstance(node.value, ast.Call):
                            func_name = ""
                            if isinstance(node.value.func, ast.Name):
                                func_name = node.value.func.id
                            elif isinstance(node.value.func, ast.Attribute):
                                func_name = node.value.func.attr
                            if func_name == "APIRouter":
                                for kw in node.value.keywords:
                                    if kw.arg == "prefix" and isinstance(kw.value, ast.Constant):
                                        for target in node.targets:
                                            if isinstance(target, ast.Name):
                                                router_prefixes[target.id] = str(kw.value.value)

                    parts = rel_path.split("/")
                    mod_name = parts[2] if len(parts) > 2 else ""
                    base_prefix = module_prefixes.get(mod_name, "/api/v1")
                    if mod_name == "analytics" and "analytics_router" in f:
                        base_prefix = "/api/v1/analytics"

                    # 2. Inspect all functions with decorators via AST
                    for node in ast.walk(tree):
                        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                            for dec in node.decorator_list:
                                if isinstance(dec, ast.Call) and isinstance(dec.func, ast.Attribute):
                                    method_name = dec.func.attr.lower()
                                    if method_name in http_methods:
                                        router_var = dec.func.value.id if isinstance(dec.func.value, ast.Name) else "router"
                                        local_prefix = router_prefixes.get(router_var, "")

                                        path_suffix = ""
                                        if dec.args and isinstance(dec.args[0], ast.Constant):
                                            path_suffix = str(dec.args[0].value)
                                        else:
                                            for kw in dec.keywords:
                                                if kw.arg == "path" and isinstance(kw.value, ast.Constant):
                                                    path_suffix = str(kw.value.value)

                                        # Extract require_permission AST call
                                        required_perm = None
                                        for subnode in ast.walk(dec):
                                            if isinstance(subnode, ast.Call):
                                                fname = subnode.func.id if isinstance(subnode.func, ast.Name) else ""
                                                if fname == "require_permission" and subnode.args and isinstance(subnode.args[0], ast.Constant):
                                                    required_perm = str(subnode.args[0].value)

                                        is_tenant_session = False
                                        is_public_session = False

                                        # Inspect function args
                                        for arg in node.args.args:
                                            ann_name = ""
                                            if isinstance(arg.annotation, ast.Name):
                                                ann_name = arg.annotation.id
                                            if "TenantSession" in ann_name or "get_tenant_session" in ann_name:
                                                is_tenant_session = True
                                            if "get_session" in ann_name or "get_public_session" in ann_name:
                                                is_public_session = True

                                        for default_val in node.args.defaults:
                                            for subnode in ast.walk(default_val):
                                                if isinstance(subnode, ast.Name):
                                                    if "get_tenant_session" in subnode.id or "TenantSession" in subnode.id:
                                                        is_tenant_session = True
                                                    if "get_session" in subnode.id:
                                                        is_public_session = True
                                                elif isinstance(subnode, ast.Call):
                                                    fname = subnode.func.id if isinstance(subnode.func, ast.Name) else ""
                                                    if fname == "require_permission" and subnode.args and isinstance(subnode.args[0], ast.Constant) and not required_perm:
                                                        required_perm = str(subnode.args[0].value)

                                        full_path = f"{base_prefix}{local_prefix}{path_suffix}".replace("//", "/")
                                        if not full_path.startswith("/"):
                                            full_path = "/" + full_path
                                        norm_path = full_path.rstrip("/") if len(full_path) > 1 else full_path

                                        perm_status = "OK"
                                        if not required_perm:
                                            perm_status = "PUBLIC_OR_UNGUARDED"
                                        elif required_perm not in seeded_perms:
                                            perm_status = "UNSEEDED_PERMISSION"

                                        routes.append({
                                            "method": method_name.upper(),
                                            "path": full_path,
                                            "norm_path": norm_path,
                                            "permission": required_perm,
                                            "perm_status": perm_status,
                                            "session_type": "TenantSession" if is_tenant_session else ("PublicSession" if is_public_session else "None"),
                                            "file": rel_path,
                                            "line": node.lineno,
                                            "module": mod_name
                                        })
        return routes

    def _scan_frontend_api_calls(self) -> List[Dict[str, Any]]:
        calls = []
        frontend_dir = os.path.join(self.root_dir, "frontend", "lib")
        if not os.path.exists(frontend_dir):
            return []

        dio_regex = re.compile(
            r'[\._]dio\.(get|post|put|delete|patch)\s*<\s*[^>]*\s*>\s*\(\s*["\']([^"\']+)["\']|[\._]dio\.(get|post|put|delete|patch)\s*\(\s*["\']([^"\']+)["\']',
            re.MULTILINE
        )

        for root, _, files in os.walk(frontend_dir):
            for f in files:
                if f.endswith(".dart"):
                    filepath = os.path.join(root, f)
                    rel_path = os.path.relpath(filepath, self.root_dir).replace('\\', '/')
                    with open(filepath, "r", encoding="utf-8", errors="ignore") as fp:
                        for line_idx, line in enumerate(fp, 1):
                            for match in dio_regex.finditer(line):
                                method = (match.group(1) or match.group(3)).upper()
                                raw_uri = match.group(2) or match.group(4)
                                clean_uri = raw_uri.split("?")[0]
                                clean_uri = re.sub(r'\$[a-zA-Z0-9_]+|\$\{[^}]+\}', '{param}', clean_uri)
                                if not clean_uri.startswith("/api/v1"):
                                    api_uri = f"/api/v1{clean_uri}" if clean_uri.startswith("/") else f"/api/v1/{clean_uri}"
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

    def _match_api_routes(self) -> Dict[str, Any]:
        def route_pattern(path: str) -> re.Pattern:
            pattern = re.sub(r'\{[^}]+\}', r'[^/]+', path)
            return re.compile(f"^{pattern}$")

        matched = []
        unused_backend = []
        broken_frontend = []

        for br in self.routes:
            pat = route_pattern(br["norm_path"])
            matching_calls = [
                fc for fc in self.frontend_calls 
                if fc["method"] == br["method"] and pat.match(fc["norm_uri"])
            ]
            if matching_calls:
                matched.append({"route": br, "calls": matching_calls})
            else:
                unused_backend.append(br)

        for fc in self.frontend_calls:
            is_matched = False
            for br in self.routes:
                if fc["method"] == br["method"]:
                    pat = route_pattern(br["norm_path"])
                    if pat.match(fc["norm_uri"]):
                        is_matched = True
                        break
            if not is_matched:
                broken_frontend.append(fc)

        return {
            "matched_count": len(matched),
            "matched": matched,
            "unused_backend": unused_backend,
            "broken_frontend": broken_frontend,
            "total_backend": len(self.routes),
            "total_frontend_calls": len(self.frontend_calls)
        }

    def _scan_flutter_health(self) -> Dict[str, Any]:
        frontend_dir = os.path.join(self.root_dir, "frontend", "lib")
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
                    rel_path = os.path.relpath(filepath, self.root_dir).replace('\\', '/')
                    with open(filepath, "r", encoding="utf-8", errors="ignore") as fp:
                        lines = fp.readlines()
                    content = "".join(lines)

                    for idx, line in enumerate(lines, 1):
                        if re.search(r'class\s+\w+\s+extends\s+StatefulWidget', line):
                            stateful_widgets.append({"file": rel_path, "line": idx, "code": line.strip()})
                        if re.search(r'\bsetState\s*\(', line):
                            set_state_usages.append({"file": rel_path, "line": idx, "code": line.strip()})

                    max_indent = 0
                    for line in lines:
                        if line.strip() and not line.strip().startswith("//"):
                            indent = len(line) - len(line.lstrip())
                            max_indent = max(max_indent, indent)
                    nesting_depth = max_indent // 2
                    if nesting_depth > 12:
                        deep_nesting_files.append({"file": rel_path, "depth": nesting_depth})

                    build_match = re.search(r'Widget\s+build\s*\(\s*BuildContext\s+context\s*\)\s*\{', content)
                    if build_match:
                        start_pos = build_match.start()
                        lines_before = content[:start_pos].count("\n")
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

    def _scan_dead_models(self) -> List[Dict[str, Any]]:
        backend_app = os.path.join(self.root_dir, "backend", "app")
        if not os.path.exists(backend_app):
            return []

        models_declared = {}
        for root, _, files in os.walk(backend_app):
            for f in files:
                if "model" in f and f.endswith(".py"):
                    filepath = os.path.join(root, f)
                    rel_path = os.path.relpath(filepath, self.root_dir).replace('\\', '/')
                    with open(filepath, "r", encoding="utf-8", errors="ignore") as fp:
                        for line_idx, line in enumerate(fp, 1):
                            m = re.match(r'class\s+([A-Za-z0-9_]+)\s*\(.*(SQLModel|BaseModel)', line)
                            if m:
                                cls_name = m.group(1)
                                models_declared[cls_name] = {"file": rel_path, "line": line_idx}

        # Single-pass fast token counter across active code only (backend/app + frontend/lib)
        from collections import Counter
        word_counter = Counter()
        target_dirs = [
            os.path.join(self.root_dir, "backend", "app"),
            os.path.join(self.root_dir, "frontend", "lib")
        ]

        word_regex = re.compile(r'\b[A-Za-z0-9_]+\b')
        for tdir in target_dirs:
            if os.path.exists(tdir):
                for root, _, files in os.walk(tdir):
                    for f in files:
                        if f.endswith(('.py', '.dart')):
                            try:
                                with open(os.path.join(root, f), "r", encoding="utf-8", errors="ignore") as fp:
                                    words = word_regex.findall(fp.read())
                                    word_counter.update(words)
                            except Exception:
                                pass

        dead_models = []
        for model_name, info in models_declared.items():
            count = word_counter.get(model_name, 0)
            if count <= 1:
                dead_models.append({
                    "name": model_name,
                    "file": info["file"],
                    "line": info["line"],
                    "occurrences": count
                })
        return dead_models

# ─────────────────────────────────────────────────────────────────────────────
# HTML DASHBOARD EXPORTER
# ─────────────────────────────────────────────────────────────────────────────
def export_html(engine: XRayEngine, output_file: str = "xray_report.html"):
    report_file = os.path.join(engine.root_dir, output_file)
    with open(report_file, "w", encoding="utf-8") as f:
        f.write(build_html_content(engine))
    return report_file

def build_html_content(engine: XRayEngine) -> str:
    census = engine.census
    routes = engine.routes
    matrix = engine.matrix
    flutter = engine.flutter
    dead_models = engine.dead_models

    return f"""<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <title>Mynix Control — Codebase X-Ray Radar</title>
  <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;700&family=Plus+Jakarta+Sans:wght@400;600;700;800&display=swap" rel="stylesheet">
  <style>
    :root {{ --bg: #0B0E14; --card: #10141D; --border: #1E2433; --text: #E2E8F0; --muted: #8492A6; --primary: #3B82F6; --green: #10B981; --red: #EF4444; --yellow: #F59E0B; }}
    * {{ box-sizing: border-box; margin: 0; padding: 0; }}
    body {{ font-family: 'Plus Jakarta Sans', sans-serif; background: var(--bg); color: var(--text); padding: 32px; }}
    .container {{ max-width: 1400px; margin: 0 auto; }}
    .header {{ display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; border-bottom: 1px solid var(--border); padding-bottom: 20px; }}
    .kpi-grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; margin-bottom: 24px; }}
    .kpi-card {{ background: var(--card); border: 1px solid var(--border); border-radius: 14px; padding: 18px; }}
    .kpi-val {{ font-size: 28px; font-weight: 800; font-family: 'JetBrains Mono', monospace; }}
    .tabs {{ display: flex; gap: 8px; margin-bottom: 20px; border-bottom: 1px solid var(--border); padding-bottom: 10px; }}
    .tab-btn {{ background: transparent; border: none; color: var(--muted); font-size: 14px; font-weight: 700; padding: 8px 16px; border-radius: 8px; cursor: pointer; }}
    .tab-btn.active {{ color: #fff; background: var(--primary); }}
    .tab-content {{ display: none; }}
    .tab-content.active {{ display: block; }}
    .card {{ background: var(--card); border: 1px solid var(--border); border-radius: 14px; padding: 20px; margin-bottom: 20px; }}
    table {{ width: 100%; border-collapse: collapse; font-size: 13px; }}
    th {{ padding: 10px 14px; color: var(--muted); text-transform: uppercase; font-size: 11px; border-bottom: 1px solid var(--border); text-align: left; }}
    td {{ padding: 12px 14px; border-bottom: 1px solid rgba(255,255,255,0.03); }}
    .code {{ font-family: 'JetBrains Mono', monospace; }}
    .badge {{ font-size: 11px; font-weight: 700; padding: 3px 8px; border-radius: 6px; }}
    .badge-green {{ background: rgba(16,185,129,0.15); color: var(--green); }}
    .badge-red {{ background: rgba(239,68,68,0.15); color: var(--red); }}
    .badge-yellow {{ background: rgba(245,158,11,0.15); color: var(--yellow); }}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h2>🔬 Mynix Control — Interactive Codebase Radar</h2>
      <span class="badge badge-green">LIVE AUDIT REPORT</span>
    </div>
    <div class="kpi-grid">
      <div class="kpi-card"><div style="color:var(--muted);font-size:12px;">ВСЕГО СТРОК КОДА</div><div class="kpi-val" style="color:var(--green);">{census['total_lines']:,}</div></div>
      <div class="kpi-card"><div style="color:var(--muted);font-size:12px;">ФАЙЛОВ КОДА</div><div class="kpi-val">{census['total_files']}</div></div>
      <div class="kpi-card"><div style="color:var(--muted);font-size:12px;">ЭНДПОИНТОВ FASTAPI</div><div class="kpi-val" style="color:var(--primary);">{len(routes)}</div></div>
      <div class="kpi-card"><div style="color:var(--muted);font-size:12px;">ФАЙЛОВ >300 СТРОК</div><div class="kpi-val" style="color:var(--red);">{len(census['red_zone'])}</div></div>
      <div class="kpi-card"><div style="color:var(--muted);font-size:12px;">МЕРТВЫЕ МОДЕЛИ</div><div class="kpi-val" style="color:var(--yellow);">{len(dead_models)}</div></div>
    </div>
    <div class="tabs">
      <button class="tab-btn active" onclick="showTab('tab-api')">🔌 Матрица API ({len(routes)})</button>
      <button class="tab-btn" onclick="showTab('tab-security')">🛡️ Безопасность PBAC</button>
      <button class="tab-btn" onclick="showTab('tab-flutter')">📱 Flutter Чистота</button>
      <button class="tab-btn" onclick="showTab('tab-leaderboard')">🏆 Рейтинг Тяжеловесов</button>
      <button class="tab-btn" onclick="showTab('tab-dead')">🧟 Мертвые модели ({len(dead_models)})</button>
    </div>
    <div id="tab-api" class="tab-content active">
      <div class="card">
        <table>
          <thead><tr><th>Метод</th><th>Путь FastAPI</th><th>PBAC Право</th><th>Сессия</th><th>Файл</th></tr></thead>
          <tbody>
            {"".join(f"<tr><td><span class='badge badge-green'>{r['method']}</span></td><td class='code'><strong>{r['path']}</strong></td><td><span class='badge {'badge-green' if r['perm_status']=='OK' else 'badge-red'}'>{r['permission'] or 'PUBLIC'}</span></td><td class='code'>{r['session_type']}</td><td class='code' style='color:var(--muted);'>{r['file']}:{r['line']}</td></tr>" for r in routes)}
          </tbody>
        </table>
      </div>
    </div>
    <div id="tab-security" class="tab-content">
      <div class="card">
        <table>
          <thead><tr><th>Метод и Маршрут</th><th>Статус</th><th>Право</th><th>Изоляция</th><th>Файл</th></tr></thead>
          <tbody>
            {"".join(f"<tr><td class='code'>{r['method']} {r['path']}</td><td><span class='badge {'badge-green' if r['perm_status']=='OK' else 'badge-red'}'>{r['perm_status']}</span></td><td class='code'>{r['permission']}</td><td>{r['session_type']}</td><td class='code' style='color:var(--muted);'>{r['file']}:{r['line']}</td></tr>" for r in routes if r['perm_status'] != 'OK' or r['session_type'] != 'TenantSession')}
          </tbody>
        </table>
      </div>
    </div>
    <div id="tab-flutter" class="tab-content">
      <div class="card">
        <table>
          <thead><tr><th>StatefulWidget (BLoC-only аудит)</th><th>Файл</th><th>Строка</th></tr></thead>
          <tbody>
            {"".join(f"<tr><td class='code text-yellow'>{sw['code']}</td><td class='code'>{sw['file']}</td><td class='code'>{sw['line']}</td></tr>" for sw in flutter.get('stateful_widgets', [])[:30])}
          </tbody>
        </table>
      </div>
    </div>
    <div id="tab-leaderboard" class="tab-content">
      <div class="card">
        <table>
          <thead><tr><th>#</th><th>Строк</th><th>Файл</th><th>Статус</th></tr></thead>
          <tbody>
            {"".join(f"<tr><td class='code'>{idx}</td><td class='code' style='color:var(--red);font-size:15px;font-weight:700;'>{rz['lines']}</td><td class='code'>{rz['path']}</td><td><span class='badge badge-red'>КРАСНАЯ ЗОНА (>300)</span></td></tr>" for idx, rz in enumerate(census['red_zone'], 1))}
          </tbody>
        </table>
      </div>
    </div>
    <div id="tab-dead" class="tab-content">
      <div class="card">
        <table>
          <thead><tr><th>Имя модели</th><th>Файл</th><th>Строка</th><th>Статус</th></tr></thead>
          <tbody>
            {"".join(f"<tr><td class='code' style='color:var(--yellow);'><strong>{dm['name']}</strong></td><td class='code'>{dm['file']}</td><td class='code'>{dm['line']}</td><td><span class='badge badge-red'>0 использований</span></td></tr>" for dm in dead_models)}
          </tbody>
        </table>
      </div>
    </div>
  </div>
  <script>
    function showTab(id) {{
      document.querySelectorAll('.tab-content').forEach(e => e.classList.remove('active'));
      document.querySelectorAll('.tab-btn').forEach(e => e.classList.remove('active'));
      document.getElementById(id).classList.add('active');
      event.target.classList.add('active');
    }}
  </script>
</body>
</html>"""

# ─────────────────────────────────────────────────────────────────────────────
# INTERACTIVE CONSOLE MENU (REPL)
# ─────────────────────────────────────────────────────────────────────────────
def clear_screen():
    # Print separator
    print("\n" + "═"*78 + "\n")

def print_header(engine: XRayEngine):
    c_files = engine.census['total_files']
    c_lines = engine.census['total_lines']
    c_routes = len(engine.routes)
    c_red = len(engine.census['red_zone'])
    c_dead = len(engine.dead_models)

    print(f"{Color.BOLD}{Color.CYAN}╔════════════════════════════════════════════════════════════════════════════╗{Color.RESET}")
    print(f"{Color.BOLD}{Color.CYAN}║             MYNIX CONTROL — INTERACTIVE CODEBASE X-RAY CONSOLE             ║{Color.RESET}")
    print(f"{Color.BOLD}{Color.CYAN}╚════════════════════════════════════════════════════════════════════════════╝{Color.RESET}")
    print(f"  {c('📊 Кодовая база:', Color.WHITE)} {c(f'{c_files} файлов', Color.BOLD)} | {c(f'{c_lines:,} LOC', Color.GREEN)} | {c(f'{c_routes} роутов API', Color.BLUE)} | {c(f'{c_red} файлов >300L', Color.RED)} | {c(f'{c_dead} мертвых моделей', Color.YELLOW)}")
    print(f"{Color.GRAY}──────────────────────────────────────────────────────────────────────────────{Color.RESET}")

def safe_input(prompt_text: str) -> str:
    while True:
        try:
            return input(prompt_text).strip()
        except KeyboardInterrupt:
            print("\n" + c("Для выхода выберите [0] в меню.", Color.YELLOW))
            return ""
        except EOFError:
            return "0"

def print_main_menu(engine: XRayEngine):
    print_header(engine)
    print(f"{Color.BOLD}ГЛАВНОЕ МЕНЮ АУДИТА:{Color.RESET}")
    print(f"  {c('[1]', Color.CYAN)} 🔌 {Color.BOLD}Матрица API{Color.RESET} (Стыковка Frontend Dio ↔ Backend FastAPI)")
    print(f"  {c('[2]', Color.CYAN)} 🛡️  {Color.BOLD}Безопасность & PBAC{Color.RESET} (Аудит прав доступа и Multi-Tenancy)")
    print(f"  {c('[3]', Color.CYAN)} 📱 {Color.BOLD}Чистота Flutter{Color.RESET} (StatefulWidget, вложенность, God-методы)")
    print(f"  {c('[4]', Color.CYAN)} 🏆 {Color.BOLD}Рейтинг Тяжеловесов{Color.RESET} (Красная зона >300 строк, топ монстров)")
    print(f"  {c('[5]', Color.CYAN)} 🧟 {Color.BOLD}Мертвый Код{Color.RESET} (Неиспользуемые модели и забытые классы)")
    print(f"  {c('[6]', Color.CYAN)} 🔍 {Color.BOLD}Глубокий Вход в Слой/Модуль{Color.RESET} (Детальный аудит конкретной папки)")
    print(f"  {c('[7]', Color.CYAN)} 🌐 {Color.BOLD}Открыть HTML-Дашборд{Color.RESET} (Сгенерировать и открыть xray_report.html)")
    print(f"  {c('[R]', Color.GREEN)} 🔄 {Color.BOLD}Пересканировать проект (Rescan){Color.RESET}")
    print(f"  {c('[0]', Color.RED)} 🚪 {Color.BOLD}Выход{Color.RESET}")
    print(f"{Color.GRAY}  (Введите 'M' в любой момент, чтобы показать это меню заново){Color.RESET}")

def run_interactive_console(root_dir: str):
    engine = XRayEngine(root_dir)
    show_menu = True

    while True:
        if show_menu:
            print_main_menu(engine)
            show_menu = False

        choice = safe_input(f"\n{Color.BOLD}X-Ray [0-7, R, M=Меню] > {Color.RESET}").upper()

        if not choice:
            continue

        if choice in ("0", "Q", "QUIT", "EXIT", "ВЫХОД"):
            print(f"\n{c('👋 Завершение работы X-Ray. Чистого кода!', Color.GREEN)}\n")
            break
        elif choice in ("M", "HELP", "?", "МЕНЮ"):
            show_menu = True
        elif choice == "R":
            print(f"\n{c('🔄 Пересканирование всей кодовой базы...', Color.BLUE)}")
            engine.rescan()
            print(f"{c('✅ Готово!', Color.GREEN)}")
            show_menu = True
        elif choice == "1":
            handle_api_menu(engine)
            show_menu = True
        elif choice == "2":
            handle_security_menu(engine)
            show_menu = True
        elif choice == "3":
            handle_flutter_menu(engine)
            show_menu = True
        elif choice == "4":
            handle_leaderboard_menu(engine)
            show_menu = True
        elif choice == "5":
            handle_dead_menu(engine)
            show_menu = True
        elif choice == "6":
            handle_layer_drilldown(engine)
            show_menu = True
        elif choice == "7":
            report_file = export_html(engine)
            print(f"\n{c('✅ HTML-дашборд обновлен:', Color.GREEN)} {report_file}")
            try:
                webbrowser.open(f"file://{os.path.abspath(report_file)}")
                print(f"{c('🌐 Открыто в браузере!', Color.CYAN)}")
            except Exception as e:
                print(f"Файл готов: {report_file}")
            safe_input(f"\n{c('Нажмите Enter для возврата в меню...', Color.GRAY)}")
            show_menu = True
        else:
            print(f"{c('⚠️ Неверная команда: ' + choice + '. Введите число от 0 до 7, R (Rescan) или M (показать меню).', Color.YELLOW)}")

# ─────────────────────────────────────────────────────────────────────────────
# SUBMENUS
# ─────────────────────────────────────────────────────────────────────────────
def handle_api_menu(engine: XRayEngine):
    while True:
        clear_screen()
        print(f"{Color.BOLD}{Color.CYAN}=== 🔌 МАТРИЦА API (Frontend ↔ Backend) ==={Color.RESET}")
        print(f" • Всего эндпоинтов на FastAPI: {len(engine.routes)}")
        print(f" • Всего вызовов Dio во Flutter: {len(engine.frontend_calls)}")
        print(f" • Точных совпадений: {c(str(engine.matrix['matched_count']), Color.GREEN)}")
        print(f" • Неиспользуемых роутов на бэкенде: {c(str(len(engine.matrix['unused_backend'])), Color.YELLOW)}")
        print(f" • Вызовов фронтенда без бэкенда (риск 404): {c(str(len(engine.matrix['broken_frontend'])), Color.RED if engine.matrix['broken_frontend'] else Color.GREEN)}")

        print(f"\n{Color.BOLD}Выберите действие:{Color.RESET}")
        print("  [1] Показать все эндпоинты FastAPI с PBAC-правами")
        print("  [2] Показать неиспользуемые роуты бэкенда")
        print("  [3] Показать вызовы фронтенда без ответа на бэкенде (потенциальные 404)")
        print("  [0] ← Назад в главное меню")

        ch = safe_input(f"\n{Color.BOLD}API Меню > {Color.RESET}")
        if ch in ("0", "Q", "QUIT", "BACK"):
            break
        elif ch == "1":
            print(f"\n{Color.BOLD}{'МЕТОД':<7} {'МАРШРУТ':<45} {'ПРАВО PBAC':<22} {'СЕССИЯ':<15}{Color.RESET}")
            print("─"*90)
            for r in engine.routes:
                p_col = Color.GREEN if r['perm_status'] == 'OK' else Color.RED
                print(f"{c(r['method'], Color.CYAN):<16} {r['path']:<45} {c(str(r['permission']), p_col):<30} {r['session_type']:<15}")
            safe_input(f"\n{c('Нажмите Enter для продолжения...', Color.GRAY)}")
        elif ch == "2":
            print(f"\n{Color.BOLD}НЕИСПОЛЬЗУЕМЫЕ ЭНДПОИНТЫ БЭКЕНДА (Нет вызовов во Flutter):{Color.RESET}")
            for r in engine.matrix['unused_backend']:
                print(f" • {r['method']:6} {r['path']:40} | {r['file']}")
            safe_input(f"\n{c('Нажмите Enter для продолжения...', Color.GRAY)}")
        elif ch == "3":
            print(f"\n{Color.BOLD}ВЫЗОВЫ FLUTTER БЕЗ СОВПАДЕНИЙ НА БЭКЕНДЕ:{Color.RESET}")
            if not engine.matrix['broken_frontend']:
                print(f"{c('✅ Отлично! Все вызовы фронтенда стыкуются с бэкендом.', Color.GREEN)}")
            else:
                for fc in engine.matrix['broken_frontend']:
                    print(f" • {fc['method']:6} {fc['raw_uri']:35} | {fc['file']}:{fc['line']}")
            safe_input(f"\n{c('Нажмите Enter для продолжения...', Color.GRAY)}")

def handle_security_menu(engine: XRayEngine):
    while True:
        clear_screen()
        unguarded = [r for r in engine.routes if r['perm_status'] != 'OK' and not r['path'].endswith('/health') and not r['path'] == '/']
        tenant_leaks = [r for r in engine.routes if r['session_type'] == 'PublicSession' and 'system' not in r['module'] and 'auth' not in r['path']]

        print(f"{Color.BOLD}{Color.CYAN}=== 🛡️ БЕЗОПАСНОСТЬ, PBAC И MULTI-TENANCY ==={Color.RESET}")
        print(f" • Всего эндпоинтов: {len(engine.routes)}")
        print(f" • Незащищенных эндпоинтов (без PBAC): {c(str(len(unguarded)), Color.RED if unguarded else Color.GREEN)}")
        print(f" • Рисков утечки схем (Public session вместо Tenant): {c(str(len(tenant_leaks)), Color.RED if tenant_leaks else Color.GREEN)}")

        print(f"\n{Color.BOLD}Выберите действие:{Color.RESET}")
        print("  [1] Показать все незащищенные роуты (PUBLIC / UNGUARDED)")
        print("  [2] Показать все эндпоинты с корректной PBAC-защитой")
        print("  [3] Показать список всех зарегистрированных прав в seed.py")
        print("  [0] ← Назад в главное меню")

        ch = safe_input(f"\n{Color.BOLD}Безопасность Меню > {Color.RESET}")
        if ch in ("0", "Q", "QUIT", "BACK"):
            break
        elif ch == "1":
            print(f"\n{Color.BOLD}🔴 НЕЗАЩИЩЕННЫЕ ЭНДПОИНТЫ (ТРЕБУЮТ require_permission):{Color.RESET}")
            for r in unguarded:
                print(f"  • {c(r['method'], Color.YELLOW):<15} {r['path']:<45} | {r['file']}:{r['line']}")
            safe_input(f"\n{c('Нажмите Enter для продолжения...', Color.GRAY)}")
        elif ch == "2":
            print(f"\n{Color.BOLD}🟢 ЗАЩИЩЕННЫЕ ЭНДПОИНТЫ:{Color.RESET}")
            guarded = [r for r in engine.routes if r['perm_status'] == 'OK']
            for r in guarded:
                print(f"  • {r['method']:6} {r['path']:40} -> {c(r['permission'], Color.GREEN)}")
            safe_input(f"\n{c('Нажмите Enter для продолжения...', Color.GRAY)}")
        elif ch == "3":
            perms = engine._get_seeded_permissions()
            print(f"\n{Color.BOLD}РЕЕСТР ПРАВ (seed.py — {len(perms)} прав):{Color.RESET}")
            for p in sorted(perms):
                print(f"  • {c(p, Color.CYAN)}")
            safe_input(f"\n{c('Нажмите Enter для продолжения...', Color.GRAY)}")

def handle_flutter_menu(engine: XRayEngine):
    while True:
        clear_screen()
        fl = engine.flutter
        print(f"{Color.BOLD}{Color.CYAN}=== 📱 АУДИТ ЧИСТОТЫ И АРХИТЕКТУРЫ FLUTTER ==={Color.RESET}")
        print(f" • StatefulWidget (BLoC-only конституция): {c(str(len(fl.get('stateful_widgets', []))), Color.YELLOW)}")
        print(f" • Вызовов setState() в UI: {c(str(len(fl.get('set_state_usages', []))), Color.YELLOW)}")
        print(f" • Файлов с глубокой вложенностью (>12 уровней): {c(str(len(fl.get('deep_nesting_files', []))), Color.RED if fl.get('deep_nesting_files') else Color.GREEN)}")
        print(f" • Слишком длинных методов build() (>90 строк): {c(str(len(fl.get('god_build_methods', []))), Color.RED if fl.get('god_build_methods') else Color.GREEN)}")

        print(f"\n{Color.BOLD}Выберите действие:{Color.RESET}")
        print("  [1] Показать список StatefulWidget")
        print("  [2] Показать файлы с глубокой вложенностью (Pyramid of Doom)")
        print("  [3] Показать огромные build() методы (>90 строк)")
        print("  [0] ← Назад в главное меню")

        ch = safe_input(f"\n{Color.BOLD}Flutter Меню > {Color.RESET}")
        if ch in ("0", "Q", "QUIT", "BACK"):
            break
        elif ch == "1":
            print(f"\n{Color.BOLD}STATEFUL WIDGETS:{Color.RESET}")
            for sw in fl.get('stateful_widgets', []):
                print(f"  • {sw['file']}:{sw['line']} -> {c(sw['code'], Color.YELLOW)}")
            safe_input(f"\n{c('Нажмите Enter для продолжения...', Color.GRAY)}")
        elif ch == "2":
            print(f"\n{Color.BOLD}ФАЙЛЫ С ГЛУБОКОЙ ВЛОЖЕННОСТЬЮ ВИДЖЕТОВ (>12 уровней):{Color.RESET}")
            for dn in fl.get('deep_nesting_files', []):
                print(f"  • Глубина {c(str(dn['depth']), Color.RED)} | {dn['file']}")
            safe_input(f"\n{c('Нажмите Enter для продолжения...', Color.GRAY)}")
        elif ch == "3":
            print(f"\n{Color.BOLD}ОГРОМНЫЕ BUILD МЕТОДЫ (ТРЕБУЮТ ВЫНОСА В WIDGETS):{Color.RESET}")
            for gb in fl.get('god_build_methods', []):
                gb_lines = gb['lines']
                print(f"  • {c(f'{gb_lines} строк build()', Color.RED)} | {gb['file']}:{gb['line']}")
            safe_input(f"\n{c('Нажмите Enter для продолжения...', Color.GRAY)}")

def handle_leaderboard_menu(engine: XRayEngine):
    while True:
        clear_screen()
        c_red = engine.census['red_zone']
        c_yellow = engine.census['yellow_zone']
        print(f"{Color.BOLD}{Color.CYAN}=== 🏆 РЕЙТИНГ ФАЙЛОВ ПО РАЗМЕРУ ==={Color.RESET}")
        print(f" • 🔴 Красная зона (>300 строк): {c(str(len(c_red)), Color.RED)}")
        print(f" • 🟡 Желтая зона (250–300 строк): {c(str(len(c_yellow)), Color.YELLOW)}")
        print(f" • 🟢 Зеленая зона (100–249 строк): {c(str(engine.census['green_zone_count']), Color.GREEN)}")
        print(f" • ⚡ Микро-компоненты (<100 строк): {c(str(engine.census['micro_zone_count']), Color.CYAN)}")

        print(f"\n{Color.BOLD}Выберите действие:{Color.RESET}")
        print("  [1] Показать все файлы Красной зоны (>300 строк)")
        print("  [2] Показать все файлы Желтой зоны (250–300 строк)")
        print("  [3] Топ-30 самых больших файлов проекта")
        print("  [0] ← Назад в главное меню")

        ch = safe_input(f"\n{Color.BOLD}Рейтинг Меню > {Color.RESET}")
        if ch in ("0", "Q", "QUIT", "BACK"):
            break
        elif ch == "1":
            print(f"\n{Color.BOLD}🔴 ФАЙЛЫ В КРАСНОЙ ЗОНЕ (>300 СТРОК):{Color.RESET}")
            for idx, r in enumerate(c_red, 1):
                r_lines = r['lines']
                print(f"  {idx:2}. {c(f'{r_lines:4} строк', Color.RED)} | {r['path']}")
            safe_input(f"\n{c('Нажмите Enter для продолжения...', Color.GRAY)}")
        elif ch == "2":
            print(f"\n{Color.BOLD}🟡 ФАЙЛЫ В ЖЕЛТОЙ ЗОНЕ (250-300 СТРОК):{Color.RESET}")
            for idx, r in enumerate(c_yellow, 1):
                r_lines = r['lines']
                print(f"  {idx:2}. {c(f'{r_lines:4} строк', Color.YELLOW)} | {r['path']}")
            safe_input(f"\n{c('Нажмите Enter для продолжения...', Color.GRAY)}")
        elif ch == "3":
            print(f"\n{Color.BOLD}ТОП-30 САМЫХ БОЛЬШИХ ФАЙЛОВ ПРОЕКТА:{Color.RESET}")
            for idx, r in enumerate(engine.census['leaderboard'][:30], 1):
                col = Color.RED if r['lines'] > 300 else (Color.YELLOW if r['lines'] >= 250 else Color.GREEN)
                r_lines = r['lines']
                print(f"  {idx:2}. {c(f'{r_lines:4} строк', col)} | {r['path']}")
            safe_input(f"\n{c('Нажмите Enter для продолжения...', Color.GRAY)}")

def handle_dead_menu(engine: XRayEngine):
    clear_screen()
    print(f"{Color.BOLD}{Color.CYAN}=== 🧟 МЕРТВЫЙ КОД И НЕИСПОЛЬЗУЕМЫЕ МОДЕЛИ ==={Color.RESET}")
    print(f"Найдено моделей/схем с 0 вызовов в проекте: {c(str(len(engine.dead_models)), Color.YELLOW)}\n")
    for dm in engine.dead_models:
        print(f" • Модель {c(dm['name'], Color.YELLOW)} в {dm['file']}:{dm['line']} — {c('0 использований', Color.RED)}")
    safe_input(f"\n{c('Нажмите Enter для возврата...', Color.GRAY)}")

def handle_layer_drilldown(engine: XRayEngine):
    while True:
        clear_screen()
        print(f"{Color.BOLD}{Color.CYAN}=== 🔍 ГЛУБОКИЙ ВХОД В МОДУЛЬ / СЛОЙ ==={Color.RESET}")
        print(f"{Color.BOLD}БЭКЕНД МОДУЛИ (backend/app/):{Color.RESET}")
        b_mods = sorted(engine.backend_modules.keys())
        for idx, mod in enumerate(b_mods, 1):
            info = engine.backend_modules[mod]
            print(f"  [B{idx}] ⚙️  backend/app/{mod:<15} ({len(info['files'])} файлов, {info['lines']} LOC)")

        print(f"\n{Color.BOLD}ФРОНТЕНД ФИЧИ (frontend/lib/features/):{Color.RESET}")
        f_mods = sorted(engine.frontend_features.keys())
        for idx, feat in enumerate(f_mods, 1):
            info = engine.frontend_features[feat]
            print(f"  [F{idx}] 📱 frontend/lib/features/{feat:<12} ({len(info['files'])} файлов, {info['lines']} LOC)")

        print(f"\n  [0] ← Назад в главное меню")

        ch = safe_input(f"\n{Color.BOLD}Выберите модуль (например B1 или F1) > {Color.RESET}").upper()
        if ch in ("0", "Q", "QUIT", "BACK"):
            break
        elif ch.startswith("B") and ch[1:].isdigit():
            idx = int(ch[1:]) - 1
            if 0 <= idx < len(b_mods):
                mod_name = b_mods[idx]
                show_module_detail(engine, f"backend/app/{mod_name}", engine.backend_modules[mod_name])
        elif ch.startswith("F") and ch[1:].isdigit():
            idx = int(ch[1:]) - 1
            if 0 <= idx < len(f_mods):
                feat_name = f_mods[idx]
                show_module_detail(engine, f"frontend/lib/features/{feat_name}", engine.frontend_features[feat_name])

def show_module_detail(engine: XRayEngine, title: str, data: Dict[str, Any]):
    clear_screen()
    files = sorted(data["files"], key=lambda x: x["lines"], reverse=True)
    print(f"{Color.BOLD}{Color.CYAN}=== ДЕТАЛЬНЫЙ АУДИТ: {title} ==={Color.RESET}")
    print(f" • Всего файлов: {len(files)}")
    print(f" • Всего строк кода: {data['lines']} LOC\n")

    print(f"{Color.BOLD}{'#':<3} {'СТРОК':<8} {'СТАТУС':<12} {'ФАЙЛ':<50}{Color.RESET}")
    print("─"*78)
    for idx, f in enumerate(files, 1):
        lines = f["lines"]
        if lines > 300:
            status = c("🔴 >300L", Color.RED)
            l_str = c(str(lines), Color.RED)
        elif lines >= 250:
            status = c("🟡 250-300", Color.YELLOW)
            l_str = c(str(lines), Color.YELLOW)
        else:
            status = c("🟢 OK", Color.GREEN)
            l_str = c(str(lines), Color.GREEN)

        print(f"{idx:<3} {l_str:<16} {status:<20} {f['path']}")

    safe_input(f"\n{c('Нажмите Enter для возврата к выбору слоев...', Color.GRAY)}")

# ─────────────────────────────────────────────────────────────────────────────
# MAIN DISPATCHER
# ─────────────────────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description="Mynix Control X-Ray Audit System")
    parser.add_argument("--json", action="store_true", help="Dump full audit report in JSON to stdout (for AI agents)")
    parser.add_argument("--html", nargs="?", const="xray_report.html", help="Generate standalone HTML dashboard report and exit")
    parser.add_argument("--security", action="store_true", help="Run non-interactive security audit and exit")
    parser.add_argument("--api", action="store_true", help="Run non-interactive API matrix audit and exit")
    parser.add_argument("--flutter", action="store_true", help="Run non-interactive Flutter health audit and exit")
    parser.add_argument("--leaderboard", action="store_true", help="Run non-interactive file leaderboard audit and exit")
    parser.add_argument("--ci", action="store_true", help="Run CI validation and exit with non-zero code on failures")
    args = parser.parse_args()

    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..")) if "scripts" in os.path.dirname(__file__) else os.getcwd()

    if args.json:
        engine = XRayEngine(root_dir)
        report = {
            "census": engine.census,
            "routes": engine.routes,
            "frontend_calls": engine.frontend_calls,
            "matrix": engine.matrix,
            "flutter": engine.flutter,
            "dead_models": engine.dead_models,
            "backend_modules": engine.backend_modules,
            "frontend_features": engine.frontend_features
        }
        print(json.dumps(report, indent=2, ensure_ascii=False))
        sys.exit(0)

    if args.html:
        engine = XRayEngine(root_dir)
        output_file = args.html if isinstance(args.html, str) else "xray_report.html"
        report_path = export_html(engine, output_file)
        print(f"✅ HTML report generated: {report_path}")
        sys.exit(0)

    if args.security:
        engine = XRayEngine(root_dir)
        unguarded = [r for r in engine.routes if r['perm_status'] != 'OK' and not r['path'].endswith('/health') and not r['path'] == '/']
        print(f"=== 🛡️ SECURITY & PBAC AUDIT ===")
        print(f"Total Routes: {len(engine.routes)}")
        print(f"Unguarded Routes: {len(unguarded)}")
        for r in unguarded:
            print(f"  [UNGUARDED] {r['method']:6} {r['path']:45} | {r['file']}:{r['line']}")
        sys.exit(1 if unguarded else 0)

    if args.api:
        engine = XRayEngine(root_dir)
        print(f"=== 🔌 API CONNECTIVITY MATRIX ===")
        print(f"FastAPI Routes: {len(engine.routes)}")
        print(f"Flutter Dio Calls: {len(engine.frontend_calls)}")
        print(f"Matched Routes: {engine.matrix['matched_count']}")
        print(f"Unused Backend Routes: {len(engine.matrix['unused_backend'])}")
        print(f"Broken Frontend Calls: {len(engine.matrix['broken_frontend'])}")
        if engine.matrix['broken_frontend']:
            print("\nPotential 404 Calls in Frontend:")
            for fc in engine.matrix['broken_frontend']:
                print(f"  [404 RISK] {fc['method']:6} {fc['raw_uri']:35} | {fc['file']}:{fc['line']}")
        sys.exit(0)

    if args.flutter:
        engine = XRayEngine(root_dir)
        fl = engine.flutter
        print(f"=== 📱 FLUTTER HEALTH AUDIT ===")
        print(f"StatefulWidgets: {len(fl.get('stateful_widgets', []))}")
        print(f"setState usages: {len(fl.get('set_state_usages', []))}")
        print(f"Deep Nesting Files (>12 levels): {len(fl.get('deep_nesting_files', []))}")
        print(f"God Build Methods (>90 lines): {len(fl.get('god_build_methods', []))}")
        sys.exit(0)

    if args.leaderboard:
        engine = XRayEngine(root_dir)
        print(f"=== 🏆 FILE LEADERBOARD ===")
        print(f"Red Zone (>300 lines): {len(engine.census['red_zone'])}")
        for idx, r in enumerate(engine.census['red_zone'], 1):
            print(f"  {idx:2}. {r['lines']:4} lines | {r['path']}")
        sys.exit(0)

    if args.ci:
        engine = XRayEngine(root_dir)
        unguarded = [r for r in engine.routes if r['perm_status'] != 'OK' and not r['path'].endswith('/health') and not r['path'] == '/']
        if unguarded:
            print(f"CI FAILURE: {len(unguarded)} unguarded routes found!")
            sys.exit(1)
        print("CI SUCCESS: All checks passed.")
        sys.exit(0)

    # Launch Interactive Console by default
    run_interactive_console(root_dir)

if __name__ == "__main__":
    main()
