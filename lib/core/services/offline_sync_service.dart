import 'package:flutter/foundation.dart';
import 'package:photopya/core/services/local_storage_service.dart';
import 'package:photopya/core/services/connectivity_service.dart';
import 'package:photopya/core/network/Api_service/network_caller.dart';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  bool _isSyncing = false;

  void init() {
    // Listen to connectivity changes to trigger auto-sync
    ConnectivityService().addListener(_onConnectivityChanged);
    debugPrint('🔄 [OfflineSyncService] Initialized and listening to connectivity.');
  }

  void _onConnectivityChanged() {
    if (ConnectivityService().isOnline) {
      debugPrint('🔄 [OfflineSyncService] Internet restored. Triggering auto-sync...');
      syncPendingRequests();
    }
  }

  /// Queue a request to be executed later when online
  static Future<void> queueRequest({
    required String url,
    required String method,
    Map<String, dynamic>? body,
    required String actionType, // 'pending_create', 'pending_update', 'pending_delete'
  }) async {
    final String id = '${actionType}_${DateTime.now().millisecondsSinceEpoch}';
    final requestData = {
      'id': id,
      'url': url,
      'method': method,
      'body': body,
      'actionType': actionType,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await LocalStorageService.savePendingRequest(id, requestData);
    debugPrint('🔄 [OfflineSyncService] Queued offline action: $actionType for $url');
  }

  /// Process all queued requests
  Future<void> syncPendingRequests() async {
    if (_isSyncing) {
      debugPrint('🔄 [OfflineSyncService] Sync already in progress.');
      return;
    }
    
    if (!ConnectivityService().isOnline) {
      debugPrint('🔄 [OfflineSyncService] Cannot sync. Offline.');
      return;
    }

    final pendingRequests = LocalStorageService.getAllPendingRequests();
    if (pendingRequests.isEmpty) {
      debugPrint('🔄 [OfflineSyncService] No pending requests to sync.');
      return;
    }

    _isSyncing = true;
    debugPrint('🔄 [OfflineSyncService] Starting sync of ${pendingRequests.length} items...');

    // Sort by timestamp to maintain order of operations
    pendingRequests.sort((a, b) => (a['timestamp'] as String).compareTo(b['timestamp'] as String));

    for (var request in pendingRequests) {
      final String id = request['id'];
      final String url = request['url'];
      final String method = request['method'];
      final Map<String, dynamic>? body = request['body'];

      debugPrint('🔄 [OfflineSyncService] Syncing item $id: $method $url');
      
      bool success = false;
      try {
        if (method == 'POST') {
          final response = await NetworkCaller.postRequest(url: url, body: body ?? {});
          success = response.isSuccess;
        } else if (method == 'PUT') {
          // Assuming PUT requires body
          // final response = await NetworkCaller.putRequest(url: url, body: body ?? {});
          // success = response.isSuccess;
        } else if (method == 'DELETE') {
          // final response = await NetworkCaller.deleteRequest(url: url);
          // success = response.isSuccess;
        }
        
        if (success) {
          debugPrint('✅ [OfflineSyncService] Successfully synced $id');
          await LocalStorageService.removePendingRequest(id);
        } else {
          debugPrint('❌ [OfflineSyncService] Failed to sync $id. Keeping in queue.');
        }
      } catch (e) {
        debugPrint('❌ [OfflineSyncService] Exception syncing $id: $e');
      }
    }

    _isSyncing = false;
    debugPrint('🔄 [OfflineSyncService] Sync completed.');
  }
}
