import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqService {
  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  // Read the API key from .env file
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  // In-memory cache: query -> result (max 20 entries, LRU eviction)
  final _cache = <String, AiSearchResult>{};

  Future<AiSearchResult?> interpretSearchQuery(String query) async {
    if (_apiKey.isEmpty) {
      debugPrint('GROQ_API_KEY is missing. Please add it to your .env file.');
      return null;
    }

    final cacheKey = query.toLowerCase().trim();
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'llama-3.1-8b-instant', // cheapest, fastest
        'max_tokens': 200,
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {'role': 'user', 'content': query},
        ],
      }),
    );

    if (response.statusCode != 200) return null;

    try {
      final data = jsonDecode(response.body);
      final text = data['choices'][0]['message']['content'] as String;
      
      final json = jsonDecode(text) as Map<String, dynamic>;
      final result = AiSearchResult.fromJson(json);
      // LRU cache eviction
      if (_cache.length >= 20) _cache.remove(_cache.keys.first);
      _cache[cacheKey] = result;
      return result;
    } catch (_) {
      return null; // graceful fallback
    }
  }

  static const _systemPrompt = '''
You are a pharmacy assistant for a Bangladeshi online pharmacy.
Given a user's search query, return ONLY a JSON object with:
- "generics": array of up to 5 generic drug names that match
- "categories": array of up to 3 drug category names
- "note": one short sentence in plain language about the query (in the same language as the query)
Example: {"generics": ["paracetamol", "ibuprofen"], "categories": ["analgesic", "antipyretic"], "note": "Showing common fever and pain relief medicines."}
If the query is already a drug name, return empty arrays and note: "".
Return ONLY the JSON object, nothing else.
''';
}

class AiSearchResult {
  final List<String> generics;
  final List<String> categories;
  final String note;

  AiSearchResult({
    required this.generics,
    required this.categories,
    required this.note,
  });

  factory AiSearchResult.fromJson(Map<String, dynamic> json) => AiSearchResult(
    generics: List<String>.from(json['generics'] ?? []),
    categories: List<String>.from(json['categories'] ?? []),
    note: json['note'] ?? '',
  );
}
