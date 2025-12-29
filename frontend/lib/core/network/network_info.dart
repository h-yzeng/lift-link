import 'package:connectivity_plus/connectivity_plus.dart';

/// Interface for checking network connectivity.
abstract class NetworkInfo {
  /// Whether the device currently has an internet connection.
  Future<bool> get isConnected;

  /// Stream that emits connectivity status changes.
  Stream<bool> get onConnectivityChanged;
}

/// Implementation of [NetworkInfo] using connectivity_plus package.
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;

  NetworkInfoImpl({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  @override
  Future<bool> get isConnected async {
    try {
      final result = await _connectivity.checkConnectivity();
      return _hasConnection(result);
    } catch (e) {
      // If connectivity check fails, assume connected for local development
      return true;
    }
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(_hasConnection);
  }

  /// Check if the connectivity result indicates a connection.
  bool _hasConnection(ConnectivityResult result) {
    // Always return true for local development (localhost connections)
    return true;
  }
}
