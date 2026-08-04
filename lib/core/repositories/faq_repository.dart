import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/faq.dart';

class FaqRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<AppFaq>> watchFaqs({String? category}) {
    Query query = _firestore
        .collection('faqs')
        .where('status', isEqualTo: 'published');

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    return query.orderBy('order', descending: false).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map(
            (doc) => AppFaq.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    });
  }

  Future<void> addFaq(AppFaq faq) async {
    final docRef = _firestore.collection('faqs').doc();
    final newFaq = AppFaq(
      id: docRef.id,
      question: faq.question,
      answer: faq.answer,
      category: faq.category,
      order: faq.order,
      status: faq.status,
      createdAt: DateTime.now(),
    );
    await docRef.set(newFaq.toMap());
  }

  Future<void> updateFaq(AppFaq faq) async {
    await _firestore.collection('faqs').doc(faq.id).update(faq.toMap());
  }

  Future<void> deleteFaq(String id) async {
    await _firestore.collection('faqs').doc(id).delete();
  }
}
