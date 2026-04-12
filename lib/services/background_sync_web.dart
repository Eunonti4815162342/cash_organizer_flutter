import 'background_sync.dart';

class WebSyncManager implements BackgroundSync {
  @override
  Future<void> initialize() async {
    print('[Sync] Background sync not supported on Web');
  }

  @override
  void scheduleTask() {
    // No hace nada en Web
  }
}

BackgroundSync getSyncManager() => WebSyncManager();
