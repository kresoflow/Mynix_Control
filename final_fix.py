import os
import glob
import re
import subprocess

def powershell_ansi_to_utf8(b):
    try:
        return bytes([b]).decode('cp1252')
    except UnicodeDecodeError:
        return chr(b)

def get_corrupted(text):
    return ''.join(powershell_ansi_to_utf8(b) for b in text.encode('utf-8'))

def get_head_files():
    result = subprocess.run(['git', 'ls-tree', '-r', 'HEAD', '--name-only'], capture_output=True, text=True)
    return [f for f in result.stdout.split('\n') if f.endswith('.dart')]

def get_head_content(filepath):
    result = subprocess.run(['git', 'show', f'HEAD:{filepath}'], capture_output=True)
    if result.returncode != 0:
        return None
    return result.stdout.decode('utf-8', errors='replace')

def main():
    print("Building precise mapping from HEAD...")
    head_files = get_head_files()
    mapping = {}
    
    for filepath in head_files:
        content = get_head_content(filepath)
        if not content: continue
        
        for match in re.finditer(r'[\u0400-\u04FF][\u0400-\u04FF\s\.,!\?:\-0-9()]*', content):
            phrase = match.group(0).strip()
            if phrase and any('\u0400' <= c <= '\u04FF' for c in phrase):
                corr = get_corrupted(phrase)
                if corr != phrase:
                    mapping[corr] = phrase
                    
    # Manual fixes
    mapping[get_corrupted('Z-отчет')] = 'Z-отчет'
    mapping[get_corrupted('ВОЙТИ')] = 'ВОЙТИ'
    mapping[get_corrupted('Добро пожаловать')] = 'Добро пожаловать'
    
    # Sort keys by length descending
    sorted_corrupted = sorted(mapping.keys(), key=len, reverse=True)
    
    print(f"Built mapping with {len(mapping)} phrases.")
    
    dart_files = glob.glob('frontend/lib/**/*.dart', recursive=True) + \
                 glob.glob('frontend/test/**/*.dart', recursive=True) + \
                 ['frontend/main.dart', 'frontend/pubspec.yaml', 'frontend/web/index.html', 'frontend/web/manifest.json']
                 
    for filepath in dart_files:
        if not os.path.exists(filepath): continue
        
        with open(filepath, 'rb') as f:
            raw_bytes = f.read()
            
        has_bom = raw_bytes.startswith(b'\xef\xbb\xbf')
        
        try:
            content = raw_bytes.decode('utf-8-sig')
        except:
            continue
            
        original_content = content
        
        if filepath.endswith('.dart'):
            for corr in sorted_corrupted:
                if corr in content:
                    content = content.replace(corr, mapping[corr])
                    
        # Rename title in index.html
        if filepath == 'frontend/web/index.html' or filepath == 'frontend/web/manifest.json':
            content = content.replace('retail_os', 'mynix')
            content = content.replace('Retail OS', 'Mynix Control')
            content = content.replace('retail_os_frontend', 'mynix_frontend')
            
        # Clean up any missed 'retail_os_frontend' in dart files just in case
        content = content.replace('retail_os_frontend', 'mynix_frontend')
        
        if content != original_content or has_bom:
            # Save WITHOUT BOM
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            if has_bom:
                print(f"  Stripped BOM from: {filepath}")
            if content != original_content:
                print(f"  Fixed content in: {filepath}")

    print("Final fix complete!")

if __name__ == '__main__':
    main()
