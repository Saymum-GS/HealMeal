import firebase_admin
from firebase_admin import credentials, firestore

print("Initializing Firebase Admin SDK...")
cred = credentials.Certificate(r"D:\HealMeal\healmeal-1-firebase-adminsdk-fbsvc-466f1d1cfb.json")
firebase_admin.initialize_app(cred)

db = firestore.client()
products_ref = db.collection('products')

total_updated = 0
last_doc = None

print("Starting heavy-duty stock update (18k+ products)...")

while True:
    query = products_ref.select(['countInStock']).limit(500)
    if last_doc:
        query = query.start_after(last_doc)
    
    docs = list(query.stream())
    
    if not docs:
        break
        
    batch = db.batch()
    for doc in docs:
        batch.update(doc.reference, {'countInStock': 25})
    
    batch.commit()
    total_updated += len(docs)
    last_doc = docs[-1]
    print(f"Committed batch of {len(docs)}. Total updated so far: {total_updated}")

print(f"Finished! Successfully verified/updated {total_updated} items.")
