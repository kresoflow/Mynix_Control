import os
import subprocess
import re

def get_head_content(filepath):
    result = subprocess.run(['git', 'show', f'HEAD:{filepath}'], capture_output=True)
    if result.returncode != 0:
        return None
    return result.stdout.decode('utf-8', errors='replace')

def get_modified_files():
    result = subprocess.run(['git', 'status', '--porcelain'], capture_output=True, text=True)
    files = []
    for line in result.stdout.split('\n'):
        if line.startswith(' M ') or line.startswith('M '):
            files.append(line[3:])
    return files

def has_logic_changes(filepath):
    head_content = get_head_content(filepath)
    if head_content is None:
        return True # New file, consider it logic change
        
    try:
        with open(filepath, 'r', encoding='utf-8-sig') as f:
            curr_content = f.read()
    except Exception:
        return True

    # 1. Reverse the package rename in curr_content for comparison
    curr_content_reverted = curr_content.replace('mynix_frontend', 'retail_os_frontend')
    
    # 2. Extract all strings from HEAD (both single and double quotes)
    # Actually, let's just strip ALL strings (text between ' or ") from both head and curr!
    # Because Cyrillic text is only inside strings (or comments).
    # If the CODE is exactly the same, then there are no logic changes!
    
    def strip_strings_and_comments(text):
        # Remove comments
        text = re.sub(r'//.*', '', text)
        text = re.sub(r'/\*.*?\*/', '', text, flags=re.DOTALL)
        # Remove strings
        text = re.sub(r"'[^']*'", "''", text)
        text = re.sub(r'"[^"]*"', '""', text)
        # Normalize whitespace
        text = re.sub(r'\s+', ' ', text).strip()
        return text

    head_code = strip_strings_and_comments(head_content)
    curr_code = strip_strings_and_comments(curr_content_reverted)
    
    return head_code != curr_code

def main():
    files = get_modified_files()
    logic_changed_files = []
    
    for file in files:
        if not file.endswith('.dart'): continue
        if not has_logic_changes(file):
            print(f"Restoring safe file: {file}")
            subprocess.run(['git', 'checkout', '--', file])
            # Now properly apply the rename
            with open(file, 'r', encoding='utf-8') as f:
                content = f.read()
            content = content.replace('retail_os_frontend', 'mynix_frontend')
            with open(file, 'w', encoding='utf-8') as f:
                f.write(content)
        else:
            logic_changed_files.append(file)
            print(f"MANUAL FIX NEEDED (has logic changes): {file}")
            
    print("\nFiles that need manual Cyrillic string fixing because they have logic changes:")
    for f in logic_changed_files:
        print(f)

if __name__ == '__main__':
    main()
