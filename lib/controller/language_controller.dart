import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class LanguageController extends ChangeNotifier {
  static const String _storageKey = 'app_language';
  final GetStorage _storage = GetStorage();

  Locale _locale = const Locale('en');

  LanguageController() {
    _loadSavedLocale();
  }

  Locale get locale => _locale;

  String get languageName =>
      _locale.languageCode == 'fr' ? 'French' : 'English';

  bool get isFrench => _locale.languageCode == 'fr';

  void _loadSavedLocale() {
    final saved = _storage.read<String>(_storageKey);
    if (saved != null && saved != _locale.languageCode) {
      _locale = Locale(saved);
    }
  }

  void setLanguage(String langCode) {
    if (_locale.languageCode == langCode) return;
    _locale = Locale(langCode);
    _storage.write(_storageKey, langCode);
    notifyListeners();
  }

  void setEnglish() => setLanguage('en');
  void setFrench() => setLanguage('fr');
}
