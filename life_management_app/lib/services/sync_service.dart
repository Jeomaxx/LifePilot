import 'package:connectivity_plus/connectivity_plus.dart';

class SyncService {
  static Future<void> initialize() async {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        _syncData();
      }
    });
  }
  
  static Future<void> _syncData() async {
  }
}
