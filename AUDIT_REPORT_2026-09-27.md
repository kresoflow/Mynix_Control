# Отчёт сбора фактов — 2026-09-27 12:33:01

## 1. Сырой вывод команд (Шаг 1)

### `python scripts/verify_rules.py`
```
==================================================
        KRESO FLOW — ARCHITECTURAL LINTER         
==================================================

--- RESULTS ---

[!] WARNINGS (118):
  ⚠ [PBAC DEBT] backend/app/system/routers/tenant_router.py defines routes but lacks require_permission / require_any_permission guards.
  ⚠ [FILE-LIMIT] backend/app/pos/models.py has 300 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] backend/app/users/seed.py has 262 lines (exceeds recommended target of 250 lines).
  ⚠ [LEGACY-LIMIT-DEBT] backend/app/inventory/services/category_service.py has 306 lines (exceeds 300, tracked for modular refactoring).
  ⚠ [FILE-LIMIT] backend/app/inventory/services/menu_service.py has 282 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] backend/app/pos/routers/checkout_router.py has 283 lines (exceeds recommended target of 250 lines).
  ⚠ [LEGACY-LIMIT-DEBT] backend/app/pos/services/checkout_service.py has 405 lines (exceeds 300, tracked for modular refactoring).
  ⚠ [LEGACY-LIMIT-DEBT] backend/app/pos/services/order_table_service.py has 407 lines (exceeds 300, tracked for modular refactoring).
  ⚠ [FILE-LIMIT] backend/app/pos/services/shift_service.py has 344 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] backend/app/system/routers/tenant_router.py has 260 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] frontend/lib/features/analytics/view/tabs/shift_history_analytics_tab.dart has 273 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] frontend/lib/features/analytics/view/widgets/analytics_filter_bar.dart has 275 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] frontend/lib/features/analytics/view/widgets/dialogs/shift_history_details_dialog.dart has 284 lines (exceeds recommended target of 250 lines).
  ⚠ [LEGACY-LIMIT-DEBT] frontend/lib/features/auth/view/login_screen.dart has 340 lines (exceeds 300, tracked for modular refactoring).
  ⚠ [FILE-LIMIT] frontend/lib/features/crm/view/crm_screen.dart has 258 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] frontend/lib/features/crm/view/widgets/dialogs/bonus_adjustment_modal.dart has 288 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] frontend/lib/features/crm/view/widgets/dialogs/customer_details_dialog.dart has 262 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] frontend/lib/features/crm/view/widgets/dialogs/customer_form_modal.dart has 293 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] frontend/lib/features/crm/view/widgets/dialogs/customer_payment_modal.dart has 274 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] frontend/lib/features/gift_cards/view/widgets/issue_gift_card_dialog.dart has 254 lines (exceeds recommended target of 250 lines).
  ... and 98 more warnings.

✔ NO CRITICAL ARCHITECTURAL ERRORS FOUND.
```

### `python scripts/verify_rules.py --strict`
```
==================================================
        KRESO FLOW — ARCHITECTURAL LINTER         
==================================================

--- RESULTS ---

[!] WARNINGS (102):
  ⚠ [PBAC DEBT] backend/app/system/routers/tenant_router.py defines routes but lacks require_permission / require_any_permission guards.
  ⚠ [FILE-LIMIT] backend/app/pos/models.py has 300 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] backend/app/users/seed.py has 262 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] backend/app/inventory/services/menu_service.py has 282 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] backend/app/pos/routers/checkout_router.py has 283 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] backend/app/pos/services/shift_service.py has 344 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] backend/app/system/routers/tenant_router.py has 260 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] frontend/lib/features/analytics/view/tabs/shift_history_analytics_tab.dart has 273 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] frontend/lib/features/analytics/view/widgets/analytics_filter_bar.dart has 275 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] frontend/lib/features/analytics/view/widgets/dialogs/shift_history_details_dialog.dart has 284 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] frontend/lib/features/crm/view/crm_screen.dart has 258 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] frontend/lib/features/crm/view/widgets/dialogs/bonus_adjustment_modal.dart has 288 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] frontend/lib/features/crm/view/widgets/dialogs/customer_details_dialog.dart has 262 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] frontend/lib/features/crm/view/widgets/dialogs/customer_form_modal.dart has 293 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] frontend/lib/features/crm/view/widgets/dialogs/customer_payment_modal.dart has 274 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] frontend/lib/features/gift_cards/view/widgets/issue_gift_card_dialog.dart has 254 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] frontend/lib/features/inventory/bloc/document_bloc.dart has 280 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] frontend/lib/features/inventory/view/widgets/bulk_receipt_view.dart has 273 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] frontend/lib/features/inventory/view/widgets/warehouse/documents_journal_tab.dart has 270 lines (exceeds recommended target of 250 lines).
  ⚠ [FILE-LIMIT] frontend/lib/features/inventory/view/widgets/warehouse/suppliers_tab.dart has 278 lines (exceeds recommended target of 250 lines).
  ... and 82 more warnings.

[X] CRITICAL ERRORS (172):
  ✖ [FILE-LIMIT] backend/app/inventory/services/category_service.py has 306 lines (exceeds hard ceiling of 300 lines).
  ✖ [FILE-LIMIT] backend/app/pos/services/checkout_service.py has 405 lines (exceeds hard ceiling of 300 lines).
  ✖ [FILE-LIMIT] backend/app/pos/services/order_table_service.py has 407 lines (exceeds hard ceiling of 300 lines).
  ✖ [FILE-LIMIT] frontend/lib/features/auth/view/login_screen.dart has 340 lines (exceeds hard ceiling of 300 lines).
  ✖ [FILE-LIMIT] frontend/lib/features/inventory/view/widgets/menu_item_modal.dart has 316 lines (exceeds hard ceiling of 300 lines).
  ✖ [FILE-LIMIT] frontend/lib/features/inventory/view/widgets/warehouse/stock_tab.dart has 418 lines (exceeds hard ceiling of 300 lines).
  ✖ [FILE-LIMIT] frontend/lib/features/menu/view/widgets/catalog/catalog_browser_tab.dart has 343 lines (exceeds hard ceiling of 300 lines).
  ✖ [FILE-LIMIT] frontend/lib/features/menu/view/widgets/catalog/ingredient_tab.dart has 472 lines (exceeds hard ceiling of 300 lines).
  ✖ [FILE-LIMIT] frontend/lib/features/menu/view/widgets/catalog/dialogs/create_ingredient_dialog.dart has 362 lines (exceeds hard ceiling of 300 lines).
  ✖ [FILE-LIMIT] frontend/lib/features/menu/view/widgets/catalog/dialogs/create_retail_product_dialog.dart has 430 lines (exceeds hard ceiling of 300 lines).
  ✖ [FILE-LIMIT] frontend/lib/features/menu/view/widgets/catalog/ingredient/ingredient_grid_view.dart has 375 lines (exceeds hard ceiling of 300 lines).
  ✖ [FILE-LIMIT] frontend/lib/features/menu/view/widgets/catalog/recipe/recipe_empty_dashboard.dart has 357 lines (exceeds hard ceiling of 300 lines).
  ✖ [FILE-LIMIT] frontend/lib/features/pos/view/pos_screen.dart has 418 lines (exceeds hard ceiling of 300 lines).
  ✖ [FILE-LIMIT] frontend/lib/features/pos/view/widgets/tables/pos_active_table_card.dart has 322 lines (exceeds hard ceiling of 300 lines).
  ✖ [DESIGN-SYSTEM] frontend/lib/core/utils/role_formatter.dart has 7 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/core/widgets/app_button.dart has 5 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/core/widgets/app_card.dart has 6 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/core/widgets/app_dialog.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/core/widgets/app_dialog_scaffold.dart has 5 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/core/widgets/app_segmented_tab.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/core/widgets/app_text_field.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/core/widgets/app_toast.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/core/widgets/date_time_picker_calendar.dart has 5 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/core/widgets/date_time_picker_time_row.dart has 3 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/core/widgets/skeleton_loader.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/core/widgets/main_layout/icon_btn.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/analytics/view/tabs/order_history_tab.dart has 4 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/analytics/view/widgets/analytics_filter_bar.dart has 4 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/analytics/view/widgets/analytics_shift_row.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/analytics/view/widgets/category_pie_chart_card.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/analytics/view/widgets/dashboard_metric_card.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/analytics/view/widgets/low_stock_alerts_widget.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/analytics/view/widgets/recent_orders_widget.dart has 5 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/analytics/view/widgets/revenue_share_widget.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/analytics/view/widgets/top_items_widget.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/auth/view/login_screen.dart has 5 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/auth/view/widgets/pin_keypad.dart has 3 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/crm/view/widgets/customer_balance_badge.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/crm/view/widgets/customer_kpi_cards.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/crm/view/widgets/customer_mobile_card.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/crm/view/widgets/dialogs/bonus_adjustment_modal.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/crm/view/widgets/dialogs/customer_bonus_tab.dart has 6 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/crm/view/widgets/dialogs/customer_details_dialog.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/crm/view/widgets/dialogs/customer_ledger_tab.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/crm/view/widgets/dialogs/customer_orders_tab.dart has 3 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/crm/view/widgets/dialogs/customer_statement_pdf_service.dart has 4 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/hub/view/hub_screen.dart has 7 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/receive_retail_screen.dart has 3 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/bulk_receipt_view.dart has 5 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/menu_manager_breadcrumbs.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/menu_manager_categories_list.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/menu_manager_items_grid.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/receive_retail_item_widget.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/retail_product_modal.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/bulk_add/bulk_add_row_item.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/retail/retail_variations_editor.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/documents_journal_tab.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/stock_tab.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/write_off_dialog.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/write_off_tab.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/dialogs/create_supplier_dialog.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/dialogs/edit_supplier_dialog.dart has 3 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/dialogs/quick_stock_action_dialog.dart has 3 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/documents/document_journal_row.dart has 5 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/ingredient/ingredient_list_widget.dart has 6 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/ingredient/ingredient_quick_setup_card.dart has 3 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/stock/hoverable_metric_card.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/stock/hoverable_stock_item.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/stock/stock_capital_chart_card.dart has 5 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/stock/stock_category_accordion.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/stock/stock_category_header.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/stock/stock_item_row.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/stock/stock_low_inventory_widget.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/stock/stock_metrics_header.dart has 9 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/stock/stock_subcategory_header.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/dialogs/document_detail/document_detail_dialog.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/dialogs/document_detail/document_detail_footer.dart has 3 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/dialogs/document_detail/document_detail_header.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/dialogs/document_detail/document_detail_items_table.dart has 9 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/dialogs/document_detail/document_detail_payment_info.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/dialogs/recipe_bulk_edit/recipe_bulk_edit_row_widget.dart has 6 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/dialogs/recipe_bulk_edit/recipe_ingredient_picker.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/dialogs/supplier_settlement/supplier_payment_modal.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/menu/view/widgets/catalog/catalog_skeleton.dart has 11 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/menu/view/widgets/catalog/ingredient_tab.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/menu/view/widgets/catalog/dialogs/duplicate_warning_chip.dart has 6 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/menu/view/widgets/catalog/dialogs/recipe_bulk_edit_dialog.dart has 4 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/menu/view/widgets/catalog/ingredient/ingredient_category_sidebar.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/menu/view/widgets/catalog/ingredient/ingredient_grid_view.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/menu/view/widgets/catalog/ingredient/ingredient_item_row.dart has 5 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/menu/view/widgets/catalog/ingredient/ingredient_mini_kpi_bar.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/menu/view/widgets/catalog/ingredient/ingredient_table_view.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/menu/view/widgets/catalog/items/category_grid_item.dart has 4 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/menu/view/widgets/catalog/items/category_list_item.dart has 5 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/menu/view/widgets/catalog/items/menu_grid_item.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/menu/view/widgets/catalog/items/menu_list_item.dart has 3 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/menu/view/widgets/catalog/recipe/recipe_analytics_header.dart has 3 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/menu/view/widgets/catalog/recipe/recipe_ingredient_item_tile.dart has 3 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/menu/view/widgets/catalog/dialogs/recipe_bulk_edit/ingredient_picker_dialog.dart has 5 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/menu/view/widgets/catalog/dialogs/recipe_bulk_edit/recipe_bulk_edit_row.dart has 4 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/orders/view/widgets/orders_skeleton.dart has 10 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/orders/view/widgets/order_card.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/orders/view/widgets/order_details_dialog.dart has 4 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/open_shift_modal.dart has 7 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/pos_menu_grid.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/pos_mobile_layout.dart has 7 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/pos_settings_modal.dart has 6 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/pos_shift_hub_modal.dart has 3 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/table_picker_modal.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/components/customer_picker_tile.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/components/pos_cart_item_tile.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/components/pos_category_card.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/components/pos_checkout_panel.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/components/pos_checkout_panel_action_button.dart has 12 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/components/pos_empty_cart.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/components/pos_item_card.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/dialogs/incoming_order_card.dart has 6 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/dialogs/incoming_order_payment_modal.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/dialogs/sync_outbox_dialog.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/modifiers/dialog_modifier_groups_list.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/tables/pos_active_tables_dialog.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/tables/pos_active_table_card.dart has 5 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/tables/split_bill_dialog.dart has 3 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/settings/view/widgets/settings_components.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/settings/view/widgets/settings_dialogs.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/settings/view/widgets/settings_ui_components.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/settings/view/widgets/theme_appearance_settings_card.dart has 5 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/superadmin/view/superadmin_screen.dart has 1 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/superadmin/view/widgets/edit_tenant_modal.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/superadmin/view/widgets/tenant_card.dart has 2 raw Colors (use AppColors.*)
  ✖ [DESIGN-SYSTEM] frontend/lib/core/widgets/profile/user_profile_modal.dart has 1 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/analytics/view/tabs/shift_history_analytics_tab.dart has 1 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/auth/view/login_screen.dart has 2 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/crm/view/widgets/dialogs/bonus_adjustment_modal.dart has 2 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/crm/view/widgets/dialogs/customer_bonus_tab.dart has 2 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/crm/view/widgets/dialogs/customer_ledger_tab.dart has 4 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/receive_retail_screen.dart has 2 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/menu_manager_breadcrumbs.dart has 3 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/menu_manager_categories_list.dart has 2 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/menu_manager_tab.dart has 4 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/retail_product_modal.dart has 3 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/menu_item/menu_item_modifier_groups_section.dart has 2 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/menu_item/menu_item_variations_section.dart has 1 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/retail/retail_category_selector.dart has 2 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/retail/retail_variations_editor.dart has 1 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/add_category_dialog.dart has 2 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/add_ingredient_dialog.dart has 2 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/receive_stock_dialog.dart has 2 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/stock_tab.dart has 1 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/write_off_dialog.dart has 3 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/write_off_tab.dart has 2 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/dialogs/create_supplier_dialog.dart has 4 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/dialogs/edit_supplier_dialog.dart has 4 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/dialogs/quick_stock_action_dialog.dart has 3 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/ingredient/ingredient_quick_setup_card.dart has 2 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/inventory/view/widgets/warehouse/dialogs/supplier_settlement/supplier_settlement_dialog.dart has 3 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/menu/view/widgets/catalog/recipe_details_panel.dart has 2 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/menu/view/widgets/catalog/dialogs/add_ingredient_to_recipe_dialog.dart has 2 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/menu/view/widgets/catalog/dialogs/create_retail_product_form.dart has 2 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/menu/view/widgets/catalog/dialogs/recipe_bulk_edit_dialog.dart has 3 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/menu/view/widgets/catalog/ingredient/ingredient_category_sidebar.dart has 7 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/customer_picker_modal.dart has 1 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/open_shift_modal.dart has 2 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/pos_menu_grid.dart has 1 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/pos_mobile_layout.dart has 2 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/table_picker_modal.dart has 4 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/dialogs/incoming_order_card.dart has 6 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/modifiers/dialog_mini_cart_view.dart has 2 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/shift_hub/shift_history_tab.dart has 1 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/tables/pos_active_table_card.dart has 6 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/pos/view/widgets/tables/split_bill_dialog.dart has 2 raw buttons (use AppPrimaryButton / AppSecondaryButton)
  ✖ [DESIGN-SYSTEM] frontend/lib/features/settings/view/widgets/settings_dialogs.dart has 3 raw buttons (use AppPrimaryButton / AppSecondaryButton)

FAILED: Fix critical errors to maintain architectural integrity.
```

