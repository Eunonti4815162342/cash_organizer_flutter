import 'dart:async';
import 'package:workmanager/workmanager.dart';
import '../infrastructure/repositories/cached_transaction_repository.dart';
import '../domain/repositories/transaction_repository.dart';
import 'api_service.dart';

const String syncTaskName = "com.cashorganizer.syncTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("[BackgroundWorkManager] Executing background sync task: $task");
    
    // In background isolates, we must initialize what we need.
    final SyncService syncService = SyncService();
    try {
      await syncService.performSync();
      return Future.value(true);
    } catch (e) {
      print("[BackgroundWorkManager] Sync failed: $e");
      return Future.value(false);
    }
  });
}

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ITransactionRepository _transactionRepo = CachedTransactionRepository();
  final ApiService _apiService = ApiService();

  Future<void> initializeWorkmanager() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Cambiar a true para ver notificaciones de ejecución en desarrollo
    );
  }

  void scheduleSyncTask() {
    print('[SyncService] Scheduling native background sync...');
    // Programar tarea periódica con restricciones inteligentes de batería (Android)
    Workmanager().registerPeriodicTask(
      "1", // ID único
      syncTaskName,
      frequency: const Duration(minutes: 15), // Android mínimo son 15 min por diseño del SO
      constraints: Constraints(
        networkType: NetworkType.connected, // Solo con Internet
        requiresBatteryNotLow: true,      // No si tiene batería baja
        requiresCharging: false,           // Podríamos ponerlo en true si el cliente es muy estricto
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  Future<void> performSync() async {
    final bool online = await _apiService.isOnline();
    if (!online) return;

    final pending = await _transactionRepo.getPendingToSync();
    if (pending.isEmpty) return;

    print('[SyncService] Syncing ${pending.length} pending transactions...');

    for (var tx in pending) {
      try {
        final result = await _apiService.createTransaction({
          'amount': {'value': tx.amount.value, 'currency': tx.amount.currency},
          'account': {'id': tx.account.id},
          'type': tx.type.name,
          'description': tx.description,
          'date': tx.date,
        });

        if (result != null) {
          await _transactionRepo.markAsSynced(tx.id, result.id);
          print('[SyncService] Transaction ${tx.id} synced with server ID ${result.id}');
        }
      } catch (e) {
        print('[SyncService] Failed to sync transaction ${tx.id}: $e');
      }
    }
  }
}
