#!/usr/bin/env python3
"""
Kreso Flow - Architectural Invariant Verification Tool
Enforces core rules from AGENTS.md:
  1. Multi-Tenancy: Zero 'tenant_id' in backend domain models.
  2. PBAC: Protected endpoints in router.py files.
  3. Micro-Architecture:
     - Target: <= 250 lines.
     - Hard ceiling: <= 300 lines (allowed up to 350 for cohesive BLoCs/transactions).
     - Taboo on micro-files: Warning on Dart feature files < 60 lines (except barrels).
  4. Design System / UI Kit:
     - Zero raw colors (Colors.*, Color(0x...)) outside core/theme.
     - Zero raw buttons (ElevatedButton, TextButton, OutlinedButton) in feature widgets.
  5. Financial & Balance Operations:
     - [LOCK-STALE-READ]: Mandatory populate_existing=True for any with_for_update call.
     - [IDEMPOTENCY-DEBT]: Mandatory client_uuid for mutating balance operations.
"""

import sys
import os
import re
import ast
import argparse
from pathlib import Path
from typing import List, Dict, Tuple, Set

# Ensure UTF-8 output on Windows consoles
if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

# ANSI Colors
class C:
    RESET = "\033[0m"
    BOLD = "\033[1m"
    RED = "\033[91m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    CYAN = "\033[96m"
    GRAY = "\033[90m"

def c(text: str, color: str) -> str:
    return f"{color}{text}{C.RESET}"


class RuleChecker:
    def __init__(self, root: Path, strict: bool = False, target: str = None):
        self.root = root
        self.strict = strict
        self.target = target
        self.errors: List[str] = []
        self.warnings: List[str] = []
        self.financial_warnings: List[str] = []

        # Allowed exemptions for cohesive complex files (up to 350 lines)
        self.cohesive_exemptions: Set[str] = {
            "menu_bloc.dart",
            "cart_bloc.dart",
            "shift_service.py",
        }

        # Known legacy technical debt files scheduled for modular decomposition
        self.legacy_oversized_baseline: Set[str] = {
            "checkout_service.py",
            "order_table_service.py",
            "category_service.py",
            "login_screen.dart",
            "stock_tab.dart",
            "catalog_browser_tab.dart",
            "ingredient_tab.dart",
            "create_ingredient_dialog.dart",
            "ingredient_grid_view.dart",
            "recipe_empty_dashboard.dart",
            "pos_screen.dart",
            "pos_active_table_card.dart",
            "menu_item_modal.dart",
            "create_retail_product_dialog.dart",
        }

        # Exempt files from UI Kit button/color rules (themes, low-level pickers)
        self.ui_kit_exempt_paths = [
            "core/theme",
            "core/widgets/color_picker",
            "core/widgets/ui_kit",
        ]

    def _is_exempt_ui(self, rel_path: str) -> bool:
        normalized = rel_path.replace("\\", "/")
        return any(exempt in normalized for exempt in self.ui_kit_exempt_paths)

    def check_backend_multi_tenancy(self):
        """Rule 1: Never add tenant_id column to domain models (schema isolation)."""
        backend_app = self.root / "backend" / "app"
        if not backend_app.exists():
            return

        pattern = re.compile(r"^\s*tenant_id\s*:\s*.*=\s*Field\(", re.MULTILINE)
        col_pattern = re.compile(r"^\s*tenant_id\s*=\s*Column\(", re.MULTILINE)

        for py_file in backend_app.rglob("*.py"):
            rel = py_file.relative_to(self.root).as_posix()
            # Users models are allowed to link User -> Tenant in public schema
            if "users/models.py" in rel:
                continue

            try:
                content = py_file.read_text(encoding="utf-8", errors="ignore")
            except Exception:
                continue

            for match in pattern.finditer(content):
                line_no = content.count("\n", 0, match.start()) + 1
                self.errors.append(
                    f"[MULTI-TENANCY] {rel}:{line_no} Forbidden 'tenant_id' Field found! "
                    f"Kreso Flow uses schema-based isolation (search_path)."
                )
            for match in col_pattern.finditer(content):
                line_no = content.count("\n", 0, match.start()) + 1
                self.errors.append(
                    f"[MULTI-TENANCY] {rel}:{line_no} Forbidden 'tenant_id' Column found! "
                    f"Kreso Flow uses schema-based isolation (search_path)."
                )

    def check_backend_pbac(self):
        """Rule 2: Ensure router endpoints are protected by PBAC dependencies."""
        backend_app = self.root / "backend" / "app"
        if not backend_app.exists():
            return

        router_files = list(backend_app.rglob("*router*.py")) + list(backend_app.rglob("router.py"))
        exempt_routers = {"auth_router.py", "database_router.py"}

        for r_file in router_files:
            rel = r_file.relative_to(self.root).as_posix()
            if self.target and self.target not in rel:
                continue
            if r_file.name in exempt_routers:
                continue

            try:
                content = r_file.read_text(encoding="utf-8", errors="ignore")
            except Exception:
                continue

            has_pbac = (
                "require_permission" in content
                or "require_any_permission" in content
                or "CurrentUser" in content
                or "get_current_user" in content
            )
            if not has_pbac and "@router." in content:
                self.warnings.append(
                    f"[PBAC DEBT] {rel} defines routes but lacks require_permission / require_any_permission guards."
                )

    @staticmethod
    def _inspect_ast_lock_stale_read(tree: ast.AST) -> Tuple[int, List[Tuple[int, str]]]:
        for parent in ast.walk(tree):
            for child in ast.iter_child_nodes(parent):
                child.parent = parent  # type: ignore

        wfu_count = 0
        violations: List[Tuple[int, str]] = []

        def is_truthy(val_node: ast.AST) -> bool:
            if isinstance(val_node, ast.Constant) and val_node.value is True:
                return True
            if isinstance(val_node, ast.Name) and val_node.id == "True":
                return True
            return False

        for node in ast.walk(tree):
            if not isinstance(node, ast.Call):
                continue

            # Form 1: session.get(..., with_for_update=True)
            if isinstance(node.func, ast.Attribute) and node.func.attr == "get":
                wfu_kw = next((kw for kw in node.keywords if kw.arg == "with_for_update"), None)
                if wfu_kw and is_truthy(wfu_kw.value):
                    wfu_count += 1
                    pe_kw = next((kw for kw in node.keywords if kw.arg == "populate_existing"), None)
                    if not pe_kw or not is_truthy(pe_kw.value):
                        violations.append(
                            (node.lineno, "session.get() с with_for_update без populate_existing=True")
                        )

            # Form 2: query.with_for_update(...)
            elif isinstance(node.func, ast.Attribute) and node.func.attr == "with_for_update":
                wfu_count += 1
                curr = node
                stmt_node = node
                while hasattr(curr, "parent"):
                    curr = curr.parent  # type: ignore
                    if isinstance(curr, (ast.stmt, ast.Expr, ast.Assign, ast.AnnAssign, ast.Return, ast.AsyncFor, ast.For)):
                        stmt_node = curr
                        break

                has_pe = False
                for sub in ast.walk(stmt_node):
                    if isinstance(sub, ast.Call) and isinstance(sub.func, ast.Attribute) and sub.func.attr == "execution_options":
                        for kw in sub.keywords:
                            if kw.arg == "populate_existing" and is_truthy(kw.value):
                                has_pe = True
                                break
                            if kw.arg is None and isinstance(kw.value, ast.Dict):
                                for k, v in zip(kw.value.keys, kw.value.values):
                                    if isinstance(k, ast.Constant) and k.value == "populate_existing" and is_truthy(v):
                                        has_pe = True
                                        break
                    if has_pe:
                        break

                if not has_pe:
                    violations.append(
                        (node.lineno, "select().with_for_update() без .execution_options(populate_existing=True)")
                    )

        return wfu_count, violations

    def run_lock_stale_read_self_test(self) -> bool:
        bad_get = "async def f(s): return await s.get(User, 1, with_for_update=True)"
        good_get = "async def f(s): return await s.get(User, 1, with_for_update=True, populate_existing=True)"
        bad_select = "async def f(s): q = select(User).where(User.id == 1).with_for_update(); return await s.execute(q)"
        good_select = "async def f(s): q = select(User).where(User.id == 1).with_for_update().execution_options(populate_existing=True); return await s.execute(q)"

        c1, v1 = self._inspect_ast_lock_stale_read(ast.parse(bad_get))
        c2, v2 = self._inspect_ast_lock_stale_read(ast.parse(good_get))
        c3, v3 = self._inspect_ast_lock_stale_read(ast.parse(bad_select))
        c4, v4 = self._inspect_ast_lock_stale_read(ast.parse(good_select))

        passed = (
            c1 == 1 and len(v1) == 1
            and c2 == 1 and len(v2) == 0
            and c3 == 1 and len(v3) == 1
            and c4 == 1 and len(v4) == 0
        )
        if not passed:
            print(c("  [LOCK-STALE-READ] ОШИБКА: Самотест чекера не прошел!", C.RED + C.BOLD))
            sys.exit(1)

        print(c("  [LOCK-STALE-READ] самотест успешно пройден (4/4 сценария: bad_get, good_get, bad_select, good_select)", C.GREEN))
        return True

    def check_backend_lock_stale_read(self):
        """Rule 2.1: Проверка [LOCK-STALE-READ] — любой with_for_update обязан сопровождаться populate_existing=True."""
        self.run_lock_stale_read_self_test()

        backend_app = self.root / "backend" / "app"
        if not backend_app.exists():
            return

        total_wfu = 0
        all_py_files = sorted(backend_app.rglob("*.py"))

        for py_file in all_py_files:
            rel = py_file.relative_to(self.root).as_posix()
            if self.target and self.target not in rel:
                continue

            try:
                content = py_file.read_text(encoding="utf-8-sig", errors="ignore")
                tree = ast.parse(content)
            except Exception:
                continue

            wfu_count, violations = self._inspect_ast_lock_stale_read(tree)
            total_wfu += wfu_count

            for lineno, desc in violations:
                msg = (
                    f"[LOCK-STALE-READ] {rel}:{lineno}: "
                    f"{desc}. Любой FOR UPDATE обязан сопровождаться populate_existing=True."
                )
                self.financial_warnings.append(msg)
                if self.strict:
                    self.errors.append(msg)
                else:
                    self.warnings.append(msg)

        if not self.target and total_wfu == 0:
            err = "[LOCK-STALE-READ] ОШИБКА: проанализировано 0 вызовов with_for_update"
            self.errors.append(err)
            print(c(f"  {err}", C.RED + C.BOLD))
            if self.strict:
                sys.exit(1)
        else:
            print(c(f"  [LOCK-STALE-READ] проанализировано {total_wfu} вызовов with_for_update", C.CYAN))

    def check_backend_balance_operations(self):
        """Rule 2.2: Проверка безопасности денежных операций и балансов:
        [IDEMPOTENCY-DEBT]: Мутация баланса без client_uuid в файле.
        Денежная операция без client_uuid — риск двойного списания при повторной отправке.
        """
        backend_app = self.root / "backend" / "app"
        if not backend_app.exists():
            return

        target_keywords = [
            "balance", "redeem", "topup", "top_up",
            "deduct", "withdraw", "deposit", "cash_operation"
        ]

        balance_mutation_pattern = re.compile(
            r'(\.\w*balance\s*[\+\-\*\/]?=|\bbalance\b\s*[\+\-\*\/]?=|\b(GiftCardTransaction|CashTransaction|CustomerTransaction|BonusTransaction)\b)',
            re.IGNORECASE,
        )

        service_files: List[Path] = []
        for py_file in backend_app.rglob("*.py"):
            parts = [p.lower() for p in py_file.parts]
            name = py_file.name.lower()
            if name.startswith("services") or "services" in parts or "service" in name:
                service_files.append(py_file)

        for s_file in sorted(service_files):
            rel = s_file.relative_to(self.root).as_posix()
            if self.target and self.target not in rel:
                continue

            try:
                content = s_file.read_text(encoding="utf-8-sig", errors="ignore")
                tree = ast.parse(content)
            except Exception:
                continue

            has_client_uuid_in_file = "client_uuid" in content

            for node in ast.walk(tree):
                if not isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                    continue

                fn_name_lower = node.name.lower()
                if not any(kw in fn_name_lower for kw in target_keywords):
                    continue

                fn_code = ast.get_source_segment(content, node) or ""

                # ─── Pattern 2b: Balance mutation without client_uuid in file ──────
                has_balance_mutation = False
                for child in ast.walk(node):
                    if isinstance(child, (ast.Assign, ast.AugAssign)):
                        targets = child.targets if isinstance(child, ast.Assign) else [child.target]
                        for target in targets:
                            if isinstance(target, ast.Attribute) and "balance" in target.attr.lower():
                                has_balance_mutation = True
                                break
                            if isinstance(target, ast.Name) and "balance" in target.id.lower():
                                has_balance_mutation = True
                                break
                    if isinstance(child, ast.Call):
                        func_name = ""
                        if isinstance(child.func, ast.Name):
                            func_name = child.func.id
                        elif isinstance(child.func, ast.Attribute):
                            func_name = child.func.attr
                        if any(txn in func_name for txn in ("GiftCardTransaction", "CashTransaction", "CustomerTransaction", "BonusTransaction")):
                            has_balance_mutation = True
                            break
                    if has_balance_mutation:
                        break

                if not has_balance_mutation:
                    has_balance_mutation = bool(balance_mutation_pattern.search(fn_code))

                if has_balance_mutation and not has_client_uuid_in_file:
                    msg = (
                        f"[IDEMPOTENCY-DEBT] {rel}:{node.lineno} in '{node.name}': "
                        f"Денежная операция без client_uuid — риск двойного списания при повторной отправке"
                    )
                    self.financial_warnings.append(msg)
                    if self.strict:
                        self.errors.append(msg)
                    else:
                        self.warnings.append(msg)

    def check_file_line_limits(self):
        """Rule 3: File limits: Warning > 250, Error > 300 (or >350 for cohesive domain files)."""
        # Backend routers and services
        backend_paths = list((self.root / "backend" / "app").rglob("*.py"))
        # Frontend feature files
        frontend_features = self.root / "frontend" / "lib" / "features"
        frontend_paths = list(frontend_features.rglob("*.dart")) if frontend_features.exists() else []

        for fpath in backend_paths + frontend_paths:
            rel = fpath.relative_to(self.root).as_posix()
            if self.target and self.target not in rel:
                continue

            try:
                with open(fpath, "r", encoding="utf-8", errors="ignore") as f:
                    lines = f.readlines()
                count = len(lines)
            except Exception:
                continue

            filename = fpath.name

            # Domain Cohesion: Allow up to 350 lines for indivisible BLoCs and transactional services
            has_domain_badge = any(
                "[ИНВАРИАНТ]" in line or "[ТРАНЗАКЦИЯ]" in line for line in lines[:40]
            )
            is_cohesive = (
                filename in self.cohesive_exemptions
                or filename.endswith("_bloc.dart")
                or (filename.endswith("_service.py") and has_domain_badge)
            )
            is_legacy = filename in self.legacy_oversized_baseline
            ceiling = 350 if is_cohesive else 300

            if count > ceiling:
                if is_legacy and not self.strict:
                    self.warnings.append(
                        f"[LEGACY-LIMIT-DEBT] {rel} has {count} lines (exceeds {ceiling}, tracked for modular refactoring)."
                    )
                else:
                    self.errors.append(
                        f"[FILE-LIMIT] {rel} has {count} lines (exceeds hard ceiling of {ceiling} lines)."
                    )
            elif count > 250:
                self.warnings.append(
                    f"[FILE-LIMIT] {rel} has {count} lines (exceeds recommended target of 250 lines)."
                )

    def check_taboo_micro_files(self):
        """Rule: Taboo on micro-files (< 60 lines) in Flutter feature UI widgets.
        Domain-Driven Design exception: Pure enums, value objects, exceptions, and models
        are autonomous domain atoms and exempted from micro-widget taboo.
        """
        frontend_features = self.root / "frontend" / "lib" / "features"
        if not frontend_features.exists():
            return

        for dart_file in frontend_features.rglob("*.dart"):
            rel = dart_file.relative_to(self.root).as_posix()
            if self.target and self.target not in rel:
                continue

            try:
                with open(dart_file, "r", encoding="utf-8", errors="ignore") as f:
                    raw_lines = f.readlines()
                lines = [line.strip() for line in raw_lines if line.strip() and not line.strip().startswith("//")]
                total_lines = len(raw_lines)
            except Exception:
                continue

            # Check if pure barrel export or stub
            is_barrel = all(line.startswith("export ") or line.startswith("import ") for line in lines)
            is_stub = dart_file.name.endswith("_stub.dart")

            # Check if domain atomic model, enum, event, state, or contract
            is_domain_atom = any(
                part in rel.lower() for part in ["/models/", "/enums/", "/domain/", "/exceptions/"]
            )
            content_str = " ".join(lines)
            is_pure_enum_or_typedef = (
                content_str.startswith("enum ")
                or "typedef " in content_str
            ) and "Widget" not in content_str and "State<" not in content_str

            if total_lines < 60 and not is_barrel and not is_stub and not is_domain_atom and not is_pure_enum_or_typedef:
                self.warnings.append(
                    f"[MICRO-WIDGET-FILE] {rel} has only {total_lines} lines (< 60 lines taboo). "
                    f"Keep cohesive UI helpers in the parent widget file or group form components."
                )

    def check_design_system(self):
        """Rule: Design System tokens - No raw Colors or buttons."""
        frontend_lib = self.root / "frontend" / "lib"
        if not frontend_lib.exists():
            return

        pat_colors = re.compile(r"(?<!App)Colors\.[a-zA-Z]+")
        pat_color_hex = re.compile(r"\bColor\(0x[0-9a-fA-F]+\)")
        pat_buttons = re.compile(r"\b(ElevatedButton|TextButton|OutlinedButton)\b")

        raw_color_files = []
        raw_button_files = []

        for dart_file in frontend_lib.rglob("*.dart"):
            rel = dart_file.relative_to(self.root).as_posix()
            if self.target and self.target not in rel:
                continue
            if self._is_exempt_ui(rel):
                continue

            try:
                content = dart_file.read_text(encoding="utf-8", errors="ignore")
            except Exception:
                continue

            c_matches = pat_colors.findall(content) + pat_color_hex.findall(content)
            b_matches = pat_buttons.findall(content)

            if c_matches:
                raw_color_files.append((rel, len(c_matches)))
            if b_matches:
                raw_button_files.append((rel, len(b_matches)))

        # If a specific target was requested or strict mode is active, treat as error
        if self.target or self.strict:
            for rel, cnt in raw_color_files:
                self.errors.append(f"[DESIGN-SYSTEM] {rel} has {cnt} raw Colors (use AppColors.*)")
            for rel, cnt in raw_button_files:
                self.errors.append(f"[DESIGN-SYSTEM] {rel} has {cnt} raw buttons (use AppPrimaryButton / AppSecondaryButton)")
        else:
            if raw_color_files:
                self.warnings.append(
                    f"[DESIGN-SYSTEM DEBT] {len(raw_color_files)} legacy files contain raw Colors.* tokens."
                )
            if raw_button_files:
                self.warnings.append(
                    f"[DESIGN-SYSTEM DEBT] {len(raw_button_files)} legacy files contain raw Button widgets."
                )

    def run(self) -> int:
        print(c("==================================================", C.CYAN))
        print(c("        KRESO FLOW — ARCHITECTURAL LINTER         ", C.BOLD + C.CYAN))
        print(c("==================================================", C.CYAN))

        self.check_backend_multi_tenancy()
        self.check_backend_pbac()
        self.check_backend_lock_stale_read()
        self.check_backend_balance_operations()
        self.check_file_line_limits()
        self.check_taboo_micro_files()
        self.check_design_system()

        print("\n" + c("--- RESULTS ---", C.BOLD))

        if not self.errors and not self.warnings:
            print(c("✔ ALL ARCHITECTURAL RULES AND INVARIANTS PASSED!", C.GREEN + C.BOLD))
            return 0

        # Выделенный блок для финансового аудита и безопасности балансов
        if self.financial_warnings:
            print(c(f"\n[!] FINANCIAL & BALANCE AUDIT ({len(self.financial_warnings)}):", C.YELLOW + C.BOLD))
            for w in self.financial_warnings:
                print(c(f"  ⚠ {w}", C.YELLOW))

        # Общие предупреждения (за вычетом финансового аудита)
        general_warnings = [w for w in self.warnings if w not in self.financial_warnings]
        if general_warnings:
            print(c(f"\n[!] GENERAL WARNINGS ({len(general_warnings)}):", C.YELLOW + C.BOLD))
            for w in general_warnings[:20]:
                print(c(f"  ⚠ {w}", C.YELLOW))
            if len(general_warnings) > 20:
                print(c(f"  ... and {len(general_warnings) - 20} more warnings.", C.GRAY))

        if self.errors:
            print(c(f"\n[X] CRITICAL ERRORS ({len(self.errors)}):", C.RED + C.BOLD))
            for e in self.errors:
                print(c(f"  ✖ {e}", C.RED))
            print(c("\nFAILED: Fix critical errors to maintain architectural integrity.", C.RED + C.BOLD))
            return 1

        print(c("\n✔ NO CRITICAL ARCHITECTURAL ERRORS FOUND.", C.GREEN + C.BOLD))
        return 0


def main():
    parser = argparse.ArgumentParser(description="Kreso Flow Architectural Linter")
    parser.add_argument("--strict", action="store_true", help="Treat all warnings as errors")
    parser.add_argument("--target", type=str, default=None, help="Specific file or directory pattern to scan")
    args = parser.parse_args()

    root = Path(__file__).resolve().parent.parent
    checker = RuleChecker(root=root, strict=args.strict, target=args.target)
    sys.exit(checker.run())


if __name__ == "__main__":
    main()