### `pytest backend/tests/ -v 2>&1 | tail -100`
```
backend\tests\test_analytics.py::test_format_selected_options_modifiers_strings PASSED [ 10%]
backend\tests\test_analytics.py::test_format_selected_options_combined PASSED [ 11%]
backend\tests\test_analytics.py::test_analytics_endpoints_and_permissions PASSED [ 12%]
backend\tests\test_bulk_endpoints.py::test_bulk_create_menu_items_pbac_and_variations PASSED [ 12%]
backend\tests\test_bulk_endpoints.py::test_bulk_create_retail_products_prohibits_phantom_stock PASSED [ 13%]
backend\tests\test_bulk_endpoints.py::test_bulk_create_ingredients_prohibits_phantom_stock PASSED [ 14%]
backend\tests\test_bulk_endpoints.py::test_single_catalog_card_creation_prohibits_phantom_stock PASSED [ 15%]
backend\tests\test_bulk_endpoints.py::test_document_completion_rejects_bogus_item_ids PASSED [ 16%]
backend\tests\test_bulk_endpoints.py::test_bulk_delete_menu_items_and_categories_smart_purge PASSED [ 17%]
backend\tests\test_cash_operations.py::test_cash_operation_deposit_and_withdrawal_flow PASSED [ 18%]
backend\tests\test_cash_operations.py::test_cash_operation_insufficient_funds PASSED [ 19%]
backend\tests\test_cash_operations.py::test_cash_operation_closed_shift PASSED [ 20%]
backend\tests\test_cash_operations.py::test_cash_operation_pbac_permissions PASSED [ 21%]
backend\tests\test_cash_operations.py::test_cross_tenant_cash_operation_isolation PASSED [ 22%]
backend\tests\test_crm_and_ledger.py::test_crm_customer_loyalty_debt_and_payment PASSED [ 23%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_bulk_dishes_happy_path PASSED [ 24%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_bulk_dishes_with_variations PASSED [ 25%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_bulk_dishes_attributes_and_tags PASSED [ 25%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_bulk_dishes_category_association PASSED [ 26%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_bulk_dishes_description_and_availability PASSED [ 27%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_bulk_retail_happy_path PASSED [ 28%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_bulk_retail_units PASSED [ 29%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_bulk_retail_barcodes PASSED [ 30%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_bulk_retail_cost_and_price PASSED [ 31%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_bulk_retail_zero_initial_stock PASSED [ 32%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_bulk_ingredients_happy_path PASSED [ 33%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_bulk_ingredients_measurement_units PASSED [ 34%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_bulk_ingredients_min_stock_alert PASSED [ 35%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_bulk_ingredients_barcodes PASSED [ 36%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_bulk_ingredients_zero_initial_stock PASSED [ 37%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_bulk_categories_happy_path PASSED [ 37%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_bulk_categories_hierarchy PASSED [ 38%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_bulk_categories_types PASSED [ 39%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_bulk_categories_ordering_and_colors PASSED [ 40%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_bulk_categories_visibility_flags PASSED [ 41%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_goods_receipt_creation_multi_item PASSED [ 42%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_goods_receipt_completion_status_transition PASSED [ 43%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_goods_receipt_unpaid_supplier_debt PASSED [ 44%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_goods_receipt_paid_supplier_neutral PASSED [ 45%]
backend\tests\test_e2e_requirements.py::TestTier1FeatureCoverage::test_goods_receipt_stock_transaction_logged PASSED [ 46%]
backend\tests\test_e2e_requirements.py::TestTier2BoundaryCornerCases::test_empty_batch_dishes PASSED [ 47%]
backend\tests\test_e2e_requirements.py::TestTier2BoundaryCornerCases::test_empty_batch_retail PASSED [ 48%]
backend\tests\test_e2e_requirements.py::TestTier2BoundaryCornerCases::test_empty_batch_ingredients PASSED [ 49%]
backend\tests\test_e2e_requirements.py::TestTier2BoundaryCornerCases::test_empty_batch_categories PASSED [ 50%]
backend\tests\test_e2e_requirements.py::TestTier2BoundaryCornerCases::test_large_batch_50_plus_items PASSED [ 50%]
backend\tests\test_e2e_requirements.py::TestTier2BoundaryCornerCases::test_special_characters_and_quotes PASSED [ 51%]
backend\tests\test_e2e_requirements.py::TestTier2BoundaryCornerCases::test_zero_and_fractional_pricing PASSED [ 52%]
backend\tests\test_e2e_requirements.py::TestTier2BoundaryCornerCases::test_duplicate_barcodes_behavior PASSED [ 53%]
backend\tests\test_e2e_requirements.py::TestTier2BoundaryCornerCases::test_goods_receipt_invalid_item_id_rejection PASSED [ 54%]
backend\tests\test_e2e_requirements.py::TestTier3CombinatorialCrossFeature::test_catalog_creation_never_increments_stock PASSED [ 55%]
backend\tests\test_e2e_requirements.py::TestTier3CombinatorialCrossFeature::test_bulk_nomenclature_to_goods_receipt_stock_sync PASSED [ 56%]
backend\tests\test_e2e_requirements.py::TestTier3CombinatorialCrossFeature::test_moving_average_cost_recalculation PASSED [ 57%]
backend\tests\test_e2e_requirements.py::TestTier3CombinatorialCrossFeature::test_partial_payment_supplier_debt_and_stock PASSED [ 58%]
backend\tests\test_e2e_requirements.py::TestTier3CombinatorialCrossFeature::test_goods_receipt_followed_by_writeoff PASSED [ 59%]
backend\tests\test_e2e_requirements.py::TestTier4RealWorldWorkflows::test_workflow_restaurant_opening_inventory_setup PASSED [ 60%]
backend\tests\test_e2e_requirements.py::TestTier4RealWorldWorkflows::test_workflow_supplier_delivery_invoice_processing PASSED [ 61%]
backend\tests\test_gift_cards.py::test_cross_tenant_gift_card_isolation PASSED [ 62%]
backend\tests\test_gift_cards.py::test_gift_cards_lifecycle_and_invariants PASSED [ 62%]
backend\tests\test_gift_cards.py::test_gift_card_pbac_permissions PASSED [ 63%]
backend\tests\test_gift_cards.py::test_gift_card_validation_errors PASSED [ 64%]
backend\tests\test_hall_orders_and_approval.py::test_hall_orders_approval_and_deferred_deduction PASSED [ 65%]
backend\tests\test_inventory_deduction.py::test_dish_recipe_auto_deduction PASSED [ 66%]
backend\tests\test_inventory_deduction.py::test_retail_product_auto_deduction PASSED [ 67%]
backend\tests\test_inventory_deduction.py::test_disabled_inventory_deduction_flag PASSED [ 68%]
backend\tests\test_inventory_deduction.py::test_get_recipes_summary PASSED [ 69%]
backend\tests\test_inventory_deduction.py::test_dish_variation_independent_recipe_deduction PASSED [ 70%]
backend\tests\test_m1_adversarial.py::test_menu_bulk_atomic_rollback_on_pydantic_validation_failure PASSED [ 71%]
backend\tests\test_m1_adversarial.py::test_retail_bulk_atomic_rollback_on_pydantic_validation_failure PASSED [ 72%]
backend\tests\test_m1_adversarial.py::test_ingredients_bulk_atomic_rollback_on_pydantic_validation_failure PASSED [ 73%]
backend\tests\test_m1_adversarial.py::test_menu_bulk_atomic_rollback_on_midway_service_failure PASSED [ 74%]
backend\tests\test_m1_adversarial.py::test_menu_bulk_dish_variations_multiple_options_and_prices PASSED [ 75%]
backend\tests\test_m1_adversarial.py::test_menu_variations_update_lifecycle PASSED [ 75%]
backend\tests\test_m1_adversarial.py::test_bulk_endpoints_reject_unauthenticated PASSED [ 76%]
backend\tests\test_m1_adversarial.py::test_bulk_endpoints_reject_insufficient_permissions PASSED [ 77%]
backend\tests\test_m1_adversarial.py::test_bulk_endpoints_fine_grained_pbac_separation PASSED [ 78%]
backend\tests\test_main.py::test_health_check PASSED                     [ 79%]
backend\tests\test_main.py::test_root PASSED                             [ 80%]
backend\tests\test_multitenancy_and_idor.py::test_cross_tenant_idor_isolation PASSED [ 81%]
backend\tests\test_poka_yoke_guards.py::test_cannot_close_shift_with_active_orders PASSED [ 82%]
backend\tests\test_poka_yoke_guards.py::test_self_deletion_and_last_owner_deletion_blocked PASSED [ 83%]
backend\tests\test_poka_yoke_guards.py::test_ingredient_deletion_ledger_guard PASSED [ 84%]
backend\tests\test_poka_yoke_guards.py::test_kitchen_kds_mark_ready_and_undo PASSED [ 85%]
backend\tests\test_poka_yoke_guards.py::test_pin_bruteforce_protection PASSED [ 86%]
backend\tests\test_poka_yoke_guards.py::test_analytics_date_guards PASSED [ 87%]
backend\tests\test_poka_yoke_guards.py::test_category_circular_dependency_guard PASSED [ 87%]
backend\tests\test_poka_yoke_guards.py::test_numerical_range_guards PASSED [ 88%]
backend\tests\test_poka_yoke_guards.py::test_two_stage_menu_item_and_category_deletion PASSED [ 89%]
backend\tests\test_poka_yoke_guards.py::test_restore_duplicate_collision_guards PASSED [ 90%]
backend\tests\test_pos_offline_idempotency.py::test_pos_checkout_idempotency_and_offline_client_uuid PASSED [ 91%]
backend\tests\test_pos_shifts.py::test_pos_shift_lifecycle_x_and_z_reports PASSED [ 92%]
backend\tests\test_retail_variations.py::test_retail_multi_variations_creation_and_stock PASSED [ 93%]
backend\tests\test_supplier_debt_and_documents.py::test_supplier_debt_lifecycle_and_payments PASSED [ 94%]
backend\tests\test_system_security.py::test_superadmin_brute_force_protection PASSED [ 95%]
backend\tests\test_system_security.py::test_superadmin_valid_token_success PASSED [ 96%]
backend\tests\test_system_security.py::test_schema_name_validation PASSED [ 97%]
backend\tests\test_system_security.py::test_tenant_full_update_and_owner_management PASSED [ 98%]
backend\tests\test_users.py::test_user_creation_and_login PASSED         [ 99%]
backend\tests\test_users.py::test_pin_login PASSED                       [100%]

============================ 108 passed in 26.89s =============================
```

