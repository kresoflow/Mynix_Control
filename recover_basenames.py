import os
import json

def recover_basenames():
    zero_byte_files = [
        r'D:\Mynix_Control\frontend\lib\features\inventory\view\widgets\warehouse\ingredient_tab.dart',
        r'D:\Mynix_Control\frontend\lib\features\inventory\view\widgets\warehouse\recipe_details_panel.dart',
        r'D:\Mynix_Control\frontend\lib\features\inventory\view\widgets\warehouse\recipe_menu_list.dart',
        r'D:\Mynix_Control\frontend\lib\features\inventory\view\widgets\warehouse\recipe_tab.dart',
        r'D:\Mynix_Control\frontend\lib\features\inventory\view\widgets\warehouse\dialogs\add_ingredient_to_recipe_dialog.dart',
        r'D:\Mynix_Control\frontend\lib\features\inventory\view\widgets\warehouse\dialogs\create_ingredient_dialog.dart',
        r'D:\Mynix_Control\frontend\lib\features\inventory\view\widgets\warehouse\dialogs\recipe_bulk_edit_dialog.dart',
        r'D:\Mynix_Control\frontend\lib\features\pos\view\pos_screen.dart'
    ]
    
    transcript_path = r'C:\Users\Admin_Ax\.gemini\antigravity\brain\494aa6c3-a606-41b4-9264-8dabd09b55b8\.system_generated\logs\transcript_full.jsonl'
    recovered = {}
    
    with open(transcript_path, 'r', encoding='utf-8') as f:
        for line in f:
            try:
                step = json.loads(line)
                if 'tool_calls' in step:
                    for call in step['tool_calls']:
                        if call['name'] in ['write_to_file', 'replace_file_content']:
                            args = call['args']
                            target = args.get('TargetFile', '')
                            code = args.get('CodeContent', '') if call['name'] == 'write_to_file' else args.get('ReplacementContent', '')
                            
                            for zbf in zero_byte_files:
                                basename = os.path.basename(zbf)
                                if basename in target:
                                    if call['name'] == 'replace_file_content' and args.get('TargetContent', '') != '':
                                        continue # skip partial replacements
                                    recovered[zbf] = code
            except:
                pass
                
    for zbf, code in recovered.items():
        with open(zbf, 'w', encoding='utf-8') as f:
            f.write(code)
        print(f"Recovered: {zbf}")

if __name__ == '__main__':
    recover_basenames()
