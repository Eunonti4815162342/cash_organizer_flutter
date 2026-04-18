import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final _controller = StreamController<bool>.broadcast();
  StreamSubscription? _sub;
  bool _isOffline = false;

  Stream<bool> get offlineStream => _controller.stream;
  bool get isOffline => _isOffline;

  void initialize() {
    if (kIsWeb) return;
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (offline != _isOffline) {
        _isOffline = offline;
        _controller.add(_isOffline);
      }
    });
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