### `flutter analyze frontend/ 2>&1 | tail -100`
```
   info - Missing a required trailing comma - frontend\lib\features\analytics\view\widgets\xray_table_card.dart:129:18 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\analytics\view\widgets\xray_table_card.dart:134:18 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\auth\bloc\auth_bloc.dart:72:6 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\auth\view\widgets\pin_keypad.dart:68:23 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\crm\bloc\crm_bloc.dart:67:8 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\crm\bloc\crm_bloc.dart:150:8 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\crm\bloc\crm_bloc.dart:198:8 - require_trailing_commas
   info - 'value' is deprecated and shouldn't be used. Use initialValue instead. This will set the initial value for the form field. This feature was deprecated after v3.33.0-1.0.pre - frontend\lib\features\crm\view\widgets\dialogs\bonus_adjustment_modal.dart:195:15 - deprecated_member_use
warning - The declaration 'disposeWidget' isn't referenced - frontend\lib\features\crm\view\widgets\dialogs\bonus_adjustment_modal.dart:285:8 - unused_element
   info - Missing a required trailing comma - frontend\lib\features\crm\view\widgets\dialogs\customer_statement_pdf_service.dart:71:113 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\inventory\bloc\document_bloc.dart:64:8 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\inventory\bloc\document_bloc.dart:81:8 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\inventory\bloc\document_bloc.dart:103:8 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\inventory\bloc\document_bloc.dart:124:8 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\inventory\bloc\document_bloc.dart:207:8 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\inventory\bloc\document_bloc.dart:232:8 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\inventory\bloc\document_bloc.dart:257:8 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\inventory\bloc\document_bloc.dart:275:8 - require_trailing_commas
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\inventory\bloc\ingredient_bloc.dart:48:13 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\inventory\bloc\ingredient_bloc.dart:59:11 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\inventory\bloc\ingredient_bloc.dart:62:11 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\inventory\bloc\ingredient_bloc.dart:105:11 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\inventory\bloc\ingredient_bloc.dart:108:11 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\inventory\bloc\ingredient_bloc.dart:123:11 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\inventory\bloc\ingredient_bloc.dart:126:11 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\inventory\bloc\ingredient_bloc.dart:136:11 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\inventory\bloc\ingredient_bloc.dart:139:11 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\inventory\bloc\ingredient_bloc.dart:149:11 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\inventory\bloc\ingredient_bloc.dart:152:11 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\inventory\bloc\ingredient_bloc.dart:162:11 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\inventory\bloc\ingredient_bloc.dart:165:11 - prefer_const_constructors
   info - Missing a required trailing comma - frontend\lib\features\inventory\bloc\recipe_bloc.dart:73:10 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\inventory\bloc\recipe_bloc.dart:79:10 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\inventory\bloc\recipe_bloc.dart:97:8 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\inventory\repository\parts\documents_part.dart:8:8 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\inventory\services\export\document_text_builder.dart:82:8 - require_trailing_commas
   info - 'dart:html' is deprecated and shouldn't be used. Use package:web and dart:js_interop instead - frontend\lib\features\inventory\services\export_helper_web.dart:2:1 - deprecated_member_use
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\inventory\view\warehouse_screen.dart:32:42 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\inventory\view\widgets\bulk_add\bulk_add_row_item.dart:209:35 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\inventory\view\widgets\bulk_add\bulk_add_row_item.dart:226:25 - prefer_const_constructors
   info - Missing a required trailing comma - frontend\lib\features\inventory\view\widgets\bulk_add\bulk_add_save_helper.dart:100:20 - require_trailing_commas
   info - Angle brackets will be interpreted as HTML - frontend\lib\features\inventory\view\widgets\warehouse\dialogs\edit_supplier_dialog.dart:7:19 - unintended_html_in_doc_comment
   info - Missing a required trailing comma - frontend\lib\features\inventory\view\widgets\warehouse\dialogs\edit_supplier_dialog.dart:85:95 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\inventory\view\widgets\warehouse\dialogs\edit_supplier_dialog.dart:99:60 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\inventory\view\widgets\warehouse\dialogs\edit_supplier_dialog.dart:121:60 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\inventory\view\widgets\warehouse\dialogs\edit_supplier_dialog.dart:147:95 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\inventory\view\widgets\warehouse\dialogs\edit_supplier_dialog.dart:150:97 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\inventory\view\widgets\warehouse\dialogs\quick_stock_action_dialog.dart:74:7 - require_trailing_commas
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\inventory\view\widgets\warehouse\dialogs\quick_stock_action_dialog.dart:80:44 - prefer_const_constructors
   info - Missing a required trailing comma - frontend\lib\features\inventory\view\widgets\warehouse\dialogs\recipe_bulk_edit\recipe_ingredient_picker.dart:36:15 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\inventory\view\widgets\warehouse\dialogs\recipe_bulk_edit\recipe_ingredient_picker.dart:56:22 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\inventory\view\widgets\warehouse\dialogs\recipe_bulk_edit\recipe_row_state.dart:10:58 - require_trailing_commas
   info - Don't use 'BuildContext's across async gaps, guarded by an unrelated 'mounted' check - frontend\lib\features\inventory\view\widgets\warehouse\dialogs\supplier_settlement\supplier_settlement_dialog.dart:62:7 - use_build_context_synchronously
   info - Don't use 'BuildContext's across async gaps, guarded by an unrelated 'mounted' check - frontend\lib\features\inventory\view\widgets\warehouse\dialogs\supplier_settlement\supplier_settlement_dialog.dart:81:7 - use_build_context_synchronously
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\inventory\view\widgets\warehouse\dialogs\supplier_settlement\supplier_settlement_row.dart:128:21 - prefer_const_constructors
   info - Missing a required trailing comma - frontend\lib\features\inventory\view\widgets\warehouse\stock\stock_category_accordion.dart:58:15 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\inventory\view\widgets\warehouse\stock\stock_category_header.dart:58:15 - require_trailing_commas
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\inventory\view\widgets\warehouse\supplier_row.dart:198:29 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\inventory\view\widgets\warehouse\supplier_row.dart:223:13 - prefer_const_constructors
   info - Missing a required trailing comma - frontend\lib\features\kitchen\view\widgets\kds\kds_item_row.dart:38:7 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\orders\view\orders_screen.dart:54:15 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\pos\bloc\cart_bloc.dart:190:6 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\pos\bloc\cart_bloc.dart:201:6 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\pos\bloc\cart_bloc.dart:208:5 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\pos\bloc\cart_bloc.dart:224:7 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\pos\bloc\cart_bloc.dart:275:8 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\pos\bloc\cart_bloc.dart:294:6 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\pos\bloc\cart_bloc.dart:313:6 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\pos\bloc\pos_settings_cubit.dart:43:4 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\pos\bloc\pos_settings_cubit.dart:60:8 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\pos\services\lan\local_pos_client.dart:9:4 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\pos\services\lan\local_pos_server.dart:87:13 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\pos\services\lan\local_pos_server.dart:111:13 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\pos\services\pos_sync_service.dart:55:14 - require_trailing_commas
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\pos\view\widgets\customer_picker_modal.dart:167:30 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\pos\view\widgets\customer_picker_modal.dart:170:27 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\pos\view\widgets\customer_picker_modal.dart:172:27 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\pos\view\widgets\customer_picker_modal.dart:172:66 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\pos\view\widgets\dialogs\sync_outbox_dialog.dart:198:27 - prefer_const_constructors
   info - Missing a required trailing comma - frontend\lib\features\pos\view\widgets\helpers\pos_item_click_handler.dart:68:6 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\pos\view\widgets\helpers\pos_item_click_handler.dart:80:12 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\pos\view\widgets\menu_modifiers_dialog.dart:54:10 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\pos\view\widgets\menu_modifiers_dialog.dart:121:10 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\pos\view\widgets\open_shift_modal.dart:162:21 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\pos\view\widgets\pos_mobile_layout.dart:58:33 - require_trailing_commas
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\pos\view\widgets\tables\pos_active_table_card.dart:190:25 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\pos\view\widgets\tables\pos_active_table_card.dart:192:29 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\pos\view\widgets\tables\pos_active_table_card.dart:194:29 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\pos\view\widgets\tables\pos_active_table_card.dart:196:38 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\pos\view\widgets\tables\pos_active_table_card.dart:255:25 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\pos\view\widgets\tables\pos_active_table_card.dart:256:26 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\pos\view\widgets\tables\pos_active_table_card.dart:256:47 - prefer_const_constructors
   info - Missing a required trailing comma - frontend\lib\features\settings\repository\user_repository.dart:29:6 - require_trailing_commas
   info - Missing a required trailing comma - frontend\lib\features\settings\view\widgets\settings_dialogs.dart:45:46 - require_trailing_commas
   info - Use 'const' with the constructor to improve performance - frontend\lib\features\settings\view\widgets\showcase\showcase_dialog_section.dart:43:11 - prefer_const_constructors
   info - The imported package 'flutter_web_plugins' isn't a dependency of the importing package - frontend\lib\main.dart:46:8 - depend_on_referenced_packages
   info - Use 'const' with the constructor to improve performance - frontend\lib\main.dart:229:52 - prefer_const_constructors
warning - Unused import: 'package:flutter/material.dart' - frontend\test\cash_operation_test.dart:1:8 - unused_import

111 issues found. (ran in 147.4s)
```

