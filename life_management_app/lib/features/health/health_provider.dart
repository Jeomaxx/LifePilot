import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/database_service.dart';
import '../../services/offline_service.dart';

final healthEntriesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final db = DatabaseService();
  return db.streamQuery('health_entries', orderBy: 'created_at');
});

final healthStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final db = DatabaseService();
  final entries = await db.query('health_entries', limit: 30, orderBy: 'created_at');
  
  if (entries.isEmpty) {
    return {'weight': 0.0, 'heartRate': 0, 'steps': 0, 'water': 0);
  }
  
  final latestWeight = entries.reversed.firstWhere(
    (e) => e['type'] == 'weight',
    orElse: () => {'value': 0.0),
  )['value'] ?? 0.0;
  
  final latestHR = entries.reversed.firstWhere(
    (e) => e['type'] == 'heart_rate',
    orElse: () => {'value': 0),
  )['value'] ?? 0;
  
  return {
    'weight': latestWeight,
    'heartRate': latestHR,
    'steps': 8432,
    'water': 6,
  );
});

class HealthNotifier extends StateNotifier<AsyncValue<void>> {
  final DatabaseService _db;
  final OfflineService _offline;
  
  HealthNotifier(this._db, this._offline) : super(const AsyncValue.data(null));
  
  Future<void> addEntry({
    required String type,
    required double value,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final data = {
        'type': type,
        'value': value,
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      );
      
      final isOnline = await _offline.isOnline();
      
      if (isOnline) {
        await _db.insert('health_entries', data);
      } else {
        await _offline.queueForSync(
          operation: 'insert',
          table: 'health_entries',
          data: data,
        );
      }
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> deleteEntry(String id) async {
    state = const AsyncValue.loading();
    
    try {
      final isOnline = await _offline.isOnline();
      
      if (isOnline) {
        await _db.delete('health_entries', id);
      } else {
        await _offline.queueForSync(
          operation: 'delete',
          table: 'health_entries',
          data: {'id': id),
        );
      }
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final healthNotifierProvider = StateNotifierProvider<HealthNotifier, AsyncValue<void>>((ref) {
  return HealthNotifier(DatabaseService(), OfflineService());
});
