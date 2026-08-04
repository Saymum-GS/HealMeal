import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';

class CategoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<AppCategory>> watchCategories() {
    return _firestore
        .collection('categories')
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppCategory.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<List<AppCategory>> getCategories() async {
    final snapshot = await _firestore
        .collection('categories')
        .orderBy('sortOrder')
        .get();

    if (snapshot.docs.isEmpty ||
        !snapshot.docs.any((d) => d.id == 'medicine')) {
      await _seedCategories();
      final retry = await _firestore
          .collection('categories')
          .orderBy('sortOrder')
          .get();
      return retry.docs
          .map((doc) => AppCategory.fromMap(doc.data(), doc.id))
          .toList();
    }

    return snapshot.docs
        .map((doc) => AppCategory.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> _seedCategories() async {
    final categories = [
      {
        'id': 'medicine',
        'name': 'Prescription Medicine',
        'slug': 'medicine',
        'iconKey': 'local_pharmacy',
        'colorHex': '#4CAF50',
        'sortOrder': 1,
        'isActive': true,
      },
      {
        'id': 'otc',
        'name': 'OTC Medicine',
        'slug': 'otc',
        'iconKey': 'medication',
        'colorHex': '#8BC34A',
        'sortOrder': 2,
        'isActive': true,
      },
      {
        'id': 'diabetes',
        'name': 'Diabetes Care',
        'slug': 'diabetes',
        'iconKey': 'bloodtype',
        'colorHex': '#F44336',
        'sortOrder': 3,
        'isActive': true,
      },
      {
        'id': 'cardiac_care',
        'name': 'Cardiac Care',
        'slug': 'cardiac_care',
        'iconKey': 'favorite',
        'colorHex': '#E91E63',
        'sortOrder': 4,
        'isActive': true,
      },
      {
        'id': 'supplements',
        'name': 'Vitamins & Supplements',
        'slug': 'supplements',
        'iconKey': 'spa',
        'colorHex': '#FF9800',
        'sortOrder': 5,
        'isActive': true,
      },
      {
        'id': 'devices',
        'name': 'Medical Devices',
        'slug': 'devices',
        'iconKey': 'monitor_heart',
        'colorHex': '#2196F3',
        'sortOrder': 6,
        'isActive': true,
      },
      {
        'id': 'personal_care',
        'name': 'Personal Care',
        'slug': 'personal_care',
        'iconKey': 'clean_hands',
        'colorHex': '#9C27B0',
        'sortOrder': 7,
        'isActive': true,
      },
      {
        'id': 'baby_care',
        'name': 'Baby Care',
        'slug': 'baby_care',
        'iconKey': 'child_care',
        'colorHex': '#00BCD4',
        'sortOrder': 8,
        'isActive': true,
      },
    ];

    for (var cat in categories) {
      await _firestore.collection('categories').doc(cat['id'] as String).set({
        ...cat,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<AppCategory?> getCategoryBySlug(String slug) async {
    final snapshot = await _firestore
        .collection('categories')
        .where('slug', isEqualTo: slug)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return AppCategory.fromMap(
      snapshot.docs.first.data(),
      snapshot.docs.first.id,
    );
  }

  Future<void> saveCategory(AppCategory category) async {
    final docRef = category.id.isEmpty
        ? _firestore.collection('categories').doc()
        : _firestore.collection('categories').doc(category.id);

    final map = category.toMap();
    map['id'] = docRef.id;

    if (category.id.isEmpty) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }
    map['updatedAt'] = FieldValue.serverTimestamp();

    await docRef.set(map, SetOptions(merge: true));
  }

  // Legacy support for admin_cubit.dart
  Future<void> addCategory(String slug, String name, String iconKey) async {
    final cat = AppCategory(
      id: '',
      name: name,
      slug: slug,
      iconKey: iconKey,
      colorHex: '#607D8B',
    );
    await saveCategory(cat);
  }

  Future<void> deleteCategory(String id) async {
    // 1. Get the category to find its slug
    final doc = await _firestore.collection('categories').doc(id).get();
    if (!doc.exists) return;

    final category = AppCategory.fromMap(doc.data()!, doc.id);

    // 2. Check if any products use this categoryId
    final productsSnap = await _firestore
        .collection('products')
        .where('categoryId', isEqualTo: category.id)
        .limit(1)
        .get();

    if (productsSnap.docs.isNotEmpty) {
      throw Exception('This category contains products and cannot be deleted.');
    }

    await _firestore.collection('categories').doc(id).delete();
  }
}
