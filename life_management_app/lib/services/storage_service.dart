import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class StorageService {
  final _supabase = Supabase.instance.client;
  
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required dynamic file,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      String fullPath = '$userId/$path';
      
      if (kIsWeb) {
        if (file is Uint8List) {
          await _supabase.storage.from(bucket).uploadBinary(fullPath, file);
        } else if (file is List<int>) {
          await _supabase.storage.from(bucket).uploadBinary(
                fullPath,
                Uint8List.fromList(file),
              );
        } else {
          throw Exception('Invalid file type for web upload');
        }
      } else {
        if (file is String) {
          await _supabase.storage.from(bucket).upload(fullPath, File(file));
        } else if (file is File) {
          await _supabase.storage.from(bucket).upload(fullPath, file);
        } else {
          throw Exception('Invalid file type for mobile upload');
        }
      }
      
      return _supabase.storage.from(bucket).getPublicUrl(fullPath);
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }
  
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      String fullPath = '$userId/$path';
      await _supabase.storage.from(bucket).remove([fullPath]);
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }
  
  String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    String fullPath = '$userId/$path';
    return _supabase.storage.from(bucket).getPublicUrl(fullPath);
  }
  
  Future<List<FileObject>> listFiles({
    required String bucket,
    String? path,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      String fullPath = path != null ? '$userId/$path' : userId;
      return await _supabase.storage.from(bucket).list(path: fullPath);
    } catch (e) {
      throw Exception('Failed to list files: $e');
    }
  }
}
