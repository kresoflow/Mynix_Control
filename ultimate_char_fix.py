import os
import glob

def powershell_ansi_to_utf8(b):
    try:
        return bytes([b]).decode('cp1252')
    except UnicodeDecodeError:
        return chr(b)

def get_corrupted_char(c):
    return ''.join(powershell_ansi_to_utf8(b) for b in c.encode('utf-8'))

def main():
    print("Building character-level mapping...")
    mapping = {}
    
    # Generate all Russian Cyrillic characters
    chars = []
    # А-Я
    chars.extend(chr(i) for i in range(0x0410, 0x0430))
    # а-я
    chars.extend(chr(i) for i in range(0x0430, 0x0450))
    # Ё, ё
    chars.extend(['Ё', 'ё'])
    # Other symbols like № if used
    chars.append('№')
    
    for c in chars:
        corr = get_corrupted_char(c)
        if corr != c:
            mapping[corr] = c
            
    # Sort keys by length descending just in case (though all should be length 2)
    sorted_corrupted = sorted(mapping.keys(), key=len, reverse=True)
    
    print(f"Built mapping for {len(mapping)} characters.")
    
    dart_files = glob.glob('frontend/lib/**/*.dart', recursive=True) + \
                 glob.glob('frontend/test/**/*.dart', recursive=True)
                 
    fixed_files = 0
                 
    for filepath in dart_files:
        if not os.path.exists(filepath): continue
        
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
        except:
            continue
            
        original_content = content
        
        for corr in sorted_corrupted:
            if corr in content:
                content = content.replace(corr, mapping[corr])
                
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            fixed_files += 1
            print(f"  Fixed characters in: {filepath}")

    print(f"Done! Fixed {fixed_files} files.")

if __name__ == '__main__':
    main()
