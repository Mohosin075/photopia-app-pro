import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends ChangeNotifier {
  static const String _storageKey = 'app_theme_mode';
  final GetStorage _storage = GetStorage();

  ThemeMode _themeMode = ThemeMode.system;

  ThemeController() {
    _loadSavedThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void _loadSavedThemeMode() {
    final saved = _storage.read<String>(_storageKey);
    if (saved != null) {
      switch (saved) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'system':
          _themeMode = ThemeMode.system;
          break;
      }
    }
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    
    String modeString = 'system';
    if (mode == ThemeMode.light) modeString = 'light';
    if (mode == ThemeMode.dark) modeString = 'dark';
    
    _storage.write(_storageKey, modeString);
    notifyListeners();
  }

  void toggleTheme() {
    if (isDarkMode) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}
