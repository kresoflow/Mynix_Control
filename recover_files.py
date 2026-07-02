import os
import json
import glob

def recover_files():
    # Find all 0-byte dart files
    zero_byte_files = [f for f in glob.glob('frontend/lib/**/*.dart', recursive=True) if os.path.getsize(f) == 0]
    
    print(f"Found {len(zero_byte_files)} zero-byte files to recover.")
    
    transcript_path = r'C:\Users\Admin_Ax\.gemini\antigravity\brain\494aa6c3-a606-41b4-9264-8dabd09b55b8\.system_generated\logs\transcript_full.jsonl'
    
    recovered = {}
    
    # Read the transcript and find the last write_to_file for each
    with open(transcript_path, 'r', encoding='utf-8') as f:
        for line in f:
            try:
                step = json.loads(line)
                if 'tool_calls' in step:
                    for call in step['tool_calls']:
                        if call['name'] == 'write_to_file':
                            args = call['args']
                            target_file = args.get('TargetFile', '').replace('\\', '/')
                            code = args.get('CodeContent', '')
                            
                            # check if target_file ends with any of the zero_byte_files
                            for zbf in zero_byte_files:
                                zbf_normalized = zbf.replace('\\', '/')
                                if zbf_normalized in target_file or target_file.endswith(zbf_normalized.split('frontend/')[-1]):
                                    recovered[zbf] = code
            except:
                pass
                
    for zbf, code in recovered.items():
        with open(zbf, 'w', encoding='utf-8') as f:
            f.write(code)
        print(f"Recovered: {zbf}")
        
    print(f"Successfully recovered {len(recovered)} out of {len(zero_byte_files)} files.")

if __name__ == '__main__':
    recover_files()
