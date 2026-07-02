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
    r"features\pos\view\widgets\components\pos_cart_header.dart",
    r"features\pos\view\widgets\components\pos_cart_item_tile.dart",
    r"features\pos\view\widgets\components\pos_item_card.dart",
]

for rel_path in target_files:
    file_path = os.path.join(directory, rel_path)
    if not os.path.exists(file_path):
        continue
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    new_content = content.replace("${${", "${").replace("}.toCurrency(context)}", ".toCurrency(context)}")
    
    if new_content != content:
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"Fixed {rel_path}")
