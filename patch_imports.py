import os

def insert_import(filepath, import_statement):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if import_statement not in content:
        lines = content.split('\n')
        # find last import
        last_import = 0
        for i, line in enumerate(lines):
            if line.startswith('import '):
                last_import = i
        
        lines.insert(last_import + 1, import_statement)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))

def main():
    insert_import('frontend/lib/core/router/app_router.dart', "import 'package:mynix_frontend/features/pos/view/pos_screen.dart';")
    insert_import('frontend/lib/features/inventory/view/warehouse_screen.dart', "import 'package:mynix_frontend/features/inventory/view/widgets/warehouse/documents_journal_tab.dart';")
    insert_import('frontend/lib/features/inventory/view/widgets/menu_manager_tab.dart', "import 'package:mynix_frontend/features/inventory/view/widgets/menu_manager_breadcrumbs.dart';")
    insert_import('frontend/lib/features/menu/view/widgets/catalog/catalog_content_view.dart', "import 'package:mynix_frontend/features/menu/view/widgets/catalog/items/menu_grid_item.dart';")
    insert_import('frontend/lib/features/menu/view/widgets/catalog/catalog_grid_view.dart', "import 'package:mynix_frontend/features/menu/view/widgets/catalog/items/menu_grid_item.dart';")

if __name__ == '__main__':
    main()
