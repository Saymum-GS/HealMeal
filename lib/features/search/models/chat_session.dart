import 'chat_message.dart';

class AiChatSession {
  final String id;
  String name;
  List<AiChatMessage> messages;
  final DateTime createdAt;
  DateTime updatedAt;

  AiChatSession({
    required this.id,
    required this.name,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      // We don't save messages here, they are saved separately
    };
  }

  factory AiChatSession.fromJson(Map<String, dynamic> json) {
    return AiChatSession(
      id: json['id'] as String,
      name: json['name'] as String,
      messages: [], // Loaded separately
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
