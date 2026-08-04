// ============================================================================
// HealMeal Localization
// Merged from: app_localizations, locale_cubit
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'strings_en.dart';
export 'strings_en.dart';
import 'strings_bn.dart';

// -- Locale Cubit ------------------------------------------------------------

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(Locale('en'));

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language_code') ?? 'en';
    emit(Locale(langCode));
  }

  Future<void> setEnglish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', 'en');
    emit(Locale('en'));
  }

  Future<void> setBangla() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', 'bn');
    emit(Locale('bn'));
  }
}

// -- Localization Helpers ----------------------------------------------------

class L {
  static final AppStringsEn _en = AppStringsEn();
  static final AppStringsBn _bn = AppStringsBn();

  static String str(
    BuildContext context,
    String Function(AppStringsEn) enFn,
    String Function(AppStringsBn) bnFn,
  ) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'bn') {
      return bnFn(_bn);
    }
    return enFn(_en);
  }
}

extension LocalizationExtension on BuildContext {
  bool get isBangla => Localizations.localeOf(this).languageCode == 'bn';

  String tr(String enText, String bnText) => isBangla ? bnText : enText;

  AppStrings get strings => isBangla ? AppStringsBn() : AppStringsEn();
}
