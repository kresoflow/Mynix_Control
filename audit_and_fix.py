import os
import glob
import re

def main():
    print("Starting full audit and fix...")
    
    # Files to check
    dart_files = glob.glob('frontend/lib/**/*.dart', recursive=True) + \
                 glob.glob('frontend/test/**/*.dart', recursive=True) + \
                 ['frontend/main.dart', 'frontend/pubspec.yaml', 'frontend/web/index.html', 'frontend/web/manifest.json']
                 
    bom_stripped = 0
    package_renamed = 0
    corrupted_found = 0
    
    for filepath in dart_files:
        if not os.path.exists(filepath): continue
        
        # Check for BOM
        with open(filepath, 'rb') as f:
            raw_bytes = f.read()
            
        has_bom = raw_bytes.startswith(b'\xef\xbb\xbf')
        
        try:
            content = raw_bytes.decode('utf-8-sig')
        except:
            continue
            
        original_content = content
        
        # 1. Rename package
        if 'retail_os_frontend' in content:
            content = content.replace('retail_os_frontend', 'mynix_frontend')
            package_renamed += 1
            
        # Rename title in index.html
        if filepath == 'frontend/web/index.html' or filepath == 'frontend/web/manifest.json':
            content = content.replace('retail_os', 'mynix')
            content = content.replace('Retail OS', 'Mynix Control')
            
        # 2. Check for remaining corruption
        if 'Ð' in content or 'Ñ' in content or 'Î' in content or 'Ï' in content or 'â' in content:
            # We have left over corruption!
            corrupted_found += 1
            print(f"CORRUPTION STILL IN: {filepath}")
            # Print first corrupted line
            for line in content.split('\n'):
                if 'Ð' in line or 'Ñ' in line:
                    print(f"  -> {line.strip()}")
                    break
                    
        # 3. Save if changed or had BOM
        if content != original_content or has_bom:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            if has_bom:
                bom_stripped += 1
                
    print(f"\nAudit complete!")
    print(f"BOMs stripped: {bom_stripped}")
    print(f"Package renamed in {package_renamed} files")
    print(f"Files still corrupted: {corrupted_found}")

if __name__ == '__main__':
    main()
