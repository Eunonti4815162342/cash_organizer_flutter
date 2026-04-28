import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'sync_service.dart';

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
      // Consideramos OFFLINE solo si no hay ninguna interfaz activa (WiFi, Móvil, Ethernet, VPN...)
      // Si la lista contiene algo distinto a 'none', intentamos ser optimistas
      final offline = results.isEmpty || results.every((r) => r == ConnectivityResult.none);
      
      if (offline != _isOffline) {
        _isOffline = offline;
        _controller.add(_isOffline);

        if (!_isOffline) {
          // Pequeño delay para que la interfaz se estabilice antes de sincronizar
          Future.delayed(const Duration(seconds: 1), () {
            SyncService().performSync();
          });
        }
      }
    });
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
