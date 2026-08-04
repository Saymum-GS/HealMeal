import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';

class ChatRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Send a message (from patient or admin)
  Future<void> sendMessage(String userId, ChatMessage message) async {
    final msgRef = _db
        .collection('chats')
        .doc(userId)
        .collection('messages')
        .doc();
    final msgWithId = message.toMap();
    msgWithId['id'] = msgRef.id;
    msgWithId['createdAt'] = FieldValue.serverTimestamp();
    await msgRef.set(msgWithId);

    // Update the parent chat document
    final isAdmin = message.senderId == 'admin';
    await _db.collection('chats').doc(userId).set({
      'userId': userId,
      if (!isAdmin) 'userName': message.senderName,
      'lastMessage': message.text.isNotEmpty ? message.text : '[Image]',
      'lastMessageAt': FieldValue.serverTimestamp(),
      if (isAdmin)
        'unreadByPatient': FieldValue.increment(1)
      else
        'unreadByAdmin': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  /// Real-time message stream for a conversation
  Stream<List<ChatMessage>> messagesStream(String userId) => _db
      .collection('chats')
      .doc(userId)
      .collection('messages')
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map(
        (snap) => snap.docs.map((d) => ChatMessage.fromMap(d.data())).toList(),
      );

  /// All conversations stream (admin only)
  Stream<List<ChatConversation>> allConversationsStream() => _db
      .collection('chats')
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map((d) => ChatConversation.fromMap(d.data())).toList(),
      );

  /// Mark messages as read
  Future<void> markMessagesRead(String userId, {required bool byAdmin}) async {
    final field = byAdmin ? 'unreadByAdmin' : 'unreadByPatient';
    await _db
        .collection('chats')
        .doc(userId)
        .update({field: 0})
        .catchError((_) {});

    // Mark individual messages as read (only those from the other party)
    // We just mark the unread count to 0 on the parent doc.
    // Individual isRead field updates on each message doc are expensive
    // for the free tier. The unread count on the parent doc is the source of truth.
  }

  /// Unread count stream for the FAB badge (patient side)
  Stream<int> unreadCountForUser(String userId) => _db
      .collection('chats')
      .doc(userId)
      .snapshots()
      .map((snap) => (snap.data()?['unreadByPatient'] as num?)?.toInt() ?? 0);

  /// Delete a specific message (Admin)
  Future<void> deleteMessage(String userId, String messageId) async {
    await _db
        .collection('chats')
        .doc(userId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  /// Delete an entire conversation (Admin)
  Future<void> deleteConversation(String userId) async {
    final msgs = await _db
        .collection('chats')
        .doc(userId)
        .collection('messages')
        .get();
    for (var doc in msgs.docs) {
      await doc.reference.delete();
    }
    await _db.collection('chats').doc(userId).delete();
  }
}