### `dart analyze frontend/lib/ 2>&1 | tail -100`
```
   info - features\analytics\view\widgets\xray_table_card.dart:115:18 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\analytics\view\widgets\xray_table_card.dart:121:18 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\analytics\view\widgets\xray_table_card.dart:129:18 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\analytics\view\widgets\xray_table_card.dart:134:18 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\auth\bloc\auth_bloc.dart:72:6 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\auth\view\widgets\pin_keypad.dart:68:23 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\crm\bloc\crm_bloc.dart:67:8 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\crm\bloc\crm_bloc.dart:150:8 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\crm\bloc\crm_bloc.dart:198:8 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\crm\view\widgets\dialogs\bonus_adjustment_modal.dart:195:15 - 'value' is deprecated and shouldn't be used. Use initialValue instead. This will set the initial value for the form field. This feature was deprecated after v3.33.0-1.0.pre. Try replacing the use of the deprecated member with the replacement. - deprecated_member_use
   info - features\crm\view\widgets\dialogs\customer_statement_pdf_service.dart:71:113 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\bloc\document_bloc.dart:64:8 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\bloc\document_bloc.dart:81:8 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\bloc\document_bloc.dart:103:8 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\bloc\document_bloc.dart:124:8 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\bloc\document_bloc.dart:207:8 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\bloc\document_bloc.dart:232:8 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\bloc\document_bloc.dart:257:8 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\bloc\document_bloc.dart:275:8 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\bloc\ingredient_bloc.dart:48:13 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\inventory\bloc\ingredient_bloc.dart:59:11 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\inventory\bloc\ingredient_bloc.dart:62:11 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\inventory\bloc\ingredient_bloc.dart:105:11 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\inventory\bloc\ingredient_bloc.dart:108:11 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\inventory\bloc\ingredient_bloc.dart:123:11 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\inventory\bloc\ingredient_bloc.dart:126:11 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\inventory\bloc\ingredient_bloc.dart:136:11 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\inventory\bloc\ingredient_bloc.dart:139:11 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\inventory\bloc\ingredient_bloc.dart:149:11 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\inventory\bloc\ingredient_bloc.dart:152:11 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\inventory\bloc\ingredient_bloc.dart:162:11 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\inventory\bloc\ingredient_bloc.dart:165:11 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\inventory\bloc\recipe_bloc.dart:73:10 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\bloc\recipe_bloc.dart:79:10 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\bloc\recipe_bloc.dart:97:8 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\repository\parts\documents_part.dart:8:8 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\services\export\document_text_builder.dart:82:8 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\services\export_helper_web.dart:2:1 - 'dart:html' is deprecated and shouldn't be used. Use package:web and dart:js_interop instead. Try replacing the use of the deprecated member with the replacement. - deprecated_member_use
   info - features\inventory\view\warehouse_screen.dart:32:42 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\inventory\view\widgets\bulk_add\bulk_add_row_item.dart:209:35 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\inventory\view\widgets\bulk_add\bulk_add_row_item.dart:226:25 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\inventory\view\widgets\bulk_add\bulk_add_save_helper.dart:100:20 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\view\widgets\warehouse\dialogs\edit_supplier_dialog.dart:7:19 - Angle brackets will be interpreted as HTML. Try using backticks around the content with angle brackets, or try replacing `<` with `&lt;` and `>` with `&gt;`. - unintended_html_in_doc_comment
   info - features\inventory\view\widgets\warehouse\dialogs\edit_supplier_dialog.dart:85:95 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\view\widgets\warehouse\dialogs\edit_supplier_dialog.dart:99:60 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\view\widgets\warehouse\dialogs\edit_supplier_dialog.dart:121:60 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\view\widgets\warehouse\dialogs\edit_supplier_dialog.dart:147:95 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\view\widgets\warehouse\dialogs\edit_supplier_dialog.dart:150:97 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\view\widgets\warehouse\dialogs\quick_stock_action_dialog.dart:74:7 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\view\widgets\warehouse\dialogs\quick_stock_action_dialog.dart:80:44 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\inventory\view\widgets\warehouse\dialogs\recipe_bulk_edit\recipe_ingredient_picker.dart:36:15 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\view\widgets\warehouse\dialogs\recipe_bulk_edit\recipe_ingredient_picker.dart:56:22 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\view\widgets\warehouse\dialogs\recipe_bulk_edit\recipe_row_state.dart:10:58 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\view\widgets\warehouse\dialogs\supplier_settlement\supplier_settlement_dialog.dart:62:7 - Don't use 'BuildContext's across async gaps, guarded by an unrelated 'mounted' check. Guard a 'State.context' use with a 'mounted' check on the State, and other BuildContext use with a 'mounted' check on the BuildContext. - use_build_context_synchronously
   info - features\inventory\view\widgets\warehouse\dialogs\supplier_settlement\supplier_settlement_dialog.dart:81:7 - Don't use 'BuildContext's across async gaps, guarded by an unrelated 'mounted' check. Guard a 'State.context' use with a 'mounted' check on the State, and other BuildContext use with a 'mounted' check on the BuildContext. - use_build_context_synchronously
   info - features\inventory\view\widgets\warehouse\dialogs\supplier_settlement\supplier_settlement_row.dart:128:21 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\inventory\view\widgets\warehouse\stock\stock_category_accordion.dart:58:15 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\view\widgets\warehouse\stock\stock_category_header.dart:58:15 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\inventory\view\widgets\warehouse\supplier_row.dart:198:29 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\inventory\view\widgets\warehouse\supplier_row.dart:223:13 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\kitchen\view\widgets\kds\kds_item_row.dart:38:7 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\orders\view\orders_screen.dart:54:15 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\pos\bloc\cart_bloc.dart:190:6 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\pos\bloc\cart_bloc.dart:201:6 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\pos\bloc\cart_bloc.dart:208:5 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\pos\bloc\cart_bloc.dart:224:7 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\pos\bloc\cart_bloc.dart:275:8 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\pos\bloc\cart_bloc.dart:294:6 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\pos\bloc\cart_bloc.dart:313:6 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\pos\bloc\pos_settings_cubit.dart:43:4 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\pos\bloc\pos_settings_cubit.dart:60:8 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\pos\services\lan\local_pos_client.dart:9:4 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\pos\services\lan\local_pos_server.dart:87:13 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\pos\services\lan\local_pos_server.dart:111:13 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\pos\services\pos_sync_service.dart:55:14 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\pos\view\widgets\customer_picker_modal.dart:167:30 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\pos\view\widgets\customer_picker_modal.dart:170:27 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\pos\view\widgets\customer_picker_modal.dart:172:27 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\pos\view\widgets\customer_picker_modal.dart:172:66 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\pos\view\widgets\dialogs\sync_outbox_dialog.dart:198:27 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\pos\view\widgets\helpers\pos_item_click_handler.dart:68:6 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\pos\view\widgets\helpers\pos_item_click_handler.dart:80:12 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\pos\view\widgets\menu_modifiers_dialog.dart:54:10 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\pos\view\widgets\menu_modifiers_dialog.dart:121:10 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\pos\view\widgets\open_shift_modal.dart:162:21 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\pos\view\widgets\pos_mobile_layout.dart:58:33 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\pos\view\widgets\tables\pos_active_table_card.dart:190:25 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\pos\view\widgets\tables\pos_active_table_card.dart:192:29 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\pos\view\widgets\tables\pos_active_table_card.dart:194:29 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\pos\view\widgets\tables\pos_active_table_card.dart:196:38 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\pos\view\widgets\tables\pos_active_table_card.dart:255:25 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\pos\view\widgets\tables\pos_active_table_card.dart:256:26 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\pos\view\widgets\tables\pos_active_table_card.dart:256:47 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - features\settings\repository\user_repository.dart:29:6 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\settings\view\widgets\settings_dialogs.dart:45:46 - Missing a required trailing comma. Try adding a trailing comma. - require_trailing_commas
   info - features\settings\view\widgets\showcase\showcase_dialog_section.dart:43:11 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - main.dart:46:8 - The imported package 'flutter_web_plugins' isn't a dependency of the importing package. Try adding a dependency for 'flutter_web_plugins' in the 'pubspec.yaml' file. - depend_on_referenced_packages
   info - main.dart:229:52 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors

110 issues found.
```

