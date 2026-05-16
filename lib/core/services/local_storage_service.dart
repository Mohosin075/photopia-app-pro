import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

class LocalStorageService {
  static const String cacheBoxName = 'api_cache_box';
  static const String pendingRequestsBoxName = 'pending_requests_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(cacheBoxName);
    await Hive.openBox(pendingRequestsBoxName);
    debugPrint('📦 [LocalStorageService] Hive initialized and boxes opened.');
  }

  // --- Cache Storage Methods ---

  /// Save raw JSON response to cache
  static Future<void> saveCache(String key, dynamic data) async {
    final box = Hive.box(cacheBoxName);
    await box.put(key, data);
  }

  /// Get cached data
  static dynamic getCache(String key) {
    final box = Hive.box(cacheBoxName);
    return box.get(key);
  }

  /// Check if cache exists
  static bool hasCache(String key) {
    final box = Hive.box(cacheBoxName);
    return box.containsKey(key);
  }

  /// Clear all cache
  static Future<void> clearCache() async {
    final box = Hive.box(cacheBoxName);
    await box.clear();
    debugPrint('📦 [LocalStorageService] Cache cleared.');
  }

  // --- Pending Requests Methods ---

  /// Save a pending API request for offline sync
  static Future<void> savePendingRequest(String id, Map<String, dynamic> requestData) async {
    final box = Hive.box(pendingRequestsBoxName);
    await box.put(id, requestData);
    debugPrint('📦 [LocalStorageService] Saved pending request: $id');
  }

  /// Get all pending requests
  static List<Map<String, dynamic>> getAllPendingRequests() {
    final box = Hive.box(pendingRequestsBoxName);
    final List<Map<String, dynamic>> requests = [];
    for (var key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        requests.add(Map<String, dynamic>.from(value));
      }
    }
    return requests;
  }

  /// Remove a processed pending request
  static Future<void> removePendingRequest(String id) async {
    final box = Hive.box(pendingRequestsBoxName);
    await box.delete(id);
    debugPrint('📦 [LocalStorageService] Removed pending request: $id');
  }
}
