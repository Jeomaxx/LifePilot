import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final _supabase = Supabase.instance.client;
  
  Future<List<Map<String, dynamic>>> query(String table, {
    String? select,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    dynamic query = _supabase.from(table).select(select ?? '*');
    
    if (filters != null) {
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });
    }
    
    if (orderBy != null) {
      query = query.order(orderBy, ascending: ascending);
    }
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return await query;
  }
  
  Future<Map<String, dynamic>> insert(String table, Map<String, dynamic> data) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      data['user_id'] = userId;
    }
    
    return await _supabase.from(table).insert(data).select().single();
  }
  
  Future<Map<String, dynamic>> update(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _supabase
        .from(table)
        .update(data)
        .eq('id', id)
        .select()
        .single();
  }
  
  Future<void> delete(String table, String id) async {
    await _supabase.from(table).delete().eq('id', id);
  }
  
  Stream<List<Map<String, dynamic>>> streamQuery(
    String table, {
    String? select,
    Map<String, dynamic>? filters,
    String? orderBy,
  }) {
    final stream = _supabase
        .from(table)
        .stream(primaryKey: ['id']);
    
    return stream.map((data) {
      var result = data.map((item) => Map<String, dynamic>.from(item)).toList();
      
      if (filters != null) {
        result = result.where((item) {
          return filters.entries.every((entry) => item[entry.key] == entry.value);
        }).toList();
      }
      
      if (orderBy != null) {
        result.sort((a, b) => 
          (a[orderBy] ?? '').toString().compareTo((b[orderBy] ?? '').toString())
        );
      }
      
      return result;
    });
  }
}