## 2. Таблица факт-чека (Шаг 2)

| Утверждение | Файл:строка | Категория | Доказательство (grep-команда+результат) |
| :--- | :--- | :--- | :--- |
| `backend/ARCHITECTURE_MAP.md` | AGENTS.md:4 | VERIFIED-REAL | `Test-Path backend/ARCHITECTURE_MAP.md` -> True |
| `frontend/ARCHITECTURE_MAP.md` | AGENTS.md:5 | VERIFIED-REAL | `Test-Path frontend/ARCHITECTURE_MAP.md` -> True |
| `ARCHITECTURE_MAP.md` | AGENTS.md:6 | VERIFIED-REAL | `Test-Path ARCHITECTURE_MAP.md` -> True |
| `DESIGN.md` | AGENTS.md:7 | VERIFIED-REAL | `Test-Path DESIGN.md` -> True |
| `01_general.md` | AGENTS.md:20 | VERIFIED-REAL | `Test-Path .agents/rules/01_general.md` -> True |
| `02_backend.md` | AGENTS.md:21 | VERIFIED-REAL | `Test-Path .agents/rules/02_backend.md` -> True |
| `search_path` | AGENTS.md:21 | VERIFIED-REAL | `git grep -n "search_path" backend/` -> `backend/app/database.py:65: await conn.execute(text(f'SET search_path TO "{schema_name}", public'))` |
| `tenant_id` | AGENTS.md:21 | VERIFIED-REAL | `git grep -n "tenant_id: int" backend/app/users/models.py` -> `backend/app/users/models.py:53: tenant_id: int = Field(...)` |
| `TenantModel` | AGENTS.md:21 | VERIFIED-REAL | `git grep -n "class TenantModel" backend/` -> `backend/app/base_model.py:16:class TenantModel(SQLModel):` |
| `Perm` | AGENTS.md:21 | VERIFIED-REAL | `git grep -n "class Perm" backend/` -> `backend/app/users/permissions.py:8:class Perm(str, Enum):` |
| `03_frontend_ui.md` | AGENTS.md:22 | VERIFIED-REAL | `Test-Path .agents/rules/03_frontend_ui.md` -> True |
| `AppButtonSize` | AGENTS.md:22 | VERIFIED-REAL | `git grep -n "enum AppButtonSize" frontend/` -> `frontend/lib/core/widgets/app_button.dart:7:enum AppButtonSize {` |
| `AppNavTile` | AGENTS.md:22 | VERIFIED-REAL | `git grep -n "class AppNavTile" frontend/` -> `frontend/lib/core/widgets/ui_kit/app_nav_tile.dart:45:class AppNavTile extends StatelessWidget {` |
| `get_tenant_session` | AGENTS.md:27 | VERIFIED-REAL | `git grep -n "async def get_tenant_session" backend/` -> `backend/app/dependencies.py:35:async def get_tenant_session(...)` |
| `app/users/permissions.py` | AGENTS.md:28 | VERIFIED-REAL | `Test-Path backend/app/users/permissions.py` -> True |
| `require_permission` | AGENTS.md:28 | VERIFIED-REAL | `git grep -n "def require_permission" backend/` -> `backend/app/dependencies.py:97:def require_permission(...)` |
| `Perm.<NAME>` | AGENTS.md:28 | PLACEHOLDER | Файл явно указывает плейсхолдер вызова: `Depends(require_permission(Perm.<NAME>))` |
| `async with session.begin():` | AGENTS.md:29 | VERIFIED-REAL | `git grep -n "session.begin()" backend/` -> `backend/app/dependencies.py:54: async with session.begin():` |
| `ElevatedButton` | AGENTS.md:31 | VERIFIED-REAL | `git grep -n "ElevatedButton" frontend/` -> `frontend/lib/features/auth/view/login_screen.dart:181: ElevatedButton(...)` |
| `TextButton` | AGENTS.md:31 | VERIFIED-REAL | `git grep -n "TextButton" frontend/` -> `frontend/lib/features/auth/view/login_screen.dart:186: TextButton(...)` |
| `AppPrimaryButton` | AGENTS.md:31 | VERIFIED-REAL | `git grep -n "class AppPrimaryButton" frontend/` -> `frontend/lib/core/widgets/app_button.dart:34:class AppPrimaryButton extends StatelessWidget {` |
| `AppSecondaryButton` | AGENTS.md:31 | VERIFIED-REAL | `git grep -n "class AppSecondaryButton" frontend/` -> `frontend/lib/core/widgets/app_button.dart:104:class AppSecondaryButton extends StatelessWidget {` |
| `AppColors` | AGENTS.md:31 | VERIFIED-REAL | `git grep -n "abstract class AppColors" frontend/` -> `frontend/lib/core/theme/app_colors.dart:4:abstract class AppColors {` |
| `AppRadii` | AGENTS.md:31 | VERIFIED-REAL | `git grep -n "abstract class AppRadii" frontend/` -> `frontend/lib/core/theme/app_radii.dart:4:abstract class AppRadii {` |
| `AppTextStyles` | AGENTS.md:31 | VERIFIED-REAL | `git grep -n "abstract class AppTextStyles" frontend/` -> `frontend/lib/core/theme/app_text_styles.dart:4:abstract class AppTextStyles {` |
| `StatefulWidget` | AGENTS.md:32 | VERIFIED-REAL | `git grep -n "extends StatefulWidget" frontend/` -> `frontend/lib/features/pos/view/widgets/open_shift_modal.dart:21:class OpenShiftModal extends StatefulWidget {` |
| `BLoC` | AGENTS.md:32 | VERIFIED-REAL | `git grep -n "extends Bloc<" frontend/` -> `frontend/lib/features/pos/bloc/cart_bloc.dart:169:class CartBloc extends Bloc<CartEvent, CartState> {` |
| `Equatable` | AGENTS.md:32 | VERIFIED-REAL | `git grep -n "extends Equatable" frontend/` -> `frontend/lib/features/pos/bloc/cart_bloc.dart:98:class CartState extends Equatable {` |
| `backend_architecture` | AGENTS.md:48 | VERIFIED-REAL | `Test-Path .agents/skills/backend_architecture/SKILL.md` -> True |
| `with_for_update` | AGENTS.md:48 | VERIFIED-REAL | `git grep -n "with_for_update" backend/` -> `backend/app/crm/services/crm_ledger_service.py:60: stmt = select(Customer).where(Customer.id == customer_id).with_for_update()` |
| `refactor_bloat` | AGENTS.md:49 | VERIFIED-REAL | `Test-Path .agents/skills/refactor_bloat/SKILL.md` -> True |
| `qa_testing_standards` | AGENTS.md:50 | VERIFIED-REAL | `Test-Path .agents/skills/qa_testing_standards/SKILL.md` -> True |
| `scripts/verify_rules.py` | AGENTS.md:50 | VERIFIED-REAL | `Test-Path scripts/verify_rules.py` -> True |
| `calculate_total` | .agents/rules/01_general.md:28 | PLACEHOLDER | Файл явно указывает как иллюстрацию именования на английском: `(calculate_total, ProcessOrderUseCase)` |
| `ProcessOrderUseCase` | .agents/rules/01_general.md:28 | PLACEHOLDER | Файл явно указывает как иллюстрацию именования на английском: `(calculate_total, ProcessOrderUseCase)` |
| `app.inventory.services.document_service` | .agents/rules/01_general.md:56 | PLACEHOLDER | Файл помечает блок как: `### Эталонный шаблон Backend (Python / FastAPI):` |
| `post_goods_receipt` | .agents/rules/01_general.md:61 | PLACEHOLDER | Файл помечает блок как: `### Эталонный шаблон Backend (Python / FastAPI):` |
| `InventoryDocument` | .agents/rules/01_general.md:61 | VERIFIED-REAL | `git grep -n "class InventoryDocument(" backend/` -> `backend/app/inventory/models/warehouse.py:65:class InventoryDocument(TenantModel, table=True):` |
| `lib/features/pos/view/widgets/checkout_dialog.dart` | .agents/rules/01_general.md:76 | PLACEHOLDER | Файл помечает блок как: `### Эталонный шаблон Frontend (Flutter / Dart):` |
| `CheckoutDialog` | .agents/rules/01_general.md:79 | PLACEHOLDER | Файл помечает блок как: `### Эталонный шаблон Frontend (Flutter / Dart):` |
| `PaymentType` | .agents/rules/01_general.md:86 | PLACEHOLDER | Файл помечает блок как: `### Эталонный шаблон Frontend (Flutter / Dart):` |
| `_onPayPressed` | .agents/rules/01_general.md:86 | PLACEHOLDER | Файл помечает блок как: `### Эталонный шаблон Frontend (Flutter / Dart):` |
| `.agents/sentinel/` | .agents/rules/01_general.md:97 | VERIFIED-REAL | `Test-Path .agents/sentinel` -> True |
| `app/inventory/models/` | .agents/rules/02_backend.md:8 | VERIFIED-REAL | `Test-Path backend/app/inventory/models` -> True (путь относительно backend/) |
| `app/pos/models.py` | .agents/rules/02_backend.md:8 | VERIFIED-REAL | `Test-Path backend/app/pos/models.py` -> True (путь относительно backend/) |
| `app.base_model` | .agents/rules/02_backend.md:15 | VERIFIED-REAL | `git grep -n "from app.base_model import" backend/` -> `backend/app/gift_cards/models.py:19:from app.base_model import TenantModel` |
| `SQLModel` | .agents/rules/02_backend.md:15 | VERIFIED-REAL | `git grep -n "from sqlmodel import" backend/` -> `backend/app/database.py:6:from sqlmodel import SQLModel` |
| `init_tenant_schema` | .agents/rules/02_backend.md:18 | VERIFIED-REAL | `git grep -n "async def init_tenant_schema" backend/` -> `backend/app/database.py:90:async def init_tenant_schema(schema_name: str) -> None:` |
| `auto_migrate_tenant_schemas` | .agents/rules/02_backend.md:18 | VERIFIED-REAL | `git grep -n "async def auto_migrate_tenant_schemas" backend/` -> `backend/app/database.py:108:async def auto_migrate_tenant_schemas() -> None:` |
| `SQLModel.metadata.create_all` | .agents/rules/02_backend.md:18 | VERIFIED-REAL | `git grep -n "metadata.create_all" backend/` -> `backend/app/database.py:100: await conn.run_sync(SQLModel.metadata.create_all)` |
| `backend/migrations/tenant_patches/<номер>_<описание>.sql` | .agents/rules/02_backend.md:19 | PLACEHOLDER | Файл явно указывает шаблон имени SQL-патча: `<номер>_<описание>.sql` |
| `selectinload` | .agents/rules/02_backend.md:30 | VERIFIED-REAL | `git grep -n "selectinload(" backend/` -> `backend/app/pos/services/checkout_service.py:71: existing_stmt = select(Order).where(Order.client_uuid == data.client_uuid).options(selectinload(Order.items))` |
| `joinedload` | .agents/rules/02_backend.md:30 | NOT-FOUND | `git grep -n "joinedload" backend/` -> 0 совпадений. Упомянуто как обязательное правило для many-to-one в `.agents/rules/02_backend.md:30` |
| `begin_nested()` | .agents/rules/02_backend.md:44 | NOT-FOUND | `git grep -n "begin_nested" backend/` -> 0 совпадений. Упомянуто в `.agents/rules/02_backend.md:44` |
| `HTTP 409 CONFLICT` c `detail="Подарочная карта с таким кодом уже зарегистрирована"` | .agents/rules/02_backend.md:47 | NOT-FOUND | `git grep -n "Подарочная карта с таким кодом уже зарегистрирована" backend/` -> 0 совпадений. В коде `backend/app/gift_cards/services.py:63`: `detail=f"Подарочная карта с кодом '{code}' уже зарегистрирована"` |
| `client_uuid` + `HTTP 200 OK` | .agents/rules/02_backend.md:48 | VERIFIED-REAL | `git grep -n "client_uuid" backend/app/pos/services/checkout_service.py` -> `backend/app/pos/services/checkout_service.py:70-74: if data.client_uuid: ... return existing_order` (возврат 200 OK) |
| `Perm.POS_CHECKOUT` | .agents/rules/02_backend.md:57 | NOT-FOUND | `git grep -n "POS_CHECKOUT" backend/` -> 0 совпадений. Упомянуто в `.agents/rules/02_backend.md:57`. В реестре `backend/app/users/permissions.py` отсутствует. |
| `require_any_permission` | .agents/rules/02_backend.md:59 | VERIFIED-REAL | `git grep -n "def require_any_permission" backend/` -> `backend/app/dependencies.py:109:def require_any_permission(...)` |
| `Perm.POS_CASH_OPERATIONS` | .agents/rules/02_backend.md:59 | VERIFIED-REAL | `git grep -n "POS_CASH_OPERATIONS = " backend/` -> `backend/app/users/permissions.py:19: POS_CASH_OPERATIONS = "pos:cash_operations"` |
| `Perm.CASHBOX_OPERATE` | .agents/rules/02_backend.md:59 | VERIFIED-REAL | `git grep -n "CASHBOX_OPERATE = " backend/` -> `backend/app/users/permissions.py:16: CASHBOX_OPERATE = "cashbox:operate"` |
| `app/users/seed.py` | .agents/rules/02_backend.md:63 | VERIFIED-REAL | `Test-Path backend/app/users/seed.py` -> True (путь относительно backend/) |
| `PERMISSIONS` | .agents/rules/02_backend.md:63 | VERIFIED-REAL | `git grep -n "PERMISSIONS = [" backend/app/users/seed.py` -> `backend/app/users/seed.py:10:PERMISSIONS = [` |
| `ROLE_TEMPLATES` | .agents/rules/02_backend.md:63 | VERIFIED-REAL | `git grep -n "ROLE_TEMPLATES = {" backend/app/users/seed.py` -> `backend/app/users/seed.py:84:ROLE_TEMPLATES = {` |
| `lib/features/<имя_модуля>` | .agents/rules/03_frontend_ui.md:8 | PLACEHOLDER | Файл явно указывает шаблон пути: `lib/features/<имя_модуля>` |
| `BlocSelector` | .agents/rules/03_frontend_ui.md:17 | VERIFIED-REAL | `git grep -n "BlocSelector<" frontend/` -> `frontend/lib/features/pos/view/widgets/pos_item_card.dart:58: BlocSelector<CartBloc, CartState, int>(` |
| `restartable()` | .agents/rules/03_frontend_ui.md:20 | VERIFIED-REAL | `git grep -n "restartable()" frontend/` -> `frontend/lib/features/inventory/bloc/category_bloc.dart:21: on<SearchCategoriesEvent>(_onSearch, transformer: restartable());` |
| `sequential()` | .agents/rules/03_frontend_ui.md:21 | VERIFIED-REAL | `git grep -n "sequential()" frontend/` -> `frontend/lib/features/inventory/bloc/category_bloc.dart:25: on<CreateCategoryEvent>(_onCreate, transformer: sequential());` |
| `droppable()` | .agents/rules/03_frontend_ui.md:22 | VERIFIED-REAL | `git grep -n "droppable()" frontend/` -> `frontend/lib/features/gift_cards/bloc/gift_card_bloc.dart:123: on<IssueGiftCardEvent>(_onIssue, transformer: droppable());` |
| `RepositoryProvider` | .agents/rules/03_frontend_ui.md:25 | VERIFIED-REAL | `git grep -n "RepositoryProvider<" frontend/` -> `frontend/lib/main.dart:129: RepositoryProvider<AuthRepository>(` |
| `class _PrivateHelperWidget extends StatelessWidget` | .agents/rules/03_frontend_ui.md:38 | PLACEHOLDER | Файл явно помечает как иллюстрацию приватного класса: `class _PrivateHelperWidget extends StatelessWidget` |
| `AppGhostButton` | .agents/rules/03_frontend_ui.md:43 | VERIFIED-REAL | `git grep -n "class AppGhostButton" frontend/` -> `frontend/lib/core/widgets/app_button.dart:73:class AppGhostButton extends StatelessWidget {` |
| `AppDangerButton` | .agents/rules/03_frontend_ui.md:43 | VERIFIED-REAL | `git grep -n "class AppDangerButton" frontend/` -> `frontend/lib/core/widgets/app_button.dart:137:class AppDangerButton extends StatelessWidget {` |
| `AppMenuButton` | .agents/rules/03_frontend_ui.md:43 | VERIFIED-REAL | `git grep -n "class AppMenuButton" frontend/` -> `frontend/lib/core/widgets/ui_kit/app_menu_button.dart:28:class AppMenuButton extends StatefulWidget {` |
| `AppButtonSize.xs` | .agents/rules/03_frontend_ui.md:46 | VERIFIED-REAL | `git grep -n "AppButtonSize.xs" frontend/` -> `frontend/lib/core/widgets/app_button.dart:276: SizedBox(width: effectiveSize == AppButtonSize.xs ? 4 : 6),` |
| `AppButtonSize.sm` | .agents/rules/03_frontend_ui.md:47 | VERIFIED-REAL | `git grep -n "AppButtonSize.sm" frontend/` -> `frontend/lib/features/gift_cards/view/widgets/issue_gift_card_dialog.dart:167: size: AppButtonSize.sm,` |
| `AppButtonSize.md` | .agents/rules/03_frontend_ui.md:48 | VERIFIED-REAL | `git grep -n "AppButtonSize.md" frontend/` -> `frontend/lib/core/widgets/ui_kit/app_menu_button.dart:47: this.size = AppButtonSize.md,` |
| `AppButtonSize.lg` | .agents/rules/03_frontend_ui.md:49 | VERIFIED-REAL | `git grep -n "AppButtonSize.lg" frontend/` -> `frontend/lib/core/widgets/app_button.dart:169: final effectiveSize = widget.size ?? AppButtonSize.lg;` |
| `AppButtonSize.xl` | .agents/rules/03_frontend_ui.md:50 | VERIFIED-REAL | `git grep -n "AppButtonSize.xl" frontend/` -> `frontend/test/widget_test.dart:105: expect(AppButtonSize.xl.height, equals(52.0));` |
| `AppNavTileSize.sm` | .agents/rules/03_frontend_ui.md:52 | VERIFIED-REAL | `git grep -n "AppNavTileSize.sm" frontend/` -> `frontend/lib/features/menu/view/widgets/catalog/recipe_menu_list.dart:249: size: AppNavTileSize.sm,` |
| `AppNavTileSize.md` | .agents/rules/03_frontend_ui.md:53 | VERIFIED-REAL | `git grep -n "AppNavTileSize.md" frontend/` -> `frontend/lib/core/widgets/ui_kit/app_nav_tile.dart:63: this.size = AppNavTileSize.md,` |
| `AppNavTileSize.lg` | .agents/rules/03_frontend_ui.md:54 | VERIFIED-REAL | `git grep -n "AppNavTileSize.lg" frontend/` -> `frontend/lib/core/widgets/main_layout/app_nav_rail.dart:91: size: AppNavTileSize.lg,` |
| `AppColors.brandPrimary` | .agents/rules/03_frontend_ui.md:64 | VERIFIED-REAL | `git grep -n "AppColors.brandPrimary" frontend/` -> `frontend/lib/core/theme/app_colors.dart:6: static Color brandPrimary = const Color(0xFF0284C7);` |
| `AppColors.brandSecondary` | .agents/rules/03_frontend_ui.md:64 | VERIFIED-REAL | `git grep -n "AppColors.brandSecondary" frontend/` -> `frontend/lib/core/theme/app_colors.dart:7: static Color brandSecondary = const Color(0xFF0369A1);` |
| `app_colors.dart` | .agents/rules/03_frontend_ui.md:64 | VERIFIED-REAL | `Test-Path frontend/lib/core/theme/app_colors.dart` -> True |
| `applyPalette()` | .agents/rules/03_frontend_ui.md:64 | VERIFIED-REAL | `git grep -n "applyPalette" frontend/` -> `frontend/lib/core/theme/app_colors.dart:93: static void applyPalette({required dynamic palette, bool isDark = true}) {` |
| `AppRadii.card` | .agents/rules/03_frontend_ui.md:78 | VERIFIED-REAL | `git grep -n "card = " frontend/lib/core/theme/app_radii.dart` -> `frontend/lib/core/theme/app_radii.dart:18: static const double card = xl; // 16.0` |
| `AppRadii.button` | .agents/rules/03_frontend_ui.md:79 | VERIFIED-REAL | `git grep -n "button = " frontend/lib/core/theme/app_radii.dart` -> `frontend/lib/core/theme/app_radii.dart:17: static const double button = lg; // 12.0` (значение 12.0, в правиле написано 8-10px) |
| `AppRadii.inputRadius` | .agents/rules/03_frontend_ui.md:79 | VERIFIED-REAL | `git grep -n "inputRadius = " frontend/lib/core/theme/app_radii.dart` -> `frontend/lib/core/theme/app_radii.dart:24: static final BorderRadius inputRadius = BorderRadius.circular(input);` |
| `AppRadii.pill` | .agents/rules/03_frontend_ui.md:80 | VERIFIED-REAL | `git grep -n "pill = " frontend/lib/core/theme/app_radii.dart` -> `frontend/lib/core/theme/app_radii.dart:21: static const double pill = 24.0;` |
| `AppColors.glassBorder` | .agents/rules/03_frontend_ui.md:83 | NOT-FOUND | `git grep -n "glassBorder" frontend/` -> 0 совпадений. Упомянуто как факт в `.agents/rules/03_frontend_ui.md:83`. |
| `Perm.<ACTION>` | .agents/skills/backend_architecture/SKILL.md:23 | PLACEHOLDER | Файл явно указывает плейсхолдер в диаграмме: `Perm.<ACTION>` |
| `backend/app/<domain>/services/<domain>_workflow_service.py` | .agents/skills/backend_architecture/SKILL.md:60 | PLACEHOLDER | Файл явно помечает секцию как `## 2. Рецепт А: Транзакционный Workflow Service (Writer)` |
| `DomainWorkflowService` | .agents/skills/backend_architecture/SKILL.md:69 | PLACEHOLDER | Файл явно помечает класс как часть `## 2. Рецепт А` |
| `DomainEntity` | .agents/skills/backend_architecture/SKILL.md:76 | PLACEHOLDER | Файл явно помечает класс как часть `## 2. Рецепт А` |
| `TransactionAudit` | .agents/skills/backend_architecture/SKILL.md:90 | PLACEHOLDER | Файл явно помечает класс как часть `## 2. Рецепт А` |
| `DomainQueryService` | .agents/skills/backend_architecture/SKILL.md:174 | PLACEHOLDER | Файл явно помечает класс как часть `## 3. Рецепт Б: Высокопроизводительный Query Service (Reader)` |
| `ItemCreate` | .agents/skills/backend_architecture/SKILL.md:234 | PLACEHOLDER | Файл явно помечает класс как часть `## 4. Рецепт В: Pydantic v2 DTO Триада` |
| `ItemUpdate` | .agents/skills/backend_architecture/SKILL.md:241 | PLACEHOLDER | Файл явно помечает класс как часть `## 4. Рецепт В: Pydantic v2 DTO Триада` |
| `ItemRead` | .agents/skills/backend_architecture/SKILL.md:247 | PLACEHOLDER | Файл явно помечает класс как часть `## 4. Рецепт В: Pydantic v2 DTO Триада` |
| `ALTER TABLE "{schema}".items ADD COLUMN IF NOT EXISTS barcode VARCHAR(64);` | .agents/skills/backend_architecture/SKILL.md:275 | PLACEHOLDER | Файл помечает блок как: `[ИНВАРИАНТ] Идемпотентный патч с плейсхолдером "{schema}"` |
| `python scripts/verify_rules.py --target <имя_модуля>` | .agents/skills/backend_architecture/SKILL.md:297 | VERIFIED-REAL | `git grep -n "--target" scripts/verify_rules.py` -> `scripts/verify_rules.py:27: parser.add_argument("--target", ...)` |
| `make_tenant_client` | .agents/skills/qa_testing_standards/SKILL.md:30 | PLACEHOLDER | Файл явно помечает блок как `## 1. Обязательный квадривиум тестов бэкенда` (шаблон) |
| `Perm.GIFT_CARDS_MANAGE` | .agents/skills/qa_testing_standards/SKILL.md:92 | NOT-FOUND | `git grep -n "GIFT_CARDS_MANAGE" backend/` -> 0 совпадений. В коде `backend/app/users/permissions.py:51` зарегистрировано `GIFTCARDS_MANAGE` (без подчеркивания между GIFT и CARDS). |
| `test_tenant_isolation` | .agents/skills/qa_testing_standards/SKILL.md:86 | PLACEHOLDER | Файл явно помечает функцию как шаблон теста в `## 1` |
| `test_transaction_rollback_on_failure` | .agents/skills/qa_testing_standards/SKILL.md:116 | PLACEHOLDER | Файл явно помечает функцию как шаблон теста в `## 1` |
| `test_pbac_forbidden_without_permission` | .agents/skills/qa_testing_standards/SKILL.md:137 | PLACEHOLDER | Файл явно помечает функцию как шаблон теста в `## 1` |
| `test_duplicate_conflict_and_idempotency` | .agents/skills/qa_testing_standards/SKILL.md:153 | PLACEHOLDER | Файл явно помечает функцию как шаблон теста в `## 1` |
| `MockDomainRepository` | .agents/skills/qa_testing_standards/SKILL.md:190 | PLACEHOLDER | Файл явно помечает блок как `## 2. Тестирование фронтенда` (шаблон) |
| `DomainBloc` | .agents/skills/qa_testing_standards/SKILL.md:200 | PLACEHOLDER | Файл явно помечает блок как `## 2. Тестирование фронтенда` (шаблон) |
| `MockDomainBloc` | .agents/skills/qa_testing_standards/SKILL.md:246 | PLACEHOLDER | Файл явно помечает блок как `## 2. Тестирование фронтенда` (шаблон) |
| `MyDialog` | .agents/skills/qa_testing_standards/SKILL.md:268 | PLACEHOLDER | Файл явно помечает блок как `## 2. Тестирование фронтенда` (шаблон) |
| `_FilterPill` | .agents/skills/refactor_bloat/SKILL.md:33 | PLACEHOLDER | Файл помечает блок как `Паттерн А: Вспомогательный приватный StatelessWidget (без выноса)` |
| `_InlineCommentField` | .agents/skills/refactor_bloat/SKILL.md:60 | PLACEHOLDER | Файл помечает блок как `Паттерн Б: Приватный StatefulWidget с контроллером` |
| `frontend/lib/features/gift_cards/view/widgets/topup_gift_card_dialog.dart` | .agents/skills/refactor_bloat/SKILL.md:106 | PLACEHOLDER | Файл помечает блок как `Паттерн В: Вынос диалога / модалки`. Файл не существует в проекте. |
| `TopUpGiftCardDialog` | .agents/skills/refactor_bloat/SKILL.md:111 | PLACEHOLDER | Файл помечает блок как `Паттерн В: Вынос диалога / модалки`. Класс не существует в коде. |
| `GiftCardBloc` | .agents/skills/refactor_bloat/SKILL.md:117 | VERIFIED-REAL | `git grep -n "class GiftCardBloc" frontend/` -> `frontend/lib/features/gift_cards/bloc/gift_card_bloc.dart:115:class GiftCardBloc extends Bloc<GiftCardEvent, GiftCardState> {` |
| `TopUpGiftCardEvent` | .agents/skills/refactor_bloat/SKILL.md:149 | VERIFIED-REAL | `git grep -n "class TopUpGiftCardEvent" frontend/` -> `frontend/lib/features/gift_cards/bloc/gift_card_bloc.dart:48:class TopUpGiftCardEvent extends GiftCardEvent {` |
| `AppDialogScaffold` | .agents/skills/refactor_bloat/SKILL.md:157 | VERIFIED-REAL | `git grep -n "class AppDialogScaffold" frontend/` -> `frontend/lib/core/widgets/app_dialog_scaffold.dart:8:class AppDialogScaffold extends StatelessWidget {` |
| `CartBloc` | .agents/skills/refactor_bloat/SKILL.md:170 | VERIFIED-REAL | `git grep -n "class CartBloc" frontend/` -> `frontend/lib/features/pos/bloc/cart_bloc.dart:169:class CartBloc extends Bloc<CartEvent, CartState> {` |
| `CartState` | .agents/skills/refactor_bloat/SKILL.md:170 | VERIFIED-REAL | `git grep -n "class CartState" frontend/` -> `frontend/lib/features/pos/bloc/cart_bloc.dart:98:class CartState extends Equatable {` |
| `AppTextStyles.priceLarge` | .agents/skills/refactor_bloat/SKILL.md:173 | VERIFIED-REAL | `git grep -n "priceLarge" frontend/` -> `frontend/lib/core/theme/app_text_styles.dart:58: static const TextStyle priceLarge = TextStyle(...)` |
| `CatalogBloc` | .agents/skills/refactor_bloat/SKILL.md:184 | PLACEHOLDER | Файл помечает блок как `Паттерн Д: Рефакторинг BLoC с EventTransformers` (шаблон) |
| `SearchCatalogEvent` | .agents/skills/refactor_bloat/SKILL.md:191 | PLACEHOLDER | Файл помечает блок как `Паттерн Д: Рефакторинг BLoC с EventTransformers` (шаблон) |
| `UpdateProductEvent` | .agents/skills/refactor_bloat/SKILL.md:194 | PLACEHOLDER | Файл помечает блок как `Паттерн Д: Рефакторинг BLoC с EventTransformers` (шаблон) |
| `AppSegmentedControl` | DESIGN.md:102 | VERIFIED-REAL | `git grep -n "class AppSegmentedControl" frontend/` -> `frontend/lib/core/widgets/ui_kit/app_segmented_control.dart:51:class AppSegmentedControl<T> extends StatelessWidget {` |
| `AppSegmentedSize` | DESIGN.md:103 | VERIFIED-REAL | `git grep -n "enum AppSegmentedSize" frontend/` -> `frontend/lib/core/widgets/ui_kit/app_segmented_control.dart:8:enum AppSegmentedSize {` |
| `AppColors.darkTrackBg` | DESIGN.md:106 | VERIFIED-REAL | `git grep -n "darkTrackBg" frontend/` -> `frontend/lib/core/theme/app_colors.dart:70: static Color darkTrackBg = const Color(0xFF0A1220);` |
| `AppColors.lightTrackBg` | DESIGN.md:106 | VERIFIED-REAL | `git grep -n "lightTrackBg" frontend/` -> `frontend/lib/core/theme/app_colors.dart:71: static Color lightTrackBg = const Color(0xFFECEEF2);` |
| `AppFilterChip` | DESIGN.md:108 | VERIFIED-REAL | `git grep -n "class AppFilterChip" frontend/` -> `frontend/lib/core/widgets/ui_kit/app_filter_chip.dart:50:class AppFilterChip extends StatelessWidget {` |
| `AppFilterBar` | DESIGN.md:108 | VERIFIED-REAL | `git grep -n "class AppFilterBar" frontend/` -> `frontend/lib/core/widgets/ui_kit/app_filter_chip.dart:181:class AppFilterBar extends StatelessWidget {` |
| `AppFilterChipSize` | DESIGN.md:111 | VERIFIED-REAL | `git grep -n "enum AppFilterChipSize" frontend/` -> `frontend/lib/core/widgets/ui_kit/app_filter_chip.dart:6:enum AppFilterChipSize {` |
| `AppOrderContextChip` | DESIGN.md:116 | VERIFIED-REAL | `git grep -n "class AppOrderContextChip" frontend/` -> `frontend/lib/core/widgets/ui_kit/app_filter_chip.dart:212:class AppOrderContextChip extends StatelessWidget {` |
| `AppSearchField` | DESIGN.md:119 | VERIFIED-REAL | `git grep -n "class AppSearchField" frontend/` -> `frontend/lib/core/widgets/ui_kit/app_search_field.dart:58:class AppSearchField extends StatefulWidget {` |
| `AppSearchFieldSize` | DESIGN.md:122 | VERIFIED-REAL | `git grep -n "enum AppSearchFieldSize" frontend/` -> `frontend/lib/core/widgets/ui_kit/app_search_field.dart:10:enum AppSearchFieldSize {` |
| `AppSearchMode` | DESIGN.md:126 | VERIFIED-REAL | `git grep -n "enum AppSearchMode" frontend/` -> `frontend/lib/core/widgets/ui_kit/app_search_field.dart:17:enum AppSearchMode {` |
| `AppRadii.sm` | DESIGN.md:152 | VERIFIED-REAL | `git grep -n "sm = " frontend/lib/core/theme/app_radii.dart` -> `frontend/lib/core/theme/app_radii.dart:7: static const double sm = 6.0;` |
| `AppRadii.md` | DESIGN.md:109 | VERIFIED-REAL | `git grep -n "md = " frontend/lib/core/theme/app_radii.dart` -> `frontend/lib/core/theme/app_radii.dart:8: static const double md = 8.0;` |
| `AppDialog` | DESIGN.md:177 | VERIFIED-REAL | `git grep -n "class AppDialog" frontend/` -> `frontend/lib/core/widgets/app_dialog.dart:13:class AppDialog extends StatelessWidget {` |

