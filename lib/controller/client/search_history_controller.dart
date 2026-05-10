import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class SearchHistoryController extends ChangeNotifier {
  static const String _storageKey = 'recent_searches';
  final GetStorage _storage = GetStorage();
  List<String> _recentSearches = [];

  SearchHistoryController() {
    _loadHistory();
  }

  List<String> get recentSearches => _recentSearches;

  void _loadHistory() {
    final List<dynamic>? stored = _storage.read<List<dynamic>>(_storageKey);
    if (stored != null) {
      _recentSearches = stored.cast<String>();
    }
    notifyListeners();
  }

  void addSearchTerm(String term) {
    if (term.trim().isEmpty) return;
    
    // Remove if already exists to move it to the top
    _recentSearches.remove(term.trim());
    
    // Insert at the beginning
    _recentSearches.insert(0, term.trim());
    
    // Keep only the last 10
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }
    
    _saveHistory();
  }

  void removeSearchTerm(String term) {
    _recentSearches.remove(term);
    _saveHistory();
  }

  void clearHistory() {
    _recentSearches.clear();
    _saveHistory();
  }

  void _saveHistory() {
    _storage.write(_storageKey, _recentSearches);
    notifyListeners();
  }
}
