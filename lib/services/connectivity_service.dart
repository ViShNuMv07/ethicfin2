import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';


class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool isOnline = true;

  Stream<bool> get onStatusChange => _controller.stream;

  Future<void> init() async {
    final initial = await _connectivity.checkConnectivity();
    isOnline = _hasConnection(initial);
    _controller.add(isOnline);

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = _hasConnection(results);
      if (online != isOnline) {
        isOnline = online;
        _controller.add(isOnline);
      }
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<bool> checkNow() async {
    final result = await _connectivity.checkConnectivity();
    isOnline = _hasConnection(result);
    return isOnline;
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
