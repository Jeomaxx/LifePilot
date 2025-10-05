import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'offline_service.dart';

class SyncService {
  static final OfflineService _offlineService = OfflineService();
  static final _supabase = Supabase.instance.client;
  static bool _isSyncing = false;
  
  static Future<void> initialize() async {
    Connectivity().onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        await syncPendingChanges();
      }
    });
    
    final isOnline = await _offlineService.isOnline();
    if (isOnline) {
      await syncPendingChanges();
    }
  }
  
  static Future<void> syncPendingChanges() async {
    if (_isSyncing) return;
    _isSyncing = true;
    
    try {
      final pendingItems = await _offlineService.getPendingSync();
      
      for (var i = pendingItems.length - 1; i >= 0; i--) {
        final item = pendingItems[i];
        
        try {
          switch (item.operation) {
            case 'insert':
              await _supabase.from(item.table).insert(item.data);
              break;
            case 'update':
              await _supabase
                  .from(item.table)
                  .update(item.data)
                  .eq('id', item.data['id']);
              break;
            case 'delete':
              await _supabase
                  .from(item.table)
                  .delete()
                  .eq('id', item.data['id']);
              break;
          }
          
          await _offlineService.removeSyncItem(i);
          print('Successfully synced ${item.operation} on ${item.table}');
        } catch (e) {
          print('Error syncing item ${item.operation} on ${item.table}: $e');
        }
      }
    } catch (e) {
      print('Error in sync process: $e');
    } finally {
      _isSyncing = false;
    }
  }
  
  static Future<void> forceSyncNow() async {
    final isOnline = await _offlineService.isOnline();
    if (isOnline) {
      await syncPendingChanges();
    }
  }
}
