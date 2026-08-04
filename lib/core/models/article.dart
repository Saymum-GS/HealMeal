import 'package:cloud_firestore/cloud_firestore.dart';

/// Unified article model - replaces both HealthInsight and hardcoded blog data.
/// Stored in Firestore `articles` collection.
class Article {
  final String id;
  final String title;
  final String slug;
  final String summary;
  final String body;
  final String imageUrl;

  /// e.g. 'article', 'daily_tip', 'guide'
  final String articleType;

  /// e.g. 'Diabetes', 'Heart Health', 'Medicine Tips', 'General'
  final String category;
  final List<String> relatedProductIds;
  final int readTimeMinutes;
  final String author;

  /// Rank for home page featured placement. 0 = not featured.
  final int featuredRank;

  /// Scheduled publish date.
  final DateTime? publishAt;

  /// 'draft', 'published', 'archived'
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Article({
    required this.id,
    required this.title,
    this.slug = '',
    this.summary = '',
    required this.body,
    this.imageUrl = '',
    this.articleType = 'article',
    this.category = 'General',
    this.relatedProductIds = const [],
    this.readTimeMinutes = 5,
    this.author = 'HealMeal Editorial',
    this.featuredRank = 0,
    this.publishAt,
    this.status = 'published',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPublished => status == 'published';
  bool get isFeatured => featuredRank > 0;
  bool get isDailyTip => articleType == 'daily_tip';

  factory Article.fromMap(Map<String, dynamic> map, String id) {
    return Article(
      id: id,
      title: map['title'] ?? '',
      slug: map['slug'] ?? '',
      summary: map['summary'] ?? '',
      body: map['body'] ?? map['content'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      articleType: map['articleType'] ?? 'article',
      category: map['category'] ?? 'General',
      relatedProductIds: List<String>.from(map['relatedProductIds'] ?? []),
      readTimeMinutes: map['readTimeMinutes'] ?? 5,
      author: map['author'] ?? 'HealMeal Editorial',
      featuredRank: map['featuredRank'] ?? 0,
      publishAt: (map['publishAt'] as Timestamp?)?.toDate(),
      status: map['status'] ?? 'published',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'slug': slug,
      'summary': summary,
      'body': body,
      'imageUrl': imageUrl,
      'articleType': articleType,
      'category': category,
      'relatedProductIds': relatedProductIds,
      'readTimeMinutes': readTimeMinutes,
      'author': author,
      'featuredRank': featuredRank,
      'publishAt': publishAt != null ? Timestamp.fromDate(publishAt!) : null,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Article copyWith({
    String? id,
    String? title,
    String? slug,
    String? summary,
    String? body,
    String? imageUrl,
    String? articleType,
    String? category,
    List<String>? relatedProductIds,
    int? readTimeMinutes,
    String? author,
    int? featuredRank,
    DateTime? publishAt,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Article(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      summary: summary ?? this.summary,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      articleType: articleType ?? this.articleType,
      category: category ?? this.category,
      relatedProductIds: relatedProductIds ?? this.relatedProductIds,
      readTimeMinutes: readTimeMinutes ?? this.readTimeMinutes,
      author: author ?? this.author,
      featuredRank: featuredRank ?? this.featuredRank,
      publishAt: publishAt ?? this.publishAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
