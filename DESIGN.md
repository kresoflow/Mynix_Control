<!-- =========================================================================== -->
<!-- ДОКУМЕНТ: Design System & UI Kit Specification (DESIGN.md)                  -->
<!-- СТАТУС:   АКТУАЛЬНО (Phase 0: Rebranding, CI/CD & Documentation Hardening)   -->
<!-- ДАТА:     2026-09-19 | Контрольный коммит: e5ae1c6                         -->
<!-- =========================================================================== -->

> [!IMPORTANT] РЕГЛАМЕНТ АКТУАЛИЗАЦИИ ДОКУМЕНТАЦИИ (PHASE-DRIVEN SYNC)
> Данный документ обновляется **централизованно по завершении фаз разработки (Milestones)**. AI-агенты обязаны проверять актуальное состояние кодовой базы инструментами поиска перед внесением изменений.

﻿# Kreso Flow — Official Design System & UI Specification (DESIGN.md)

## 1. Visual Theme & Atmosphere
Kreso Flow is an enterprise-grade ERP, POS, and Warehouse operating system for modern restaurants and retail chains.
The visual identity follows an ultra-clean, high-density, **Linear & Stripe-grade aesthetic**:
- **Silent & Data-First:** The UI never screams at the user. Data (revenue, stock, tables, tickets) is the hero; chrome and containers elegantly frame the content.
- **Multi-Layered Depth:** Interfaces use calibrated surface luminance rather than harsh borders.
- **Glass & Neon Accents:** Subtle backdrop filters, 1px semi-transparent borders (`rgba(255,255,255,0.06)`), and luminous brand glows on interactive elements.

---

## 2. Color Palette & Semantic Roles

### Brand & Accents
- **Brand Primary:** `#0284C7` (Light) / `#38BDF8` (Dark) — Sapphire / Sky Cobalt Blue. Key CTA buttons, active tabs, primary actions.
- **Brand Secondary:** `#0369A1` (Deep Cobalt) — Secondary highlights and subtle accents.
- **Brand Tertiary:** `#0D9488` (Teal Mint) — Analytical badges, secondary metrics.

### Dark Mode Surfaces
- **Canvas / Background (`darkBg`):** `#050B14` (Deep Midnight Obsidian)
- **Primary Surface / Sidebar (`darkSurface`):** `#0A1220` (Dark Navy Surface)
- **Elevated Card / Panels (`darkCard`):** `#0E1A2D` (Card Surface)
- **Hover Surface (`darkCardHover`):** `#15243C` (Interactive hover)
- **Subtle Border (`darkBorder`):** `#1E3250` (1px structure)
- **Text Primary (`darkText`):** `#E0F2FE` (Luminous cool white, prevents eye fatigue)
- **Text Secondary (`darkSubtext`):** `#7DD3FC` / `#94A3B8` (Metadata, muted labels)

