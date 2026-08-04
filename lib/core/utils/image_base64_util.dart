import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Utility for converting images to/from base64 strings for Firestore storage.
///
/// Firestore documents have a 1MB size limit. A compressed JPEG image
/// at ~100KB produces a ~133KB base64 string, well within limits.
/// Max recommended image size: ~500KB original → ~667KB base64.
class ImageBase64Util {
  /// Maximum bytes for the image before base64 encoding.
  /// 500KB is safe - the base64 will be ~667KB, leaving room in the 1MB doc.
  static const int maxImageBytes = 500 * 1024;

  /// Pick an image from gallery or camera, compress, and return as base64.
  /// Returns null if user cancels or image is too large after compression.
  static Future<String?> pickAndEncode({
    ImageSource source = ImageSource.gallery,
    int maxWidth = 800,
    int maxHeight = 800,
    int quality = 70,
  }) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
      );
      if (file == null) return null;

      final bytes = await file.readAsBytes();
      if (bytes.length > maxImageBytes) {
        // Try re-picking at lower quality
        final retryFile = await picker.pickImage(
          source: source,
          maxWidth: (maxWidth * 0.6).toDouble(),
          maxHeight: (maxHeight * 0.6).toDouble(),
          imageQuality: 50,
        );
        if (retryFile == null) return null;
        final retryBytes = await retryFile.readAsBytes();
        if (retryBytes.length > maxImageBytes) return 'TOO_LARGE';
        return base64Encode(retryBytes);
      }

      return base64Encode(bytes);
    } catch (e) {
      debugPrint('ImageBase64Util.pickAndEncode error: $e');
      return null;
    }
  }

  /// Encode raw bytes to base64 string.
  static String encode(Uint8List bytes) => base64Encode(bytes);

  /// Decode base64 string to bytes.
  static Uint8List decode(String base64String) => base64Decode(base64String);

  /// Check if a string is a base64-encoded image (not a URL).
  static bool isBase64(String value) {
    if (value.isEmpty) return false;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return false;
    }
    if (value.startsWith('data:image/')) return true;
    // Heuristic: base64 strings are long and contain only valid base64 chars
    if (value.length > 100 && RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(value)) {
      return true;
    }
    return false;
  }

  /// Build an Image widget from either a base64 string or a network URL.
  /// This is a convenience for rendering images from Firestore where the
  /// field may contain either format.
  static ImageProvider resolveProvider(String imageData) {
    if (isBase64(imageData)) {
      String clean = imageData;
      // Strip data URI prefix if present
      if (clean.startsWith('data:image/')) {
        clean = clean.split(',').last;
      }
      // Remove any whitespace or newlines that cause base64 decoding errors
      clean = clean.replaceAll(RegExp(r'\s+'), '');
      return MemoryImage(decode(clean));
    }
    return NetworkImage(imageData);
  }

  /// Estimated base64 size from raw bytes count.
  static int estimateBase64Size(int rawBytes) => (rawBytes * 4 / 3).ceil();
}
