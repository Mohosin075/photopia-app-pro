import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguageController extends ChangeNotifier {
  static const String _storageKey = 'app_language';
  final GetStorage _storage = GetStorage();

  Locale _locale = const Locale('en');

  LanguageController() {
    _loadSavedLocale();
  }

  Locale get locale => _locale;

  String get languageName {
    if (_locale.languageCode == 'fr') return 'Français';
    return 'English';
  }

  bool get isFrench => _locale.languageCode == 'fr';

  void _loadSavedLocale() {
    final saved = _storage.read<String>(_storageKey);
    if (saved != null && saved != _locale.languageCode) {
      _locale = Locale(saved);
    }
  }

  void setLanguage(BuildContext context, String langCode) {
    debugPrint('LanguageController.setLanguage: target=$langCode, controller_locale=${_locale.languageCode}, easy_locale=${context.locale.languageCode}');
    if (_locale.languageCode == langCode && context.locale.languageCode == langCode) {
      debugPrint('LanguageController.setLanguage: locales match, returning');
      return;
    }
    _locale = Locale(langCode);
    _storage.write(_storageKey, langCode);
    debugPrint('LanguageController.setLanguage: calling context.setLocale(${_locale})');
    context.setLocale(_locale);
    notifyListeners();
  }

  void setEnglish(BuildContext context) => setLanguage(context, 'en');
  void setFrench(BuildContext context) => setLanguage(context, 'fr');
}
