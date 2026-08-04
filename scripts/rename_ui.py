import os

replacements = {
    "'Healthcare products'": "'Healthcare medicines'",
    "'Customer Support Executive|Full Time|Support|Remote|Help customers with ordering, tracking, and product questions.'": "'Customer Support Executive|Full Time|Support|Remote|Help customers with ordering, tracking, and medicine questions.'",
    "'Products marked as prescription-only require valid prescription handling before checkout can proceed.'": "'Medicines marked as prescription-only require valid prescription handling before checkout can proceed.'",
    "'Temperature-sensitive medicines and certain medical products may be non-returnable unless quality issues are verified.'": "'Temperature-sensitive medicines and certain medical items may be non-returnable unless quality issues are verified.'",
    "'Customers may be asked for AppOrder details, photos, and product packaging information to review a claim.'": "'Customers may be asked for AppOrder details, photos, and medicine packaging information to review a claim.'",
    "'Search products or tests'": "'Search medicines or tests'",
    "'Search products by name...'": "'Search medicines by name...'",
    '"No products found for this filter."': '"No medicines found for this filter."',
    '"Delete Product?"': '"Delete Medicine?"',
    "'Edit Product'": "'Edit Medicine'",
    "'Add New Product'": "'Add New Medicine'",
    "'Product Name'": "'Medicine Name'",
    "'Featured Product'": "'Featured Medicine'",
    "'Update Product'": "'Update Medicine'",
    "'Create Product'": "'Create Medicine'",
    "'No low stock products.'": "'No low stock medicines.'",
    "'No out of stock products.'": "'No out of stock medicines.'",
    "'Search Products'": "'Search Medicines'",
    "'No products found.'": "'No medicines found.'",
    "'Add Product'": "'Add Medicine'",
    "'Products'": "'Medicines'",
    "'Failed to load products:": "'Failed to load medicines:",
    "'Product not found'": "'Medicine not found'",
    "'No products found for this brand'": "'No medicines found for this brand'",
    "'Please verify the order items and total amount match the expected product prices before confirming.'": "'Please verify the order items and total amount match the expected medicine prices before confirming.'",
    "'All Products'": "'All Medicines'",
    "'Product Review'": "'Medicine Review'",
    "'Notified Products'": "'Notified Medicines'",
    "'Suggest a Product'": "'Suggest a Medicine'",
    "'Product Reviews'": "'Medicine Reviews'",
    "'Browse Products'": "'Browse Medicines'",
    "'Notify Me - Products'": "'Notify Me - Medicines'",
    "'No products in your notify list.'": "'No medicines in your notify list.'",
    "'Product / Medicine Name'": "'Medicine Name'",
    "'Manage Products'": "'Manage Medicines'",
    "'Product deleted successfully'": "'Medicine deleted successfully'",
    "'Error deleting product: ": "'Error deleting medicine: ",
    "'Recommended Products'": "'Recommended Medicines'",
    "'Products assigned to this category will become uncategorised. This cannot be undone.'": "'Medicines assigned to this category will become uncategorised. This cannot be undone.'",
    '"Are you sure you want to delete ${product.drugName}? This action cannot be undone."': '"Are you sure you want to delete ${product.drugName}? This action cannot be undone."'
}

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    new_content = content
    for old, new in replacements.items():
        new_content = new_content.replace(old, new)
        
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
