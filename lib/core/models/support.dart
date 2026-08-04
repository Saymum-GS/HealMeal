import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Review extends Equatable {
  const Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.targetId,
    required this.targetType,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.status = 'pending',
  });

  final String id;
  final String userId;
  final String userName;
  final String targetId;
  final String targetType; // 'product', 'app'
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String status; // 'pending', 'approved', 'rejected'

  factory Review.fromMap(Map<String, dynamic> map, String id) {
    return Review(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anonymous',
      targetId: map['targetId'] ?? '',
      targetType: map['targetType'] ?? 'product',
      rating: map['rating']?.toInt() ?? 0,
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'targetId': targetId,
      'targetType': targetType,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [id, userId, targetId, rating, status];
}

class SupportMessage extends Equatable {
  const SupportMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.email,
    required this.phone,
    required this.type,
    required this.subject,
    required this.message,
    required this.createdAt,
    this.status = 'open',
    this.reply,
  });

  final String id;
  final String userId;
  final String userName;
  final String email;
  final String phone;
  final String type; // 'contact', 'suggestion', 'complaint'
  final String subject;
  final String message;
  final DateTime createdAt;
  final String status; // 'open', 'in_progress', 'resolved'
  final String? reply;

  factory SupportMessage.fromMap(Map<String, dynamic> map, String id) {
    return SupportMessage(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anonymous',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      type: map['type'] ?? 'contact',
      subject: map['subject'] ?? '',
      message: map['message'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'open',
      reply: map['reply'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'email': email,
      'phone': phone,
      'type': type,
      'subject': subject,
      'message': message,
      'createdAt': createdAt,
      'status': status,
      'reply': reply,
    };
  }

  @override
  List<Object?> get props => [id, userId, status];
}
