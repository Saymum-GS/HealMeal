import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String senderId; // user UID or "admin"
  final String senderName;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.imageUrl,
    required this.createdAt,
    this.isRead = false,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasText => text.trim().isNotEmpty;

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      text: map['text'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? map['imageBase64'] as String?,
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt']
          : (map['createdAt'] != null
                ? (map['createdAt'] as dynamic).toDate()
                : DateTime.now()),
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': createdAt,
      'isRead': isRead,
    };
  }

  @override
  List<Object?> get props => <Object?>[id, senderId, text, createdAt, isRead];
}

class ChatConversation extends Equatable {
  final String userId;
  final String userName;
  final String userEmail;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadByAdmin;
  final int unreadByPatient;

  const ChatConversation({
    required this.userId,
    required this.userName,
    this.userEmail = '',
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadByAdmin = 0,
    this.unreadByPatient = 0,
  });

  factory ChatConversation.fromMap(Map<String, dynamic> map) {
    return ChatConversation(
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      userEmail: map['userEmail'] as String? ?? '',
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageAt: map['lastMessageAt'] is DateTime
          ? map['lastMessageAt']
          : (map['lastMessageAt'] != null
                ? (map['lastMessageAt'] as dynamic).toDate()
                : DateTime.now()),
      unreadByAdmin: (map['unreadByAdmin'] as num?)?.toInt() ?? 0,
      unreadByPatient: (map['unreadByPatient'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt,
      'unreadByAdmin': unreadByAdmin,
      'unreadByPatient': unreadByPatient,
    };
  }

  @override
  List<Object?> get props => <Object?>[
    userId,
    userName,
    lastMessage,
    lastMessageAt,
    unreadByAdmin,
    unreadByPatient,
  ];
}
