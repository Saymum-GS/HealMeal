import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';

class SettingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  PlatformSettings? _cachedSettings;

  Future<PlatformSettings> getSettings({bool forceRefresh = false}) async {
    if (_cachedSettings != null && !forceRefresh) return _cachedSettings!;

    final doc = await _firestore
        .collection('platform_settings')
        .doc('global')
        .get();
    if (doc.exists) {
      _cachedSettings = PlatformSettings.fromMap(doc.data()!);
      return _cachedSettings!;
    } else {
      final defaultSettings = PlatformSettings.defaultSettings();
      try {
        await _firestore
            .collection('platform_settings')
            .doc('global')
            .set(defaultSettings.toMap());
      } catch (_) {
        // We might not have admin permissions to create it, just use defaults
      }
      _cachedSettings = defaultSettings;
      return defaultSettings;
    }
  }

  Stream<PlatformSettings> streamSettings() {
    return _firestore
        .collection('platform_settings')
        .doc('global')
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return PlatformSettings.fromMap(doc.data()!);
          }
          return PlatformSettings.defaultSettings();
        });
  }

  Future<void> updateSettings(PlatformSettings settings) async {
    await _firestore
        .collection('platform_settings')
        .doc('global')
        .set(settings.toMap(), SetOptions(merge: true));
    _cachedSettings = settings;
  }
}

// -- Feedback & Support Repositories ------------------------------------------------------------