## 3. Покрытие новых модулей (Шаг 3)

Дата в шапке `ARCHITECTURE_MAP.md`: **2026-09-20** (контрольный коммит `672602c`).

Список модулей и файлов, созданных/изменённых позже даты `2026-09-20` (по данным `git log 672602c..HEAD`):

1. **Модуль инкассации / кассовых операций (Cash Operations):**
   - Точные пути файлов:
     - `backend/app/pos/models_cash_operation.py`
     - `backend/app/pos/routers/cash_operation_router.py`
     - `backend/app/pos/services/cash_operation_service.py`
     - `backend/tests/test_cash_operations.py`
     - `frontend/lib/features/pos/models/cash_operation.dart`
     - `frontend/lib/features/pos/view/widgets/cash_operations/cash_operation_dialog.dart`
     - `frontend/test/cash_operation_test.dart`
   - Статус покрытия: **НЕ ПОКРЫТО ПРАВИЛАМИ**
   - Фиксация данных:
     - В `.agents/rules/02_backend.md:59` упоминаются названия прав `Perm.POS_CASH_OPERATIONS` и `Perm.CASHBOX_OPERATE`.
     - В `.agents/skills/backend_architecture/SKILL.md:50` слово «инкассация» упоминается в скобках в списке примеров мутаций: `(списание склада, проведение чека, пополнение карты, инкассация)`.
     - Ни в одном файле каталогов `.agents/rules/` или `.agents/skills/` нет спецификации, контракта или раздела, регламентирующего логику кассовых операций / инкассации.
     - Файлы модуля инкассации (`models_cash_operation.py`, `cash_operation_router.py`, `cash_operation_service.py`, `cash_operation.dart`, `cash_operation_dialog.dart`) отсутствуют в `ARCHITECTURE_MAP.md`, `backend/ARCHITECTURE_MAP.md` и `frontend/ARCHITECTURE_MAP.md`.

