import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<(List<AppUser>, DocumentSnapshot?)> getUsers({
    DocumentSnapshot? lastDoc,
    int limit = 20,
  }) async {
    Query query = _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();
    final users = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return AppUser.fromMap(data, doc.id);
    }).toList();

    return (users, snapshot.docs.isNotEmpty ? snapshot.docs.last : null);
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    await _firestore.collection('users').doc(userId).update({'role': newRole});
  }

  Future<void> updateUserField(
    String userId,
    String field,
    dynamic value,
  ) async {
    await _firestore.collection('users').doc(userId).update({field: value});
  }

  Future<void> updateWalletBalance(String userId, double change) async {
    await _firestore.collection('users').doc(userId).update({
      'walletBalance': FieldValue.increment(change),
    });
  }

  Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }
}
