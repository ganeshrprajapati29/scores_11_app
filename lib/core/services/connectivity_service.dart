import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  Future<bool> isConnected() async {
    // connectivity_plus 6 returns a list; comparing the list itself to
    // `none` was always true, so the app thought it was always online.
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

/// Returns a stream of single [ConnectivityResult] by mapping from the list
  Stream<ConnectivityResult> get connectivityStream =>
      _connectivity.onConnectivityChanged.map((results) {
        // Return the first non-none result, or none if all are none
        return results.isNotEmpty ? results.first : ConnectivityResult.none;
      });
}
