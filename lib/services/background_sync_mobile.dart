import 'package:workmanager/workmanager.dart';
import 'background_sync.dart';
import 'sync_service.dart';

const String syncTaskName = "com.natave.syncTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final SyncService syncService = SyncService();
    try {
      await syncService.performSync();
      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

class MobileSyncManager implements BackgroundSync {
  @override
  Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  @override
  void scheduleTask() {
    Workmanager().registerPeriodicTask(
      "1", 
      syncTaskName,
      frequency: const Duration(minutes: 15), 
      constraints: Constraints(
        networkType: NetworkType.connected, 
        requiresBatteryNotLow: true,      
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }
}

BackgroundSync getSyncManager() => MobileSyncManager();
