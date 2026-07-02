import os
import glob

def fix_file(path):
    with open(path, 'rb') as f:
        raw_bytes = f.read()
    
    try:
        text = raw_bytes.decode('utf-8-sig')
    except UnicodeDecodeError:
        return # Not valid utf-8 anymore
    
    # Try to encode back to original bytes using windows-1252
    try:
        orig_bytes = text.encode('windows-1252')
        # Now try to decode as utf-8
        fixed_text = orig_bytes.decode('utf-8')
        with open(path, 'w', encoding='utf-8') as f:
            f.write(fixed_text)
        print(f"Fixed {path} using windows-1252")
        return
    except (UnicodeEncodeError, UnicodeDecodeError):
        pass

    # Try to encode back using cp1251
    try:
        orig_bytes = text.encode('cp1251')
        fixed_text = orig_bytes.decode('utf-8')
        with open(path, 'w', encoding='utf-8') as f:
            f.write(fixed_text)
        print(f"Fixed {path} using cp1251")
        return
    except (UnicodeEncodeError, UnicodeDecodeError):
        pass

if __name__ == "__main__":
    for filepath in glob.glob('frontend/lib/**/*.dart', recursive=True):
        fix_file(filepath)
    # Also fix pubspec
    fix_file('frontend/pubspec.yaml')
