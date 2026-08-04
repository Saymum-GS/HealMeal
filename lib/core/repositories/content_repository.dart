import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';

class ContentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Article>> watchArticles({String? category}) {
    Query query = _firestore
        .collection('articles')
        .where('status', isEqualTo: 'published');

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    return query.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map(
            (doc) =>
                Article.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    });
  }

  Stream<List<AppFaq>> watchFaqs() {
    return _firestore
        .collection('faqs')
        .where('status', isEqualTo: 'published')
        .orderBy('order', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AppFaq.fromMap(doc.data(), doc.id))
              .toList();
        });
  }
}
