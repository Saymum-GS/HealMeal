import os
import re

lib_dir = r"d:\HealMeal\lib"

# Matches things like 6.w0, 1.w50, 4.h0
malformed_pat = re.compile(r'(\d+)\.(w|h|sp|r)(\d+)')

files_modified = 0

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            orig_content = content
            
            def fix_match(m):
                # 6.w0 -> 60.w
                return f"{m.group(1)}{m.group(3)}.{m.group(2)}"
                
            content = malformed_pat.sub(fix_match, content)
            
            if content != orig_content:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(content)
                files_modified += 1

print(f"Fixed {files_modified} files with malformed regex.")
