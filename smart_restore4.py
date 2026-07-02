import os
import subprocess
import glob
import re

def get_corrupted(text):
    try:
        return text.encode('utf-8').decode('cp1252', errors='replace')
    except:
        return text

def get_head_files():
    result = subprocess.run(['git', 'ls-tree', '-r', 'HEAD', '--name-only'], capture_output=True, text=True)
    return [f for f in result.stdout.split('\n') if f.endswith('.dart')]

def get_head_content(filepath):
    result = subprocess.run(['git', 'show', f'HEAD:{filepath}'], capture_output=True)
    if result.returncode != 0:
        return None
    return result.stdout.decode('utf-8', errors='replace')

def main():
    print("Building mapping from HEAD...")
    head_files = get_head_files()
    mapping = {}
    
    for filepath in head_files:
        content = get_head_content(filepath)
        if not content: continue
        
        # Find all cyrillic sequences
        for match in re.finditer(r'[\u0400-\u04FF][\u0400-\u04FF\s\.,!\?:\-0-9()]*', content):
            phrase = match.group(0).strip()
            if phrase and any('\u0400' <= c <= '\u04FF' for c in phrase):
                corr = get_corrupted(phrase)
                if corr != phrase:
                    mapping[corr] = phrase
                    
    # Also add some manual fixes just in case it missed anything
    mapping[get_corrupted('Z-отчет')] = 'Z-отчет'
    mapping[get_corrupted('ВОЙТИ')] = 'ВОЙТИ'
    
    print(f"Built mapping with {len(mapping)} phrases.")
    
    # Sort keys by length descending
    sorted_corrupted = sorted(mapping.keys(), key=len, reverse=True)
    
    print("Applying fixes to all working directory files...")
    all_dart_files = glob.glob('frontend/lib/**/*.dart', recursive=True) + glob.glob('frontend/test/**/*.dart', recursive=True) + ['frontend/main.dart']
    
    for filepath in all_dart_files:
        if not os.path.exists(filepath): continue
        
        try:
            with open(filepath, 'r', encoding='utf-8-sig') as f:
                content = f.read()
        except:
            continue
            
        original_content = content
        
        for corr in sorted_corrupted:
            if corr in content:
                content = content.replace(corr, mapping[corr])
                
        # Handle some leftovers
        # Sometimes there's a stray Ð that wasn't part of a matched phrase
        # But we shouldn't indiscriminately delete it, it's safer to just rely on the mapping.
        
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"  Fixed: {filepath}")

    print("Done!")

if __name__ == '__main__':
    main()
