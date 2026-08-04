import 'package:flutter/material.dart';

class CategoryIconRegistry {
  static final Map<String, IconData> _iconMap = {
    'medicines': Icons.medication_rounded,
    'healthcare': Icons.health_and_safety_rounded,
    'supplements': Icons.medical_services_rounded,
    'diabetes': Icons.bloodtype_rounded,
    'cardiac': Icons.favorite_rounded,
    'personal-care': Icons.face_rounded,
    'baby-care': Icons.child_care_rounded,
    'nutrition': Icons.restaurant_rounded,
    'devices': Icons.biotech_rounded,
    'otc': Icons.add_moderator_rounded,
  };

  static final Map<String, Color> _colorMap = {
    'medicines': Color(0xFF2196F3),
    'healthcare': Color(0xFF4CAF50),
    'supplements': Color(0xFFFF9800),
    'diabetes': Color(0xFFF44336),
    'cardiac': Color(0xFFE91E63),
    'personal-care': Color(0xFF9C27B0),
    'baby-care': Color(0xFF00BCD4),
    'nutrition': Color(0xFF8BC34A),
    'devices': Color(0xFF607D8B),
    'otc': Color(0xFFFFC107),
  };

  static IconData getIcon(String slug) {
    return _iconMap[slug.toLowerCase()] ?? Icons.category_rounded;
  }

  static Color getColor(String slug) {
    return _colorMap[slug.toLowerCase()] ?? Color(0xFF607D8B);
  }

  static List<String> get allKeys => _iconMap.keys.toList();
}
