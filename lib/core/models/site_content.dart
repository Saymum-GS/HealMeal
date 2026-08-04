import 'package:equatable/equatable.dart';

class SiteContent extends Equatable {
  final String id;
  final String key; // e.g. 'about', 'privacy', 'terms'
  final String title;
  final String contentBlocks; // Rich text or HTML
  final String status; // 'draft', 'published'
  final DateTime? updatedAt;

  const SiteContent({
    required this.id,
    required this.key,
    required this.title,
    required this.contentBlocks,
    this.status = 'published',
    this.updatedAt,
  });

  factory SiteContent.fromMap(Map<String, dynamic> map, [String? docId]) {
    return SiteContent(
      id: docId ?? map['id'] ?? '',
      key: map['key'] ?? '',
      title: map['title'] ?? '',
      contentBlocks: map['contentBlocks'] ?? '',
      status: map['status'] ?? 'published',
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'key': key,
      'title': title,
      'contentBlocks': contentBlocks,
      'status': status,
      'updatedAt': updatedAt,
    };
  }

  @override
  List<Object?> get props => [id, key, title, contentBlocks, status, updatedAt];
}
