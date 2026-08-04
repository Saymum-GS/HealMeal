import os
import re

lib_dir = r"d:\HealMeal\lib"

# Regex patterns
# Match height: 10, height: 10.5, but ignore if followed by .h, .w, .sp, .r or already inside AppSpacing
height_pat = re.compile(r'(height:\s*)([3-9]|[1-9][0-9]+)(\.[0-9]+)?(?!\s*\.\w)(?!\s*\.h)(?!\s*\.sp)(?!\s*\.r)')
width_pat = re.compile(r'(width:\s*)([3-9]|[1-9][0-9]+)(\.[0-9]+)?(?!\s*\.\w)(?!\s*\.h)(?!\s*\.sp)(?!\s*\.r)')
size_pat = re.compile(r'(size:\s*)([3-9]|[1-9][0-9]+)(\.[0-9]+)?(?!\s*\.\w)(?!\s*\.h)(?!\s*\.sp)(?!\s*\.r)')
font_pat = re.compile(r'(fontSize:\s*)([1-9][0-9]+)(\.[0-9]+)?(?!\s*\.\w)(?!\s*\.h)(?!\s*\.sp)(?!\s*\.r)')
edge_all_pat = re.compile(r'(EdgeInsets\.all\(\s*)([1-9][0-9]+)(\.[0-9]+)?(?!\s*\.\w)(?!\s*\.h)(?!\s*\.sp)(?!\s*\.r)')
edge_sym_v_pat = re.compile(r'(vertical:\s*)([1-9][0-9]+)(\.[0-9]+)?(?!\s*\.\w)(?!\s*\.h)(?!\s*\.sp)(?!\s*\.r)')
edge_sym_h_pat = re.compile(r'(horizontal:\s*)([1-9][0-9]+)(\.[0-9]+)?(?!\s*\.\w)(?!\s*\.h)(?!\s*\.sp)(?!\s*\.r)')
edge_only_t_pat = re.compile(r'(top:\s*)([1-9][0-9]+)(\.[0-9]+)?(?!\s*\.\w)(?!\s*\.h)(?!\s*\.sp)(?!\s*\.r)')
edge_only_b_pat = re.compile(r'(bottom:\s*)([1-9][0-9]+)(\.[0-9]+)?(?!\s*\.\w)(?!\s*\.h)(?!\s*\.sp)(?!\s*\.r)')
edge_only_l_pat = re.compile(r'(left:\s*)([1-9][0-9]+)(\.[0-9]+)?(?!\s*\.\w)(?!\s*\.h)(?!\s*\.sp)(?!\s*\.r)')
edge_only_r_pat = re.compile(r'(right:\s*)([1-9][0-9]+)(\.[0-9]+)?(?!\s*\.\w)(?!\s*\.h)(?!\s*\.sp)(?!\s*\.r)')

def replace_with_h(match):
    num = match.group(2) + (match.group(3) or '')
    if num in ['0']: return match.group(0)
    return f"{match.group(1)}{num}.h"

def replace_with_w(match):
    num = match.group(2) + (match.group(3) or '')
    if num in ['0']: return match.group(0)
    return f"{match.group(1)}{num}.w"

def replace_with_sp(match):
    num = match.group(2) + (match.group(3) or '')
    if num in ['0']: return match.group(0)
    return f"{match.group(1)}{num}.sp"

def replace_with_r(match):
    num = match.group(2) + (match.group(3) or '')
    if num in ['0']: return match.group(0)
    return f"{match.group(1)}{num}.r"

files_modified = 0

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()

            orig_content = content
            content = height_pat.sub(replace_with_h, content)
            content = edge_sym_v_pat.sub(replace_with_h, content)
            content = edge_only_t_pat.sub(replace_with_h, content)
            content = edge_only_b_pat.sub(replace_with_h, content)
            
            content = width_pat.sub(replace_with_w, content)
            content = edge_sym_h_pat.sub(replace_with_w, content)
            content = edge_only_l_pat.sub(replace_with_w, content)
            content = edge_only_r_pat.sub(replace_with_w, content)
            
            content = size_pat.sub(replace_with_w, content) # size -> .w
            content = font_pat.sub(replace_with_sp, content)
            content = edge_all_pat.sub(replace_with_w, content)

            if content != orig_content:
                # Need screenutil import
                if "import 'package:flutter_screenutil/flutter_screenutil.dart';" not in content:
                    lines = content.split('\n')
                    # find last import
                    last_import = -1
                    for i, l in enumerate(lines):
                        if l.startswith("import '"):
                            last_import = i
                    if last_import != -1:
                        lines.insert(last_import + 1, "import 'package:flutter_screenutil/flutter_screenutil.dart';")
                    else:
                        lines.insert(0, "import 'package:flutter_screenutil/flutter_screenutil.dart';")
                    content = '\n'.join(lines)
                
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(content)
                files_modified += 1

print(f"Modified {files_modified} files to be responsive.")
