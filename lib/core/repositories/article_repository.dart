import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/article.dart';

/// Repository for articles - replaces both HealthInsightRepository and hardcoded blog data.
/// Uses one-shot reads with caching for home, streams for admin.
class ArticleRepository {
  final FirebaseFirestore _firestore;
  List<Article>? _cachedPublished;

  ArticleRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('articles');

  /// One-shot read for user-facing screens - cached.
  Future<List<Article>> getPublishedArticles({
    bool forceRefresh = false,
  }) async {
    if (_cachedPublished != null && !forceRefresh) return _cachedPublished!;
    final snap = await _collection
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    _cachedPublished = snap.docs
        .map((d) => Article.fromMap(d.data(), d.id))
        .toList();
    return _cachedPublished!;
  }

  /// Featured articles for home - one-shot, cached.
  Future<List<Article>> getFeaturedArticles() async {
    final all = await getPublishedArticles();
    return all.where((a) => a.isFeatured).toList()
      ..sort((a, b) => a.featuredRank.compareTo(b.featuredRank));
  }

  /// Daily tip for home - one-shot.
  Future<Article?> getDailyTip() async {
    final all = await getPublishedArticles();
    final tips = all.where((a) => a.isDailyTip).toList();
    if (tips.isEmpty) return null;
    // Rotate daily tips by day-of-year
    final dayIndex =
        DateTime.now().difference(DateTime(2026)).inDays % tips.length;
    return tips[dayIndex];
  }

  /// Stream for admin screens.
  Stream<List<Article>> watchAllArticles() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Article.fromMap(d.data(), d.id)).toList(),
        );
  }

  Future<void> addArticle(Article article) async {
    final docRef = _collection.doc();
    final newArticle = article.copyWith(id: docRef.id);
    await docRef.set(newArticle.toMap());
    _cachedPublished = null;
  }

  Future<void> updateArticle(Article article) async {
    await _collection.doc(article.id).update(article.toMap());
    _cachedPublished = null;
  }

  Future<void> deleteArticle(String id) async {
    await _collection.doc(id).delete();
    _cachedPublished = null;
  }

  String generateId() => _collection.doc().id;

  void clearCache() => _cachedPublished = null;
}
