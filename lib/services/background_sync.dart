abstract class BackgroundSync {
  Future<void> initialize();
  void scheduleTask();
}

// Fábrica para obtener la implementación correcta según la plataforma
BackgroundSync getSyncManager() => throw UnsupportedError('Cannot create sync manager');