2. **Модуль подарочных карт (Gift Cards):**
   - Точные пути файлов:
     - `backend/app/gift_cards/__init__.py`
     - `backend/app/gift_cards/models.py`
     - `backend/app/gift_cards/router.py`
     - `backend/app/gift_cards/services.py`
     - `backend/tests/test_gift_cards.py`
     - `frontend/lib/features/gift_cards/bloc/gift_card_bloc.dart`
     - `frontend/lib/features/gift_cards/models/gift_card.dart`
     - `frontend/lib/features/gift_cards/repository/gift_card_repository.dart`
     - `frontend/lib/features/gift_cards/view/widgets/gift_card_preview_card.dart`
     - `frontend/lib/features/gift_cards/view/widgets/issue_gift_card_dialog.dart`
   - Статус покрытия: **ПОКРЫТО ПРАВИЛАМИ** (добавлен в `ARCHITECTURE_MAP.md:36`, ссылки на модуль присутствуют в `02_backend.md:47`, `backend_architecture/SKILL.md:53`, `refactor_bloat/SKILL.md:105-150`).

3. **Вспомогательные сервисы номенклатуры (Inventory Helpers):**
   - Точные пути файлов:
     - `backend/app/inventory/services/document_completion_helper.py`
     - `backend/app/inventory/services/menu_variation_helper.py`
   - Статус покрытия: **НЕ ПОКРЫТО ПРАВИЛАМИ** (файлы отсутствуют в `backend/ARCHITECTURE_MAP.md`).

