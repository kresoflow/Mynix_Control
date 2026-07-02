import os
import glob
import re

def main():
    dart_files = glob.glob('frontend/lib/**/*.dart', recursive=True) + glob.glob('frontend/test/**/*.dart', recursive=True)
    fixed = 0
    
    for filepath in dart_files:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        original = content
        
        # 1. Fix old package name
        content = content.replace('retail_os_frontend', 'mynix_frontend')
        
        # 2. Fix use_build_context_synchronously naive fixes
        
        if content != original:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            fixed += 1
            
    print(f"Fixed {fixed} files.")

if __name__ == '__main__':
    main()
