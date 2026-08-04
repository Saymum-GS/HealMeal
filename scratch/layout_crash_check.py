import os
import re

lib_dir = r"d:\HealMeal\lib"

def check_layout_crashes(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    issues = []
    
    # Check if SingleChildScrollView contains Expanded or Spacer
    if 'SingleChildScrollView' in content:
        # Simplistic check: if both exist in the file, we flag it for manual review
        if 'Expanded(' in content or 'Spacer(' in content or 'Flexible(' in content:
            issues.append("Contains SingleChildScrollView AND (Expanded/Flexible/Spacer) - possible RenderFlex crash.")
            
    # Check for shrinkWrap: true in nested ListViews
    if 'ListView.builder' in content or 'ListView(' in content:
        if 'shrinkWrap: true' in content and 'NeverScrollableScrollPhysics' not in content:
            issues.append("ListView with shrinkWrap: true might be missing physics: NeverScrollableScrollPhysics()")

    if issues:
        print(f"\n{os.path.relpath(path, lib_dir)}:")
        for issue in issues:
            print(f"  - {issue}")

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            check_layout_crashes(os.path.join(root, file))
