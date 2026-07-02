import os
import re

directory = r"D:\Mynix_Control\frontend\lib"
target_files = [
    r"core\widgets\main_layout\cashbox_modal.dart",
    r"core\widgets\main_layout\mynix_app_bar.dart",
    r"features\inventory\view\inventory_screen.dart",
    r"features\inventory\view\widgets\menu_manager_items_grid.dart",
    r"features\inventory\view\widgets\warehouse\stock\hoverable_stock_item.dart",
    r"features\inventory\view\widgets\warehouse\stock\stock_category_accordion.dart",
    r"features\inventory\view\widgets\warehouse\stock\stock_item_row.dart",
    r"features\inventory\view\widgets\warehouse\stock_tab.dart",
    r"features\menu\view\widgets\catalog\items\menu_grid_item.dart",
    r"features\menu\view\widgets\catalog\items\menu_list_item.dart",
    r"features\pos\view\pos_screen.dart",
    r"features\pos\view\widgets\components\pos_cart_header.dart",
    r"features\pos\view\widgets\components\pos_cart_item_tile.dart",
    r"features\pos\view\widgets\components\pos_checkout_panel.dart",
    r"features\pos\view\widgets\components\pos_item_card.dart",
    r"features\inventory\view\widgets\warehouse\documents_journal_tab.dart",
]

for rel_path in target_files:
    file_path = os.path.join(directory, rel_path)
    if not os.path.exists(file_path):
        continue
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Find anything before .toCurrency(context) inside ${...} or plain
    # Since we might have complex expressions like (state... ?? state...)
    # The safest way is to replace .toCurrency(context) manually or use a smarter regex.
    # Actually, if we just cast to num, it's easy:
    # 1. mynix_app_bar.dart:
    # (state.shiftDetails['current_cash_expected'] ?? state.shiftDetails['opening_cash']).toCurrency(context)
    # 2. pos_screen.dart:
    # (diff as num).toCurrency(context)
    # 3. stock_item_row.dart:
    # (item.currentStock * item.costPerUnit).toCurrency(context)
    # 
    # But wait, we can just replace `.toCurrency(context)` with ` as num).toCurrency(context)` if we wrap it.
    # Let's just use CurrencyFormatter.format(context, ...)
    
    # We can just run a regex that captures everything before .toCurrency(context) up to the `${` or start of string.
    # But nested parentheses make it hard for regex.
    
    # Let's just do it manually for the files that are dynamic, or replace them all with a simpler regex.
    pass
