import os
import subprocess
import re

files_to_fix = [
    "frontend/lib/core/widgets/main_layout/cashbox_modal.dart",
    "frontend/lib/core/widgets/main_layout/mynix_app_bar.dart",
    "frontend/lib/features/analytics/view/analytics_dashboard_screen.dart",
    "frontend/lib/features/inventory/bloc/document_bloc.dart",
    "frontend/lib/features/inventory/bloc/document_event.dart",
    "frontend/lib/features/inventory/repository/inventory_repository.dart",
    "frontend/lib/features/inventory/view/warehouse_screen.dart",
    "frontend/lib/features/inventory/view/widgets/bulk_add/dish_row.dart",
    "frontend/lib/features/inventory/view/widgets/bulk_add/ingredient_row.dart",
    "frontend/lib/features/inventory/view/widgets/bulk_add/retail_row.dart",
    "frontend/lib/features/inventory/view/widgets/bulk_add_modal.dart",
    "frontend/lib/features/inventory/view/widgets/bulk_receipt_view.dart",
    "frontend/lib/features/inventory/view/widgets/menu_manager_items_grid.dart",
    "frontend/lib/features/inventory/view/widgets/retail_product_modal.dart",
    "frontend/lib/features/inventory/view/widgets/warehouse/dialogs/receive_document_dialog.dart",
    "frontend/lib/features/inventory/view/widgets/warehouse/documents_journal_tab.dart",
    "frontend/lib/features/inventory/view/widgets/warehouse/stock_tab.dart",
    "frontend/lib/features/kitchen/view/kds_board.dart",
    "frontend/lib/features/menu/view/catalog_screen.dart",
    "frontend/lib/features/menu/view/widgets/catalog/catalog_browser_tab.dart",
    "frontend/lib/features/menu/view/widgets/catalog/catalog_dialogs.dart",
    "frontend/lib/features/menu/view/widgets/catalog/items/menu_grid_item.dart",
    "frontend/lib/features/menu/view/widgets/catalog/items/menu_list_item.dart",
    "frontend/lib/features/pos/repository/menu_repository.dart",
    "frontend/lib/features/pos/view/pos_screen.dart",
    "frontend/lib/features/pos/view/widgets/components/pos_cart_header.dart",
    "frontend/lib/features/pos/view/widgets/components/pos_cart_item_tile.dart",
    "frontend/lib/features/pos/view/widgets/components/pos_checkout_panel.dart",
    "frontend/lib/features/pos/view/widgets/components/pos_item_card.dart",
    "frontend/lib/features/settings/view/settings_screen.dart"
]

def get_head_content(filepath):
    result = subprocess.run(['git', 'show', f'HEAD:{filepath}'], capture_output=True)
    if result.returncode != 0:
        return None
    return result.stdout.decode('utf-8', errors='replace')

def get_corrupted(text):
    # This simulates what PowerShell Get-Content did when it read UTF-8 as ANSI
    return text.encode('utf-8').decode('cp1252', errors='replace')

def main():
    for filepath in files_to_fix:
        print(f"Fixing Cyrillic in {filepath}...")
        head_content = get_head_content(filepath)
        if not head_content:
            continue
            
        # Extract all Cyrillic words/phrases from HEAD
        # Match any string of characters that includes at least one Cyrillic letter
        # We'll match maximal sequences of Cyrillic letters, spaces, and punctuation
        cyrillic_phrases = set()
        for match in re.finditer(r'[\u0400-\u04FF][\u0400-\u04FF\s\.,!\?:\-0-9]*', head_content):
            phrase = match.group(0).strip()
            if phrase and any('\u0400' <= c <= '\u04FF' for c in phrase):
                # Only take ones that actually contain cyrillic
                cyrillic_phrases.add(phrase)
                
        # Sort by length descending to replace longer phrases first (avoids substring issues)
        cyrillic_phrases = sorted(list(cyrillic_phrases), key=len, reverse=True)
        
        try:
            with open(filepath, 'r', encoding='utf-8-sig') as f:
                content = f.read()
        except:
            continue
            
        original_content = content
        
        for phrase in cyrillic_phrases:
            corrupted = get_corrupted(phrase)
            if corrupted in content:
                content = content.replace(corrupted, phrase)
                
        # Also let's fix any remaining stray characters just in case
        # like "Ð" -> "" if it's completely isolated, but it's safer to just rely on phrase replacement.
        
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"  Fixed!")
        else:
            print(f"  No replacements made.")

if __name__ == '__main__':
    main()