4. **Тестовые наборы инвариантов и вариаций:**
   - Точные пути файлов:
     - `backend/tests/test_retail_variations.py`
     - `backend/tests/test_poka_yoke_guards.py`
   - Статус покрытия: **ПОКРЫТО ПРАВИЛАМИ** (входят в общий тестовый прогон `pytest`, регламентированный в `02_backend.md §6`).

5. **Сервисы локальной синхронизации POS (LAN Sync):**
   - Точные пути файлов:
     - `frontend/lib/features/pos/services/lan/local_pos_client.dart`
     - `frontend/lib/features/pos/services/lan/local_pos_server.dart`
     - `frontend/lib/features/pos/services/pos_sync_service.dart`
   - Статус покрытия: **НЕ ПОКРЫТО ПРАВИЛАМИ** (файлы отсутствуют в `frontend/ARCHITECTURE_MAP.md`).

## 4. Эмпирическая проверка на тест-драйве gift_cards (Шаг 3.5)

Файлы модуля `gift_cards`:
- Backend: `backend/app/gift_cards/__init__.py`, `backend/app/gift_cards/models.py`, `backend/app/gift_cards/router.py`, `backend/app/gift_cards/services.py`, `backend/tests/test_gift_cards.py`
- Frontend: `frontend/lib/features/gift_cards/bloc/gift_card_bloc.dart`, `frontend/lib/features/gift_cards/models/gift_card.dart`, `frontend/lib/features/gift_cards/repository/gift_card_repository.dart`, `frontend/lib/features/gift_cards/view/widgets/gift_card_preview_card.dart`, `frontend/lib/features/gift_cards/view/widgets/issue_gift_card_dialog.dart`

### 1. Использование `.with_for_update()` при операциях с балансом (backend_architecture §2)
- **Вердикт:** **ЧАСТИЧНО**
- **Доказательство (код `backend/app/gift_cards/services.py:103` и `153`):**
```python
# backend/app/gift_cards/services.py:103 (redeem_gift_card)
card = await session.get(GiftCard, card_id, with_for_update=True)

# backend/app/gift_cards/services.py:153 (top_up_gift_card)
card = await session.get(GiftCard, card_id, with_for_update=True)
```
- **Доказательство расхождения с рецептом `.agents/skills/backend_architecture/SKILL.md:52-55`:**
```
> [!IMPORTANT] ПЕССИМИСТИЧЕСКАЯ БЛОКИРОВКА WITH_FOR_UPDATE
> Любая операция списания или пополнения баланса (подарочные карты, касса, склад, бонусы клиентов)
> ОБЯЗАНА использовать явную блокировку строки через select(Model).where(...).with_for_update().
> *Не используй session.get(), так как он может вернуть кэшированный объект из Identity Map без выполнения реального SQL-запроса FOR UPDATE!*
```
В коде использован вызов `session.get(..., with_for_update=True)` вместо конструкции `select(GiftCard).where(GiftCard.id == card_id).with_for_update()`, которая предписана в рецепте.

### 2. Реализация контракта client_uuid/409/200 из 02_backend.md §4
- **Вердикт:** **ЧАСТИЧНО**
- **Доказательство реализации HTTP 409 при дубликате (`backend/app/gift_cards/services.py:59-64`):**
```python
existing = await session.execute(select(GiftCard).where(GiftCard.code == code))
if existing.scalars().first() is not None:
    raise HTTPException(
        status_code=status.HTTP_409_CONFLICT,
        detail=f"Подарочная карта с кодом '{code}' уже зарегистрирована",
    )
```
- **Доказательство отсутствия client_uuid / HTTP 200 no-op:**
`git grep -n "client_uuid" backend/app/gift_cards/` возвращает 0 строк (код завершения 1). Поле `client_uuid` отсутствует в схемах `GiftCardCreate`, `GiftCardRedeem`, `GiftCardTopUp`, отсутствует в модели `GiftCard` и не обрабатывается в сервисах эмиссии/списания.

### 3. Использование DTO-триады (Create/Update/Read) без прямой отдачи ORM-модели
- **Вердикт:** **СЛЕДУЕТ**
- **Доказательство (схемы в `backend/app/gift_cards/models.py:149-212`):**
```python
class GiftCardCreate(SQLModel): ...         # Входные данные создания (строка 149)
class GiftCardRedeem(SQLModel): ...         # Входные данные списания (строка 158)
class GiftCardTopUp(SQLModel): ...          # Входные данные пополнения (строка 165)
class GiftCardUpdateStatus(SQLModel): ...   # Входные данные обновления статуса (строка 171)
class GiftCardTransactionRead(SQLModel): ...# Выходные данные транзакции (строка 178)
class GiftCardRead(SQLModel): ...           # Выходные данные карты (строка 192)
class GiftCardListResponse(SQLModel): ...   # Пагинированный список карт (строка 208)
```
- **Доказательство применения в роутере `backend/app/gift_cards/router.py`:**
```python
@router.post("", response_model=GiftCardRead, status_code=status.HTTP_201_CREATED, ...)
@router.get("", response_model=GiftCardListResponse, ...)
@router.get("/lookup", response_model=GiftCardRead, ...)
@router.get("/{card_id}", response_model=GiftCardRead, ...)
@router.post("/{card_id}/redeem", response_model=GiftCardRead, ...)
@router.post("/{card_id}/topup", response_model=GiftCardRead, ...)
@router.patch("/{card_id}/status", response_model=GiftCardRead, ...)
```
Все эндпоинты типизированы DTO-схемами через `response_model`, сериализация выполняется через схемы SQLModel/Pydantic.

### 4. Наличие явного теста на модуль, покрывающего IDOR/rollback/PBAC по образцу из qa_testing_standards
- **Вердикт:** **ЧАСТИЧНО**
- **PBAC:** **СЛЕДУЕТ**. В `backend/tests/test_gift_cards.py:171-197` функция `test_gift_card_pbac_permissions` верифицирует возврат 403 Forbidden пользователю без прав:
```python
token = user_svc.create_access_token(user_id=user_no_perm.id, tenant_id=tenant.id, permissions=[], is_superuser=False)
headers = {"Authorization": f"Bearer {token}"}
resp = await async_client.post("/api/v1/gift-cards", json={"initial_balance": 1000.0}, headers=headers)
assert resp.status_code == 403
assert "Missing permissions" in resp.json()["detail"]
```
- **IDOR (Cross-Tenant):** **ЧАСТИЧНО**. В `backend/tests/test_gift_cards.py:21-92` функция `test_cross_tenant_gift_card_isolation` проверяет изоляцию балансов между `tenant_alpha` и `tenant_beta`, однако отсутствует проверка попытки прямого чтения сущности по `card_a['id']` с заголовками `headers_b` с ожиданием ответа `404 Not Found`, предписанная шаблоном `qa_testing_standards/SKILL.md:108-112`:
```python
# qa_testing_standards/SKILL.md:108-112 (эталонный образец):
# res_idor = await async_client.get(f"/api/v1/<domain>/{item_id}", headers=headers_beta)
# assert res_idor.status_code == 404
```
- **Rollback:** **НЕ СЛЕДУЕТ**. В `backend/tests/test_gift_cards.py` отсутствует тест транзакционного отката составной операции при принудительном сбое с верификацией отсутствия мусорных записей в таблице транзакций через прямой SQL-запрос `select(...)` (по образцу `qa_testing_standards/SKILL.md:116-134`).
