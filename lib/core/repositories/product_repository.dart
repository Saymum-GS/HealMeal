import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';

class ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Product>> getProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final snapshot = await _firestore
        .collection('products')
        .where(FieldPath.documentId, whereIn: ids)
        .get();

    return snapshot.docs
        .map((doc) => Product.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<Product?> getProductById(String id) async {
    final doc = await _firestore.collection('products').doc(id).get();
    if (!doc.exists) return null;
    return Product.fromMap(doc.data()!, doc.id);
  }

  Future<List<Product>> getFeaturedProducts({int limit = 20}) async {
    final snap = await _firestore
        .collection('products')
        .where('isFeatured', isEqualTo: true)
        .limit(limit * 2)
        .get();
    return snap.docs
        .map((d) => Product.fromMap(d.data(), d.id))
        .where((p) => p.isAvailable)
        .take(limit)
        .toList();
  }

  Future<List<Product>> getFlashSaleProducts({int limit = 20}) async {
    final snap = await _firestore
        .collection('products')
        .where('isFlashSale', isEqualTo: true)
        .limit(limit * 2)
        .get();
    return snap.docs
        .map((d) => Product.fromMap(d.data(), d.id))
        .where((p) => p.isAvailable && p.isCurrentlyFlashSale)
        .take(limit)
        .toList();
  }

  Future<({List<Product> products, DocumentSnapshot? lastDoc})> getAllProducts({
    ProductLifecycleStatus? status = ProductLifecycleStatus.active,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _firestore.collection('products');
    if (status != null) {
      query = query.where('lifecycleStatus', isEqualTo: status.name);
    }
    query = query.orderBy('createdAt', descending: true).limit(limit);

    if (startAfter != null) query = query.startAfterDocument(startAfter);
    final snap = await query.get();
    final products = snap.docs
        .map((d) => Product.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();
    return (
      products: products,
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
  }

  Future<({List<Product> products, DocumentSnapshot? lastDoc})>
  getProductsByCategory({
    required String categoryId,
    int limit = 40,
    DocumentSnapshot? startAfter,
    ProductLifecycleStatus? status = ProductLifecycleStatus.active,
  }) async {
    Query query = _firestore
        .collection('products')
        .where('categoryId', isEqualTo: categoryId);
    if (status != null) {
      query = query.where('lifecycleStatus', isEqualTo: status.name);
    }
    query = query.limit(limit);

    if (startAfter != null) query = query.startAfterDocument(startAfter);

    final snapshot = await query.get();
    final products = snapshot.docs
        .map(
          (doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();

    // Local sort
    products.sort(
      (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
        a.createdAt ?? DateTime.now(),
      ),
    );

    return (
      products: products,
      lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  Future<({List<Product> products, DocumentSnapshot? lastDoc})>
  getProductsByCollection({
    required String collection,
    int limit = 20,
    DocumentSnapshot? startAfter,
    ProductLifecycleStatus? status = ProductLifecycleStatus.active,
  }) async {
    Query query = _firestore
        .collection('products')
        .where('collections', arrayContains: collection);
    if (status != null) {
      query = query.where('lifecycleStatus', isEqualTo: status.name);
    }
    query = query.limit(limit);

    if (startAfter != null) query = query.startAfterDocument(startAfter);

    final snapshot = await query.get();
    final products = snapshot.docs
        .map(
          (doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();

    // Local sort
    products.sort(
      (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
        a.createdAt ?? DateTime.now(),
      ),
    );

    return (
      products: products,
      lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  Future<({List<Product> products, DocumentSnapshot? lastDoc})> searchProducts(
    String query, {
    int limit = 20,
    DocumentSnapshot? startAfter,
    ProductLifecycleStatus? status = ProductLifecycleStatus.active,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return (products: <Product>[], lastDoc: null);

    final queryTokens = q
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 2)
        .toSet()
        .take(10)
        .toList();

    if (queryTokens.isEmpty) return (products: <Product>[], lastDoc: null);

    Query firestoreQuery = _firestore.collection('products');
    if (status != null) {
      firestoreQuery = firestoreQuery.where(
        'lifecycleStatus',
        isEqualTo: status.name,
      );
    }
    firestoreQuery = firestoreQuery
        .where('searchTokens', arrayContainsAny: queryTokens)
        .limit(limit * 2);

    if (startAfter != null) {
      firestoreQuery = firestoreQuery.startAfterDocument(startAfter);
    }

    final snap = await firestoreQuery.get();
    final products = snap.docs
        .map((d) => Product.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();

    products.sort((a, b) {
      final scoreA = _scoreProduct(a, queryTokens);
      final scoreB = _scoreProduct(b, queryTokens);
      if (scoreA != scoreB) return scoreB.compareTo(scoreA);
      return a.drugName.length.compareTo(b.drugName.length);
    });

    final pList = products.take(limit).toList();
    return (
      products: pList,
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
  }

  Future<({List<Product> products, DocumentSnapshot? lastDoc})>
  getProductsByPrice({
    required double maxPrice,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _firestore
        .collection('products')
        .where('lifecycleStatus', isEqualTo: 'active')
        .where('salePrice', isLessThanOrEqualTo: maxPrice)
        .orderBy('salePrice', descending: true)
        .limit(limit);

    if (startAfter != null) query = query.startAfterDocument(startAfter);

    final snapshot = await query.get();
    final products = snapshot.docs
        .map(
          (doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
    return (
      products: products,
      lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  // -- Admin & Maintenance Methods --

  Future<List<Product>> getOutOfStockProducts({int limit = 50}) async {
    final snap = await _firestore
        .collection('products')
        .where('countInStock', isEqualTo: 0)
        .limit(limit)
        .get();
    return snap.docs.map((d) => Product.fromMap(d.data(), d.id)).toList();
  }

  Future<List<Product>> getLowStockProducts({int limit = 50}) async {
    final snap = await _firestore
        .collection('products')
        .where('countInStock', isGreaterThan: 0)
        .where('countInStock', isLessThanOrEqualTo: 5)
        .limit(limit)
        .get();
    return snap.docs.map((d) => Product.fromMap(d.data(), d.id)).toList();
  }

  Future<void> updateStock(String productId, int newCount) async {
    await _firestore.collection('products').doc(productId).update({
      'countInStock': newCount,
      'isAvailable': newCount > 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Product>> watchFlashSales() {
    return _firestore
        .collection('products')
        .where('isFlashSale', isEqualTo: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Product.fromMap(d.data(), d.id)).toList(),
        );
  }

  Future<void> setFlashSale(
    String productId,
    bool isFlash, {
    double? price,
    DateTime? flashSaleStartAt,
    DateTime? flashSaleEndAt,
  }) async {
    if (isFlash && price != null && price <= 0) {
      throw Exception('Flash sale price must be greater than 0');
    }
    final Map<String, dynamic> data = {'isFlashSale': isFlash};
    if (isFlash) {
      if (price != null) data['flashSalePrice'] = price;
      if (flashSaleStartAt != null) {
        data['flashSaleStartAt'] = Timestamp.fromDate(flashSaleStartAt);
      }
      if (flashSaleEndAt != null) {
        data['flashSaleEndAt'] = Timestamp.fromDate(flashSaleEndAt);
      }
    }
    await _firestore.collection('products').doc(productId).update(data);
  }

  Future<void> addToCampaign(String productId, String campaignId) async {
    await _firestore.collection('products').doc(productId).update({
      'campaignIds': FieldValue.arrayUnion([campaignId]),
    });
  }

  Future<void> removeFromCampaign(String productId, String campaignId) async {
    await _firestore.collection('products').doc(productId).update({
      'campaignIds': FieldValue.arrayRemove([campaignId]),
    });
  }

  Stream<List<Product>> watchProductsByCampaign(String campaignId) {
    return _firestore
        .collection('products')
        .where('campaignIds', arrayContains: campaignId)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Product.fromMap(d.data(), d.id)).toList(),
        );
  }

  Future<void> setFrequent(String productId, bool isFrequent) async {
    await _firestore.collection('products').doc(productId).update({
      'isFrequent': isFrequent,
    });
  }

  Future<void> setSale(
    String productId,
    bool isSale, {
    int? discountPercent,
  }) async {
    final Map<String, dynamic> data = {'isSale': isSale};
    if (isSale && discountPercent != null) {
      data['saleDiscountPercent'] = discountPercent;
    } else {
      data['saleDiscountPercent'] = FieldValue.delete();
    }
    await _firestore.collection('products').doc(productId).update(data);
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    final Map<String, dynamic> updateData = Map.from(data);
    if (updateData.containsKey('imageUrl')) {
      final String? imageUrl = updateData['imageUrl'] as String?;
      if (imageUrl != null && imageUrl.startsWith('data:image')) {
        await _firestore.collection('product_images').doc(id).set({
          'base64': imageUrl,
        });
        updateData['hasImage'] = true;
        updateData['imageUrl'] = ''; // clear from main document
      } else if (imageUrl != null && imageUrl.isNotEmpty) {
        updateData['hasImage'] = true;
      } else {
        updateData['hasImage'] = false;
        await _firestore
            .collection('product_images')
            .doc(id)
            .delete()
            .catchError((_) {});
      }
    }
    await _firestore.collection('products').doc(id).update(updateData);
  }

  Future<void> createProduct(Map<String, dynamic> data) async {
    final String id = data['id'] ?? _firestore.collection('products').doc().id;
    final Map<String, dynamic> createData = Map.from(data);
    createData['id'] = id;

    if (createData.containsKey('imageUrl')) {
      final String? imageUrl = createData['imageUrl'] as String?;
      if (imageUrl != null && imageUrl.startsWith('data:image')) {
        await _firestore.collection('product_images').doc(id).set({
          'base64': imageUrl,
        });
        createData['hasImage'] = true;
        createData['imageUrl'] = ''; // clear from main document
      } else if (imageUrl != null && imageUrl.isNotEmpty) {
        createData['hasImage'] = true;
      } else {
        createData['hasImage'] = false;
      }
    }
    await _firestore.collection('products').doc(id).set(createData);
  }

  Future<void> deleteProduct(String id) async {
    await _firestore.collection('products').doc(id).delete();
    await _firestore
        .collection('product_images')
        .doc(id)
        .delete()
        .catchError((_) {});
  }

  String generateId() => _firestore.collection('products').doc().id;

  // Helpers
  int _scoreProduct(Product p, List<String> tokens) {
    int score = 0;
    for (final token in tokens) {
      if (p.searchTokens.contains(token)) score += 1;
      if (p.drugName.toLowerCase().contains(token)) score += 2;
      if (p.genericName.toLowerCase().contains(token)) score += 1;
    }
    return score;
  }
}
