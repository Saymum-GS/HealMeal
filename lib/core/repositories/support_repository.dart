import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';

class SupportRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitSupportMessage(SupportMessage message) async {
    await _firestore
        .collection('support_messages')
        .doc(message.id)
        .set(message.toMap());
  }

  Stream<List<SupportMessage>> watchUserSupportMessages(String userId) {
    return _firestore
        .collection('support_messages')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SupportMessage.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<SupportMessage>> watchAllSupportMessages() {
    return _firestore
        .collection('support_messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SupportMessage.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> updateSupportMessageStatus(
    String id,
    String status, {
    String? reply,
  }) async {
    final Map<String, dynamic> data = {'status': status};
    if (reply != null) {
      data['reply'] = reply;
    }
    await _firestore.collection('support_messages').doc(id).update(data);
  }

  Future<void> deleteSupportMessage(String id) async {
    await _firestore.collection('support_messages').doc(id).delete();
  }
}
