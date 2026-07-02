import os
import re

directory = r"D:\Mynix_Control\frontend\lib"
import_statement = "import 'package:mynix_frontend/core/utils/currency_formatter.dart';\n"

# Files that need patching
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
        print(f"Skipping {file_path}")
        continue
    
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    modified = False

    # Insert import if not present
    if import_statement.strip() not in content:
        # insert after last import
        last_import = content.rfind("import '")
        if last_import != -1:
            end_of_line = content.find("\n", last_import)
            content = content[:end_of_line+1] + import_statement + content[end_of_line+1:]
        else:
            content = import_statement + "\n" + content
        modified = True

    # Do specific replacements
    
    # \${something} с -> something.toCurrency(context)
    # \${something.toInt()} с -> something.toCurrency(context)
    # \${something.toStringAsFixed(..)} с -> something.toCurrency(context)
    
    # We will use regex to find occurrences like `'${...} с'` or `"Σ: ${...} с"`
    def repl(m):
        prefix = m.group(1) # e.g. "'", "'Σ: ", etc
        expr = m.group(2)   # e.g. "item.price" or "item.price.toInt()"
        suffix = m.group(3) # e.g. "'"
        
        # Clean up expr
        expr = re.sub(r'\.toInt\(\)', '', expr)
        expr = re.sub(r'\.toStringAsFixed\(\d+\)', '', expr)
        
        # if expr contains a space or operators without parens, wrap in parens
        if " " in expr or "*" in expr or "+" in expr or "?? " in expr:
            expr = f"({expr})"
            
        return f"{prefix}${{{expr}.toCurrency(context)}}{suffix}"

    new_content = re.sub(r"('|\"|'Σ: |'Σ |\"Σ: |\"Σ )(\$\{[^\}]+\})\s*[с₸]('|\")", repl, content)
    if new_content != content:
        content = new_content
        modified = True

    # Also handle strings like '... $diff с' 
    def repl2(m):
        prefix = m.group(1)
        var = m.group(2)
        suffix = m.group(3)
        return f"{prefix}${{{var}.toCurrency(context)}}{suffix}"
        
    new_content = re.sub(r"('|\"|: )\$([a-zA-Z0-9_]+)\s*[с₸]('|\")", repl2, content)
    if new_content != content:
        content = new_content
        modified = True

    if modified:
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Updated {rel_path}")
