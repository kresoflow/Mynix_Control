import os
import subprocess

def get_modified_files():
    result = subprocess.run(['git', 'status', '--porcelain'], capture_output=True, text=True)
    files = []
    for line in result.stdout.split('\n'):
        if line.startswith(' M ') or line.startswith('M '):
            files.append(line[3:])
    return files

def has_meaningful_changes(filepath):
    # Check if the git diff contains anything other than the package rename and the encoding corruption
    result = subprocess.run(['git', 'diff', filepath], capture_output=True, text=True, encoding='utf-8', errors='replace')
    diff_lines = result.stdout.split('\n')
    
    for line in diff_lines:
        if line.startswith('+') and not line.startswith('+++'):
            # It's an addition
            content = line[1:]
            # Ignore the BOM
            if content.startswith('\ufeff'):
                content = content[1:]
            
            # If it's a rename of package
            if 'mynix_frontend' in content:
                continue
            
            # If it contains corrupted cyrillic (like Ð)
            if 'Ð' in content or 'Ñ' in content or 'Î' in content or 'Ï' in content or 'â' in content:
                continue
                
            # If it's empty
            if not content.strip():
                continue
                
            # If it's anything else, this file has meaningful changes!
            return True
            
        elif line.startswith('-') and not line.startswith('---'):
            # It's a deletion
            content = line[1:]
            if 'retail_os_frontend' in content:
                continue
                
            # If it contains valid cyrillic
            if any('\u0400' <= c <= '\u04FF' for c in content):
                continue
                
            if not content.strip():
                continue
                
            return True
            
    return False

def main():
    files = get_modified_files()
    for file in files:
        if not file.endswith('.dart'): continue
        if not has_meaningful_changes(file):
            print(f"Restoring safe file: {file}")
            subprocess.run(['git', 'checkout', '--', file])
            # Now properly apply the rename
            with open(file, 'r', encoding='utf-8') as f:
                content = f.read()
            content = content.replace('retail_os_frontend', 'mynix_frontend')
            with open(file, 'w', encoding='utf-8') as f:
                f.write(content)
        else:
            print(f"MANUAL FIX NEEDED (has logic changes): {file}")

if __name__ == '__main__':
    main()
