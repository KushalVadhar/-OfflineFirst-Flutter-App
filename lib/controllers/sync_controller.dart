import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/sync/sync_engine.dart';
import '../services/sync/sync_queue_logic.dart';
import '../utils/app_logger.dart';

class SyncController with ChangeNotifier {
  final SyncEngine _syncEngine;
  final SyncQueueLogic _syncQueue;
  
  bool _isOnline = true;
  bool _isSyncing = false;
  int _pendingCount = 0;
  int _successCount = 0;
  int _failureCount = 0;

  StreamSubscription? _connectivitySubscription;

  SyncController({
    required SyncEngine syncEngine,
    required SyncQueueLogic syncQueue,
  })  : _syncEngine = syncEngine,
        _syncQueue = syncQueue {
    _init();
  }

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;
  int get successCount => _successCount;
  int get failureCount => _failureCount;

  void _init() {
    _updateQueueStats();
    
    // Listen to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      bool online = false;
      if (results is List) {
        final list = results as List;
        online = !list.contains(ConnectivityResult.none) && list.isNotEmpty;
      } else {
        online = results != ConnectivityResult.none;
      }
      
      if (online != _isOnline) {
        _isOnline = online;
        AppLogger.i("[SYNC] Connectivity changed: ${_isOnline ? 'Online' : 'Offline'}");
        if (_isOnline) {
          triggerSync();
        }
        notifyListeners();
      }
    });
  }

  void _updateQueueStats() {
    final obs = _syncEngine.observability;
    _pendingCount = _syncQueue.pendingCount;
    _successCount = obs.syncSuccessCount;
    _failureCount = obs.syncFailCount;
    notifyListeners();
  }

  Future<void> triggerSync() async {
    if (!_isOnline || _isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      await _syncEngine.processAll();
      _successCount++; // This is a simplified counter, could be more granular
    } catch (e) {
      _failureCount++;
      AppLogger.e("[SYNC] Sync trigger failed: $e");
    } finally {
      _isSyncing = false;
      _updateQueueStats();
    }
  }

  Future<void> enqueueAction({
    required String actionType,
    required String entityId,
    String payload = '{}',
  }) async {
    await _syncEngine.enqueueAction(
      actionType: actionType,
      entityId: entityId,
      payload: payload,
    );
    _updateQueueStats();
    
    // Auto-trigger if online
    if (_isOnline) {
      triggerSync();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
