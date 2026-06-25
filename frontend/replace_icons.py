import os
import re

directories = [
    r"d:\Mynix_Control\frontend\lib\features\menu",
    r"d:\Mynix_Control\frontend\lib\features\pos"
]

icon_mapping = {
    "Icons.category": "PhosphorIconsRegular.squaresFour",
    "Icons.fastfood": "PhosphorIconsRegular.hamburger",
    "Icons.storefront": "PhosphorIconsRegular.storefront",
    "Icons.kitchen": "PhosphorIconsRegular.cookingPot",
    "Icons.receipt_long": "PhosphorIconsRegular.receipt",
    "Icons.add": "PhosphorIconsRegular.plus",
    "Icons.create_new_folder": "PhosphorIconsRegular.folderPlus",
    "Icons.select_all": "PhosphorIconsRegular.checkSquare",
    "Icons.deselect": "PhosphorIconsRegular.square",
    "Icons.close": "PhosphorIconsRegular.x",
    "Icons.delete_forever": "PhosphorIconsRegular.trash",
    "Icons.visibility": "PhosphorIconsRegular.eye",
    "Icons.visibility_off": "PhosphorIconsRegular.eyeSlash",
    "Icons.arrow_back": "PhosphorIconsRegular.arrowLeft",
    "Icons.chevron_right": "PhosphorIconsRegular.caretRight",
    "Icons.format_list_bulleted_add": "PhosphorIconsRegular.listPlus",
    "Icons.tune": "PhosphorIconsRegular.faders",
    "Icons.grid_view": "PhosphorIconsRegular.gridFour",
    "Icons.view_list": "PhosphorIconsRegular.list",
    "Icons.delete_outline": "PhosphorIconsRegular.trash",
    "Icons.more_vert": "PhosphorIconsRegular.dotsThreeVertical",
    "Icons.lock_clock": "PhosphorIconsRegular.lockKey",
    "Icons.payments": "PhosphorIconsRegular.money",
    "Icons.lock_outline": "PhosphorIconsRegular.lock",
    "Icons.account_balance_wallet": "PhosphorIconsRegular.wallet",
    "Icons.arrow_back_ios_rounded": "PhosphorIconsRegular.caretLeft",
    "Icons.chevron_right_rounded": "PhosphorIconsRegular.caretRight",
    "Icons.receipt_long_outlined": "PhosphorIconsRegular.receipt",
    "Icons.delete_sweep_outlined": "PhosphorIconsRegular.trash",
    "Icons.close_rounded": "PhosphorIconsRegular.x",
    "Icons.remove": "PhosphorIconsRegular.minus",
    "Icons.shopping_bag_outlined": "PhosphorIconsRegular.shoppingBag",
    "Icons.fastfood_outlined": "PhosphorIconsRegular.hamburger",
    "Icons.restaurant_menu_outlined": "PhosphorIconsRegular.bookOpen",
}

import_statement = "import 'package:phosphor_flutter/phosphor_flutter.dart';"

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    
    # Check if there are any Icons.* in the file
    if "Icons." not in content:
        return

    # Replace icons
    for old_icon, new_icon in icon_mapping.items():
        # Match exactly Icons.something not Icons.something_else
        # e.g., Icons\.fastfood(?![a-zA-Z0-9_])
        pattern = re.escape(old_icon) + r"(?![a-zA-Z0-9_])"
        content = re.sub(pattern, new_icon, content)

    if content != original_content:
        # Check if import needs to be added
        if "package:phosphor_flutter/phosphor_flutter.dart" not in content:
            # Add import after the last import statement or at the top
            imports = re.findall(r"^import\s+['\"].*?['\"];", content, re.MULTILINE)
            if imports:
                last_import = imports[-1]
                content = content.replace(last_import, last_import + "\n" + import_statement, 1)
            else:
                content = import_statement + "\n\n" + content
                
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

for directory in directories:
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".dart"):
                process_file(os.path.join(root, file))
