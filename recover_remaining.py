import os
import subprocess
import json
import glob

def recover_remaining():
    zero_byte_files = [f for f in glob.glob('frontend/lib/**/*.dart', recursive=True) if os.path.getsize(f) == 0]
    print(f"Remaining 0-byte files: {len(zero_byte_files)}")
    
    # Try git checkout first
    for zbf in zero_byte_files:
        print(f"Trying git checkout for {zbf}")
        subprocess.run(['git', 'checkout', 'HEAD', '--', zbf], cwd='frontend')
        
    # Check what is still 0 bytes
    zero_byte_files = [f for f in glob.glob('frontend/lib/**/*.dart', recursive=True) if os.path.getsize(f) == 0]
    print(f"Remaining after git checkout: {len(zero_byte_files)}")
    
    if len(zero_byte_files) == 0:
        return
        
    # For the rest, search transcript for replace_file_content
    transcript_path = r'C:\Users\Admin_Ax\.gemini\antigravity\brain\494aa6c3-a606-41b4-9264-8dabd09b55b8\.system_generated\logs\transcript_full.jsonl'
    recovered = {}
    
    with open(transcript_path, 'r', encoding='utf-8') as f:
        for line in f:
            try:
                step = json.loads(line)
                if 'tool_calls' in step:
                    for call in step['tool_calls']:
                        if call['name'] == 'replace_file_content':
                            args = call['args']
                            target_file = args.get('TargetFile', '').replace('\\', '/')
                            replacement = args.get('ReplacementContent', '')
                            
                            for zbf in zero_byte_files:
                                zbf_normalized = zbf.replace('\\', '/')
                                if zbf_normalized in target_file or target_file.endswith(zbf_normalized.split('frontend/')[-1]):
                                    # This might just be a chunk, but if the file was created this way, it might be the whole file
                                    # Actually, if the file was created via replace_file_content with TargetContent="", ReplacementContent contains the full code!
                                    if args.get('TargetContent', '') == '':
                                        recovered[zbf] = replacement
            except:
                pass
                
    for zbf, code in recovered.items():
        with open(zbf, 'w', encoding='utf-8') as f:
            f.write(code)
        print(f"Recovered from transcript: {zbf}")
        
    zero_byte_files = [f for f in glob.glob('frontend/lib/**/*.dart', recursive=True) if os.path.getsize(f) == 0]
    print(f"Final remaining 0-byte files: {len(zero_byte_files)}")

if __name__ == '__main__':
    recover_remaining()
