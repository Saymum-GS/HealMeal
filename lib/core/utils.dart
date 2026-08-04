// ============================================================================
// HealMeal Utilities
// Merged from: app_formatters, app_layout, app_session, app_validators, image_upload_util
// ============================================================================

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'config.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

export 'utils/toast.dart';
export 'utils/category_icon_registry.dart';
export 'utils/product_tokenizer.dart';
export 'utils/app_layout.dart';
export 'utils/image_base64_util.dart';

// -- Formatters --------------------------------------------------------------

class AppFormatters {
  static String taka(num value, {int decimals = 0}) {
    final formatter = NumberFormat.currency(
      locale: 'en',
      symbol: '\u09F3',
      decimalDigits: decimals,
    );
    return formatter.format(value);
  }

  static String shortDate(DateTime date, {String locale = 'en'}) =>
      DateFormat('dd/MM/yyyy', locale).format(date);

  static String longDate(DateTime date, {String locale = 'en'}) =>
      DateFormat('dd MMM yyyy', locale).format(date);

  static String compactDateTime(DateTime date, {String locale = 'en'}) =>
      DateFormat('dd MMM yyyy \u2022 hh:mm a', locale).format(date);

  static String compactTime(DateTime date, {String locale = 'en'}) =>
      DateFormat('hh:mm a', locale).format(date);

  static String percent(num value) => '${value.round()}%';

  static String formatPhone(String phone) {
    if (phone.startsWith('+880')) return phone;
    if (phone.startsWith('0')) return '+88$phone';
    return '+880$phone';
  }
}

// -- Session -----------------------------------------------------------------

class AppSession {
  AppSession._();

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get isReady => _prefs != null;

  static bool get isLoggedIn => _prefs?.getBool('is_logged_in') ?? false;

  static UserRole get currentUserRole {
    final raw = _prefs?.getString('user_role');
    return UserRole.fromString(raw);
  }

  static String get roleId => currentUserRole.id;

  static String? get phone => _prefs?.getString('user_phone');

  static String? get userId => _prefs?.getString('user_id');

  static String get guestId {
    var gid = _prefs?.getString('guest_id');
    if (gid == null) {
      gid = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      _prefs?.setString('guest_id', gid);
    }
    return gid;
  }

  static String? get name => _prefs?.getString('user_name');

  static Future<void> persistLogin({
    required UserRole role,
    required String phone,
    required String userId,
    String? name,
  }) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_role', role.id);
    await prefs.setString('user_phone', phone);
    await prefs.setString('user_id', userId);
    if (name != null) await prefs.setString('user_name', name);
  }

  static Future<void> clear() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.remove('is_logged_in');
    await prefs.remove('user_role');
    await prefs.remove('user_phone');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
  }
}

// -- Guest Helper ------------------------------------------------------------

class GuestHelper {
  static void showLoginModal(
    BuildContext context, {
    required String title,
    required String message,
    String? redirectUrl,
  }) {
    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.account_circle_outlined,
                size: 64.w,
                color: AppColors.primary,
              ),
              SizedBox(height: 16.h),
              Text(
                title,
                style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (redirectUrl != null) {
                      final encoded = Uri.encodeComponent(redirectUrl);
                      context.push('/login?redirect=$encoded');
                    } else {
                      context.push('/login');
                    }
                  },
                  child: Text(
                    'Login or Register',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Not Now',
                  style: TextStyle(color: context.colorTextSecondary),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }
}

// -- Validators --------------------------------------------------------------

class AppValidators {
  static String? bdPhone(String? value) => bangladeshPhone(value);

  static String? bangladeshPhone(String? value) {
    final text = value?.trim() ?? '';
    final normalized = text.startsWith('+880') ? '0${text.substring(4)}' : text;
    final regex = RegExp(r'^01[3-9][0-9]{8}$');
    if (normalized.isEmpty) return 'Phone number is required';
    if (!regex.hasMatch(normalized)) {
      return 'Enter a valid Bangladeshi phone number';
    }
    return null;
  }

  static String? requiredField(
    String? value, {
    String message = 'This field is required',
  }) {
    if ((value ?? '').trim().isEmpty) return message;
    return null;
  }

  static String? required(String? value) => requiredField(value);

  static String? otp(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'OTP is required';
    if (text.length != 6) return 'Enter a valid 6-digit OTP';
    return null;
  }
}

// -- Image Upload ------------------------------------------------------------

class ImageUploadUtil {
  static final ImagePicker _picker = ImagePicker();

  /// Picks an image and returns it as an XFile.
  /// XFile is cross-platform (Web/Mobile) and does not depend on dart:io.
  static Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 400,
        maxHeight: 400,
      );
      return image;
    } catch (e) {
      debugPrint("Error picking image: $e");
      return null;
    }
  }

  /// Picks an image and returns it as a base64 encoded string.
  /// This is used to stay within Firebase Firestore free tier limits (1MB document limit).
  static Future<String?> pickImageAsBase64({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final XFile? image = await pickImage(source: source);

      if (image == null) return null;

      final Uint8List imageBytes = await image.readAsBytes();

      // Firestore document limit is 1MB. We cap at 900KB to be safe.
      if (imageBytes.lengthInBytes > 900 * 1024) {
        debugPrint('Image too large: ${imageBytes.lengthInBytes} bytes');
        return 'TOO_LARGE';
      }

      final String base64String = base64Encode(imageBytes);
      return "data:image/jpeg;base64,$base64String";
    } catch (e) {
      debugPrint("Error picking image as base64: $e");
      return null;
    }
  }

  /// Converts a base64 encoded string to a Uint8List so it can be displayed using Image.memory()
  static Uint8List? base64ToImage(String base64String) {
    try {
      if (base64String.contains('base64,')) {
        base64String = base64String.split('base64,').last;
      }
      return base64Decode(base64String);
    } catch (e) {
      debugPrint("Error decoding base64 string: $e");
      return null;
    }
  }
}

// End of utils
