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
  bool _isOffline = false; // Iniciamos asumiendo que hay conexión (optimismo)

  Stream<bool> get offlineStream => _controller.stream;
  bool get isOffline => _isOffline;

  void initialize() {
    // Escuchamos cambios en todas las plataformas
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });

    // Verificación inicial inmediata
    Connectivity().checkConnectivity().then(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // Consideramos OFFLINE solo si explícitamente se nos dice que no hay conexión (none) o si la lista está vacía
    final offline = results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    
    if (offline != _isOffline) {
      _isOffline = offline;
      _controller.add(_isOffline);

      if (!_isOffline) {
        // Al recuperar conexión, disparamos sincronización
        Future.delayed(const Duration(seconds: 1), () {
          SyncService().performSync();
        });
      }
    }
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