### Light Mode Surfaces
- **Canvas / Background (`lightBg`):** `#F1F5F9` (Soft Slate Gray)
- **Primary Surface (`lightSurface`):** `#FFFFFF` (Pure Crisp White)
- **Card Surface (`lightCard`):** `#FFFFFF`
- **Hover Surface (`lightCardHover`):** `#F8FAFC`
- **Subtle Border (`lightBorder`):** `#E2E8F0` / `#CBD5E1`
- **Text Primary (`lightText`):** `#0F172A` (Deep Slate Charcoal, never pure #000000)
- **Text Secondary (`lightSubtext`):** `#64748B` (Secondary descriptions)

### Status & Feedback Tokens
- **Success:** `#16A34A` (Emerald / Stock In Norm / Paid)
- **Warning:** `#D97706` (Amber / Low Stock / Attention)
- **Danger / Error:** `#DC2626` (Ruby Red / Debt / Deletion / Write-off)
- **Info:** `#2563EB` (Cobalt / System Notices)

---

## 3. Typography System

We use a calibrated 3-tier font system:
1. **Space Grotesk** — Headings, Screen Titles, Hero KPI Figures (`w600`, `w700`).
2. **Inter** — General UI, Body Text, Buttons, Forms, Navigation (`w400`, `w500`, `w600`).
3. **JetBrains Mono** — SKU, Barcodes, Order Numbers, Prices, Receipt IDs (`w500`, `w600`).

| Role | Family | Size | Weight | Line-Height | Tracking | Usage |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Display / H1** | Space Grotesk | 26px | 700 (Bold) | 1.2 | -0.5px | Screen titles, Main balance |
| **H2 (Section)** | Space Grotesk | 20px | 700 (Bold) | 1.25 | -0.3px | Page headers, Modal titles |
| **H3 (Subheader)**| Inter | 16px | 600 (Semi) | 1.3 | -0.2px | Card headers, Table headers |
| **Body Default** | Inter | 14px | 400 (Regular)| 1.4 | 0.0px | Table content, form inputs |
| **Body Medium**  | Inter | 14px | 500 (Medium) | 1.4 | 0.0px | List items, Navigation |
| **Button Standard**| Inter | 13-14px | 600 (Semi) | 1.0 | 0.0px | All action buttons |
| **Caption / Small**| Inter | 12px | 400 (Regular)| 1.3 | 0.0px | Helper text, hints |
| **Micro / Badge** | Inter | 11px | 700 (Bold) | 1.0 | +0.4px | Status chips, uppercase tags |
| **Data Mono**     | JetBrains Mono | 13-15px | 500/600 | 1.2 | 0.0px | Prices, SKU, Check IDs |

---

## 4. Component Standards & Sizing Scale

### Buttons (`AppButtonSize`)
All buttons MUST strictly conform to the 5-tier size matrix:

| Size Enum | Height | Icon Size | Font Size | Horizontal Pad | Target Usage |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`AppButtonSize.xs`** | **28 px** | 14 px | 11 px | 8 px | Table row inline actions, micro tags |
| **`AppButtonSize.sm`** | **32 px** | 16 px | 12 px | 12 px | Sidebar buttons, compact filters |
| **`AppButtonSize.md`** | **36 px** | 16-18 px | 13-14 px | 14-16 px | **Standard Header Toolbar CTA (`+ Добавить`), Search toolbar actions** |
| **`AppButtonSize.lg`** | **44-48 px** | 18-20 px | 14-15 px | 20-24 px | **Standard Modal Actions (`Сохранить`, `Создать`), Login forms** |
| **`AppButtonSize.xl`** | **52 px** | 22 px | 16 px (Bold)| 28 px | **POS Touch Screen (`Оплатить`, `Новый заказ`)** |

### Button Variants
- **`AppPrimaryButton`:** Brand Primary background + Brand Glow shadow + White text/icon.
- **`AppSecondaryButton`:** Muted surface (`darkCard` / `lightSurface`) + 1px border + Neutral text.
- **`AppGhostButton`:** Transparent background + Neutral hover + Muted text (used for Cancel).
- **`AppDangerButton`:** Danger background/border + White text (used for Delete / Irreversible actions).
- **`AppMenuButton`:** Unified dropdown action button with built-in popup menu.

### Navigation & Selection Controls Matrix (4 Canonical Categories)

1. **Vertical List & Tree Tiles (`AppNavTileSize`):**
   - **`AppNavTileSize.sm` (32px):** Nested tree nodes, deep folder hierarchies.
   - **`AppNavTileSize.md` (38-40px):** Standard Warehouse Categories, Catalog Shelves, Recipe items.
   - **`AppNavTileSize.lg` (48-52px):** Main Sidebar Navigation Rail, Settings sections.

2. **Horizontal Exclusive Switchers (`AppSegmentedControl`):**
   - **`AppSegmentedSize.sm` (32px):** Compact switchers for forms, dialogs, sub-selectors (e.g. Bank choices).
   - **`AppSegmentedSize.md` (38px):** Header module switchers (e.g. POS `[Касса | Заказы | Кухня]`, Payment methods).
   - **`AppSegmentedSize.lg` (46-48px):** Primary touchscreen mode selectors.
   - **Track Background:** Must use `AppColors.darkTrackBg` / `AppColors.lightTrackBg` to avoid blending into white page headers.

3. **Data Filters & Lists (`AppFilterChip` & `AppFilterBar`):**
   - Squircle-shaped (`AppRadii.md` = 8px) horizontal scrollable chips with dynamic count badges, optional custom semantic colors (`activeColor`), and icon support.
   - Active state: soft 12–16% translucent accent background + 1.2px accent border. Never 100% solid fill (to avoid collision with primary CTA buttons).
   - **Size Scale (`AppFilterChipSize`):**
     - **`AppFilterChipSize.sm` (26px):** Compact sidebars (Recipe menu list, Category sub-filters), dense inspector panels.
     - **`AppFilterChipSize.md` (32px):** **Standard** for main page toolbars (CRM, Warehouse Documents, Shift analytics).
     - **`AppFilterChipSize.lg` (40px):** Touchscreen POS / Tablet mode.

4. **Order Context Chips (`AppOrderContextChip`):**
   - Compact order metadata tags (Table number, Customer name, Order mode) with dynamic theme colors and optional clear button `✕`.

5. **Search Fields (`AppSearchField`):**
   - Live, reactive search-as-you-type (no redundant "Search" submit buttons).
   - Built-in hotkey badge (`Ctrl+F` / `⌘K`) that automatically switches to clear button `✕` on input.
   - **Size Scale (`AppSearchFieldSize`):**
     - **`AppSearchFieldSize.sm` (32px):** Compact sidebars (Recipe menu list, Category tree).
     - **`AppSearchFieldSize.md` (36px):** Standard for main page toolbars (CRM, Warehouse Documents, Shift analytics, POS).
     - **`AppSearchFieldSize.lg` (44px):** Modal dialogs, Command Palette, Touchscreen POS.
   - **Display Modes (`AppSearchMode`):**
     - **`AppSearchMode.standard`:** Always visible field.
     - **`AppSearchMode.collapsible`:** Collapsed icon button `34×34px`, expands on tap or `Ctrl+F` with autofocus.

### Active State & Contrast Typography Law
- **Action Buttons & Segmented Active State (`AppPrimaryButton`, `AppSegmentedControl`):**
  - **Both Themes:** 100% Solid Brand Fill (`AppColors.brandPrimary`) + Pure White text/icon (`#FFFFFF`) + Glow.
  - **Light Theme Contrast Guarantee:** `AppColors.brandPrimary` is calibrated to have $\ge 4.5:1$ contrast ratio with white text across all color palettes (Ember, Cream, Ocean).
- **Navigation & Category Lists (`AppNavTile`):**
  - **Dark Mode:** Soft Brand Background (14% alpha) + 1px micro-border + **Pure Light White Text (`AppColors.darkText`)** + Brand Accent Icon. *(Guarantees WCAG AAA sharpness).*
  - **Light Mode:** Soft Brand Background (10% alpha) + 1px micro-border + **Vibrant Brand Text (`AppColors.brandPrimary`)** + Brand Accent Icon.

---

## 5. Layout & 8-Point Grid System

- **Spacing Token Scale:** `4, 8, 12, 16, 20, 24, 32, 40, 48, 64` px.
- **Screen Padding:** Desktop: `20px` or `24px`. Tablet/Mobile: `12px` or `16px`.
- **Gap between toolbar elements:** `8px` or `10px`.
- **Gap between cards:** `12px` or `16px`.

### Border Radii (`AppRadii`)
- **Pill / Badges:** `24 px` (`AppRadii.pill`)
- **Dialogs & Modals:** `20 px` (`AppRadii.dialog`)
- **Cards & Data Tables:** `14-16 px` (`AppRadii.card`)
- **Buttons & TextFields:** `8-10 px` (`AppRadii.button`, `AppRadii.inputRadius`)
- **Small Controls / Checkboxes:** `6 px` (`AppRadii.sm`)

---

## 6. Depth & Elevation

- **Card Elevation (Dark):** 1px subtle border (`#1E3250`) + Soft ambient shadow `rgba(0,0,0,0.35) blur: 16px`.
- **Button Glow:** `BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 14, offset: Offset(0, 3))`.
- **Modal Overlay:** Backdrop filter with `ImageFilter.blur(sigmaX: 8, sigmaY: 8)` + `Colors.black.withValues(alpha: 0.6)`.

---

## 7. Do's and Don'ts (Strict Guardrails)

### ❌ DO NOT:
- **DO NOT** use `ElevatedButton`, `TextButton`, or `OutlinedButton` directly in features.
- **DO NOT** write raw `Colors.white`, `Colors.black`, `Colors.blue`, or raw HEX `Color(0xFF...)` in widget trees.
- **DO NOT** create arbitrary button heights (e.g., `height: 38`, `height: 42`, `height: 50`).
- **DO NOT** hardcode fonts or `TextStyle(fontSize: 22, fontWeight: FontWeight.bold)`. Use `AppTextStyles.*`.
- **DO NOT** let files grow over 250 lines.

### ✅ DO:
- **ALWAYS** use `AppPrimaryButton`, `AppSecondaryButton`, `AppGhostButton`, `AppMenuButton`.
- **ALWAYS** use `AppColors.*` tokens for all styling and borders.
- **ALWAYS** use `AppButtonSize.md` (36px) for toolbar/header actions and `AppButtonSize.lg` (44-48px) for modals.
- **ALWAYS** wrap modal dialogs in `AppDialog` with `AppRadii.dialog`.
- **ALWAYS** support both Dark and Light themes with dynamic contrast.

---

## 8. Agent Prompt & Implementation Guide
When implementing or modifying any UI in Kreso Flow:
1. Reference this `DESIGN.md` as the ultimate visual source of truth.
2. Ensure zero `flutter analyze` errors and zero deprecation warnings.
3. Keep widgets modular, decoupled, and cleanly composed inside `lib/features/<feature>/view/widgets/`.
