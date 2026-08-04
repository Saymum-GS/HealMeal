import 'package:equatable/equatable.dart';

class AppFaq extends Equatable {
  final String id;
  final String question;
  final String answer;
  final String category;
  final int order;
  final String status;
  final DateTime? createdAt;

  const AppFaq({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.order = 0,
    this.status = 'published',
    this.createdAt,
  });

  factory AppFaq.fromMap(Map<String, dynamic> map, [String? docId]) {
    return AppFaq(
      id: docId ?? map['id'] ?? '',
      question: map['question'] ?? map['q'] ?? '',
      answer: map['answer'] ?? map['a'] ?? '',
      category: map['category'] ?? 'General',
      order: (map['order'] ?? 0).toInt(),
      status: map['status'] ?? 'published',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'order': order,
      'status': status,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [id, question, answer, category, order, status];
}
