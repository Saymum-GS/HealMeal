import firebase_admin
from firebase_admin import credentials, firestore

print("Initializing Firebase Admin SDK...")
cred = credentials.Certificate(r"D:\HealMeal\healmeal-1-firebase-adminsdk-fbsvc-466f1d1cfb.json")
firebase_admin.initialize_app(cred)

db = firestore.client()
products_ref = db.collection('products')

print("Fetching products...")
docs = products_ref.stream()

count = 0
batch = db.batch()
batch_count = 0

for doc in docs:
    batch.update(doc.reference, {'countInStock': 25})
    count += 1
    batch_count += 1
    
    if batch_count == 400:
        batch.commit()
        print(f"Committed batch. Total updated: {count}")
        batch = db.batch()
        batch_count = 0

if batch_count > 0:
    batch.commit()
    print(f"Committed final batch. Total updated: {count}")

print(f"Finished! Total updated: {count}")
