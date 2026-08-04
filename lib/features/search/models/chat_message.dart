import '../../../core/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AiChatRole { user, assistant }

class AiChatMessage {
  final String id;
  final AiChatRole role;
  final String text;
  final List<Product> products;

  AiChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.products = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'text': text,
      'products': products.map((p) {
        final map = p.toMap();
        map['id'] = p.id; // ensure ID is preserved

        // Sanitize Timestamps for jsonEncode
        for (final key in map.keys.toList()) {
          if (map[key] is Timestamp) {
            map[key] = (map[key] as Timestamp).toDate().toIso8601String();
          } else if (map[key] is DateTime) {
            map[key] = (map[key] as DateTime).toIso8601String();
          }
        }

        return map;
      }).toList(),
    };
  }

  factory AiChatMessage.fromJson(Map<String, dynamic> json) {
    return AiChatMessage(
      id: json['id'] as String,
      role: AiChatRole.values.firstWhere((e) => e.name == json['role']),
      text: json['text'] as String,
      products:
          (json['products'] as List<dynamic>?)?.map((p) {
            final map = p as Map<String, dynamic>;
            return Product.fromMap(map, map['id'] as String?);
          }).toList() ??
          [],
    );
  }
}
