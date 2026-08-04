import os
import re

lib_dir = r"d:\HealMeal\lib"

# We want to replace standard Divider uses with SizedBox or remove them.
# For separatorBuilder: (_, __) => Divider(...) -> separatorBuilder: (_, __) => SizedBox(height: 8.h)
# For Divider(height: X) -> SizedBox(height: X)
# For Divider() -> SizedBox(height: 8.h)

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    # Replace separatorBuilder: (_, __) => Divider(...)
    # with separatorBuilder: (_, __) => SizedBox(height: 12.h)
    content = re.sub(
        r'separatorBuilder:\s*\(\s*_\s*,\s*__\s*\)\s*=>\s*Divider\([^)]*\)',
        r'separatorBuilder: (_, __) => SizedBox(height: 12.h)',
        content
    )
    
    # Also separatorBuilder: (context, index) => Divider(...)
    content = re.sub(
        r'separatorBuilder:\s*\(\s*[^,]+,\s*[^)]+\)\s*=>\s*Divider\([^)]*\)',
        r'separatorBuilder: (context, index) => SizedBox(height: 12.h)',
        content
    )

    # Replace Expanded(child: Divider(...)) with SizedBox.shrink() because it was probably an Or divider
    content = re.sub(
        r'Expanded\(\s*child:\s*Divider\([^)]*\)\s*\)',
        r'Expanded(child: SizedBox.shrink())',
        content
    )

    # Replace remaining Divider(height: X...) with SizedBox(height: X)
    # We will just capture the height if it exists.
    def divider_replacer(match):
        inner = match.group(1)
        height_match = re.search(r'height:\s*([^,]+)', inner)
        if height_match:
            h = height_match.group(1)
            return f"SizedBox(height: {h})"
        else:
            return "SizedBox(height: 12.h)"

    content = re.sub(r'Divider\(([^)]*)\)', divider_replacer, content)

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart"):
            process_file(os.path.join(root, file))
