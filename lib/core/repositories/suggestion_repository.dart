import 'package:cloud_firestore/cloud_firestore.dart';

class ProductSuggestion {
  final String id;
  final String productName;
  final String? brandName;
  final String? reason;
  final DateTime createdAt;
  final String userId;

  ProductSuggestion({
    required this.id,
    required this.productName,
    this.brandName,
    this.reason,
    required this.createdAt,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productName': productName,
      'brandName': brandName,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
      'userId': userId,
    };
  }
}

class SuggestionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitSuggestion(ProductSuggestion suggestion) async {
    await _firestore
        .collection('suggestions')
        .doc(suggestion.id)
        .set(suggestion.toMap());
  }

  Stream<List<ProductSuggestion>> watchSuggestions() {
    return _firestore
        .collection('suggestions')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return ProductSuggestion(
              id: doc.id,
              productName: data['productName'] ?? '',
              brandName: data['brandName'],
              reason: data['reason'],
              createdAt:
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              userId: data['userId'] ?? '',
            );
          }).toList();
        });
  }

  Future<void> deleteSuggestion(String id) async {
    await _firestore.collection('suggestions').doc(id).delete();
  }
}
