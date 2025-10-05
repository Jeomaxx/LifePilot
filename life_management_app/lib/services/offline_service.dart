import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SyncQueueItem {
  final String operation;
  final String table;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  SyncQueueItem({
    required this.operation,
    required this.table,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'operation': operation,
      'table': table,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    );
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      operation: map['operation'] as String,
      table: map['table'] as String,
      data: Map<String, dynamic>.from(map['data'] as Map),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

class OfflineService {
  static const String _syncQueueBox = 'sync_queue';
  static const String _cacheBox = 'cache';
  
  static Future<void> initialize() async {
    try {
      await Hive.openBox<Map>(_syncQueueBox);
      await Hive.openBox<Map>(_cacheBox);
    } catch (e) {
      print('Error initializing offline service: $e');
    }
  }
  
  Future<void> cacheData(String key, Map<String, dynamic> data) async {
    try {
      final box = Hive.box<Map>(_cacheBox);
      await box.put(key, data);
    } catch (e) {
      print('Error caching data: $e');
    }
  }
  
  Map<String, dynamic>? getCachedData(String key) {
    try {
      final box = Hive.box<Map>(_cacheBox);
      final data = box.get(key);
      return data != null ? Map<String, dynamic>.from(data) : null;
    } catch (e) {
      print('Error getting cached data: $e');
      return null;
    }
  }
  
  Future<void> queueForSync({
    required String operation,
    required String table,
    required Map<String, dynamic> data,
  }) async {
    try {
      final box = Hive.box<Map>(_syncQueueBox);
      final item = SyncQueueItem(
        operation: operation,
        table: table,
        data: data,
        timestamp: DateTime.now(),
      );
      await box.add(item.toMap());
    } catch (e) {
      print('Error queuing for sync: $e');
    }
  }
  
  Future<List<SyncQueueItem>> getPendingSync() async {
    try {
      final box = Hive.box<Map>(_syncQueueBox);
      return box.values
          .map((map) => SyncQueueItem.fromMap(Map<String, dynamic>.from(map)))
          .toList();
    } catch (e) {
      print('Error getting pending sync: $e');
      return [];
    }
  }
  
  Future<void> removeSyncItem(int index) async {
    try {
      final box = Hive.box<Map>(_syncQueueBox);
      await box.deleteAt(index);
    } catch (e) {
      print('Error removing sync item: $e');
    }
  }
  
  Future<void> clearSyncQueue() async {
    try {
      final box = Hive.box<Map>(_syncQueueBox);
      await box.clear();
    } catch (e) {
      print('Error clearing sync queue: $e');
    }
  }
  
  Future<bool> isOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }
  
  Stream<List<ConnectivityResult>> get connectivityStream {
    return Connectivity().onConnectivityChanged;
  }
}
