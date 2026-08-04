import time
import firebase_admin
from firebase_admin import credentials, firestore
from concurrent.futures import ThreadPoolExecutor

print("Initializing Firebase Admin SDK...")
cred = credentials.Certificate(r"D:\HealMeal\healmeal-1-firebase-adminsdk-fbsvc-466f1d1cfb.json")
try:
    firebase_admin.initialize_app(cred)
except ValueError:
    pass # Already initialized

db = firestore.client()
products_ref = db.collection('products')

print("Fetching all products from Firestore...")
start_time = time.time()

# Selecting only countInStock makes streaming 18k+ documents extremely fast (~2-3 seconds)
docs = list(products_ref.select(['countInStock']).stream())

fetch_time = time.time() - start_time
total_products = len(docs)
print(f"Total products in database: {total_products} (fetched in {fetch_time:.2f}s)")

out_of_stock = 0
low_stock = 0
to_update = []

for doc in docs:
    data = doc.to_dict()
    current_stock = data.get('countInStock', 0)
    if current_stock is None:
        current_stock = 0
    
    if current_stock <= 0:
        out_of_stock += 1
        to_update.append((doc.reference, 25))
    elif current_stock < 25:
        low_stock += 1
        to_update.append((doc.reference, 25))

print(f"Stock status summary:")
print(f"  - Completely Out of Stock (0 or less): {out_of_stock}")
print(f"  - Low Stock (< 25): {low_stock}")
print(f"  - Adequate Stock (>= 25): {total_products - out_of_stock - low_stock}")
print(f"Total products needing stock boost to 25: {len(to_update)}")

if not to_update:
    print("All products already have at least 25 units in stock! No updates needed.")
    exit(0)

print(f"\nStarting high-speed batch update for {len(to_update)} products...")

# Chunking into batches of 450 (Firestore limit is 500 per batch)
BATCH_SIZE = 450
chunks = [to_update[i:i + BATCH_SIZE] for i in range(0, len(to_update), BATCH_SIZE)]

def commit_chunk(chunk_idx, chunk):
    batch = db.batch()
    for ref, new_stock in chunk:
        batch.update(ref, {'countInStock': new_stock})
    batch.commit()
    return len(chunk)

update_start = time.time()
updated_count = 0

# Use ThreadPoolExecutor to commit multiple batches concurrently for maximum speed
with ThreadPoolExecutor(max_workers=5) as executor:
    futures = [executor.submit(commit_chunk, idx, chunk) for idx, chunk in enumerate(chunks)]
    for future in futures:
        updated_count += future.result()
        print(f"  -> Successfully committed batch. Total updated so far: {updated_count}/{len(to_update)}")

update_time = time.time() - update_start
print(f"\nSUCCESS! Updated {updated_count} products in {update_time:.2f}s.")
print("Every single product/medicine in Firestore now has at least 25 units in stock!")
