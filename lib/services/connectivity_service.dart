import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();

  static Future<bool> get hasInternet async {
    if (kIsWeb) return true;
    try {
      final result = await _connectivity.checkConnectivity();
      if (result.contains(ConnectivityResult.none) || result.isEmpty) {
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('[ConnectivityService] Check error: $e');
      return true;
    }
  }

  static Stream<bool> get onConnectivityChanged {
    if (kIsWeb) {
      return Stream.value(true);
    }
    try {
      return _connectivity.onConnectivityChanged.map(
        (result) => !(result.contains(ConnectivityResult.none) || result.isEmpty),
      );
    } catch (_) {
      return Stream.value(true);
    }
  }
}
