import os
import re

lib_dir = r"d:\HealMeal\lib"

expanded_in_scroll = 0
hardcoded_sizes = 0

def check_file(path):
    global expanded_in_scroll, hardcoded_sizes
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Check for hardcoded sizes (e.g., width: 100, height: 50.0)
    # Exclude those that use ScreenUtil (.w, .h, .sp, .r)
    # Exclude 0, double.infinity
    size_pattern = re.compile(r'(width|height|fontSize):\s*([1-9][0-9]*(?:\.[0-9]+)?)(?![\.\w])')
    matches = size_pattern.finditer(content)
    
    file_issues = []
    
    for match in matches:
        val = match.group(2)
        if val != '0' and val != 'double.infinity':
            file_issues.append(f"Line offset near: {match.group(0)}")
            hardcoded_sizes += 1
            
    if file_issues:
        print(f"\n{os.path.relpath(path, lib_dir)} has potential hardcoded sizes:")
        for issue in file_issues:
            print(f"  - {issue}")

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            check_file(os.path.join(root, file))

print(f"\nTotal hardcoded sizes found: {hardcoded_sizes}")
