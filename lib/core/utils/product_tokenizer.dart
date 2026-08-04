class ProductTokenizer {
  static const int maxTokens = 60;

  static List<String> tokenize(
    String drugName,
    String genericName,
    String manufacturer,
  ) {
    final Set<String> tokens = {};

    // 1. Process main names
    _addTokens(drugName, tokens);
    _addTokens(genericName, tokens);
    _addTokens(manufacturer, tokens);

    // 2. Add common abbreviations or variations if needed
    // e.g. "Paracetamol" -> "PCM"
    if (drugName.toLowerCase().contains('paracetamol')) tokens.add('pcm');
    if (drugName.toLowerCase().contains('metformin')) tokens.add('met');

    final result = tokens.toList();
    if (result.length > maxTokens) {
      return result.sublist(0, maxTokens);
    }
    return result;
  }

  static void _addTokens(String text, Set<String> tokens) {
    if (text.trim().isEmpty) return;

    final cleanText = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '');
    final words = cleanText.split(RegExp(r'\s+'));

    for (final word in words) {
      if (word.isEmpty || word.length < 2) continue;

      // Add prefixes for each word (e.g. "napa" -> "na", "nap", "napa")
      String prefix = '';
      for (int i = 0; i < word.length; i++) {
        prefix += word[i];
        if (prefix.length >= 2) {
          tokens.add(prefix);
        }
      }
    }

    // Also add prefixes for the full string if it's multiple words
    if (words.length > 1) {
      final fullClean = words.join('');
      String prefix = '';
      for (int i = 0; i < fullClean.length && i < 15; i++) {
        prefix += fullClean[i];
        if (prefix.length >= 3) {
          tokens.add(prefix);
        }
      }
    }
  }
}
