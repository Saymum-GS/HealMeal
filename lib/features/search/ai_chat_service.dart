import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/repositories.dart';
import '../../../core/models.dart';
import 'models/chat_message.dart';

class AiChatService {
  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  static const _systemPrompt = '''
You are "HealMeal AI", a friendly, knowledgeable pharmacy assistant for a Bangladeshi online pharmacy.
Your goal is to help users find the right medicines or lab tests based on their symptoms or questions.

When a user asks for a recommendation, you must reply with a JSON object containing two fields:
1. "reply": A friendly, conversational response explaining what you found and any necessary precautions (e.g. "If symptoms persist, see a doctor.").
2. "search_queries": A JSON array of exact drug names, generic names, or symptom keywords to search our database (e.g. ["D Cough", "paracetamol", "cough syrup"]). Max 3 queries.

CRITICAL MEDICAL SAFETY RULES:
- If the user provides a specific brand name (like "D Cough", "Napa"), ALWAYS include that exact brand name in your search_queries. Do not guess a generic.
- Do NOT prescribe or recommend strong steroids (e.g., Dexamethasone) or antibiotics for common ailments like coughs, colds, or fevers unless specifically requested.
- Always recommend safe, OTC options first for common symptoms.
- Never make a definitive diagnosis.

Example:
{"reply": "For a cough, a soothing cough syrup is usually recommended. Here are some common options available.", "search_queries": ["cough syrup", "dextromethorphan"]}

If they just say "hello" or ask a general question without needing medicines, you can leave "search_queries" empty.
Return ONLY valid JSON.
''';

  static Future<AiChatMessage> sendMessage({
    required String userMessage,
    required List<AiChatMessage> history,
    required ProductRepository productRepository,
  }) async {
    if (_apiKey.isEmpty) {
      return AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: AiChatRole.assistant,
        text: 'GROQ_API_KEY is missing. Please add it to your .env file.',
      );
    }

    try {
      final messages = [
        {'role': 'system', 'content': _systemPrompt},
      ];

      for (final msg in history) {
        messages.add({
          'role': msg.role == AiChatRole.user ? 'user' : 'assistant',
          'content': msg.text,
        });
      }

      messages.add({'role': 'user', 'content': userMessage});

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'max_tokens': 300,
          'messages': messages,
        }),
      );

      if (response.statusCode != 200) {
        return AiChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: AiChatRole.assistant,
          text:
              'Sorry, I am having trouble connecting to the server right now. (${response.statusCode})',
        );
      }

      final data = jsonDecode(response.body);
      final rawText = data['choices'][0]['message']['content'] as String;

      try {
        final json = jsonDecode(rawText) as Map<String, dynamic>;
        final replyText = json['reply'] as String? ?? 'Here is what I found:';
        final searchQueries = List<String>.from(json['search_queries'] ?? []);

        List<Product> matchedProducts = [];
        if (searchQueries.isNotEmpty) {
          for (final query in searchQueries) {
            final queryMatches = await productRepository.searchProducts(
              query,
              limit: 10,
            );
            matchedProducts.addAll(queryMatches.products);
          }

          // Remove duplicates and cap to top 15 results
          final seen = <String>{};
          matchedProducts = matchedProducts
              .where((p) => seen.add(p.id))
              .take(15)
              .toList();
        }

        return AiChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: AiChatRole.assistant,
          text: replyText,
          products: matchedProducts,
        );
      } catch (e) {
        // If the AI failed to return JSON, just wrap the raw text
        return AiChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: AiChatRole.assistant,
          text: rawText,
        );
      }
    } catch (e) {
      return AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: AiChatRole.assistant,
        text: 'An error occurred while connecting to the AI. Please try again.',
      );
    }
  }
}
