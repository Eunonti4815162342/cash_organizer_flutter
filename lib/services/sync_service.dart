import 'dart:async';
import '../infrastructure/repositories/cached_transaction_repository.dart';
import '../domain/repositories/transaction_repository.dart';
import 'api_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ITransactionRepository _transactionRepo = CachedTransactionRepository();
  final ApiService _apiService = ApiService();
  Timer? _syncTimer;

  void startAutoSync({int intervalSeconds = 60}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(Duration(seconds: intervalSeconds), (_) => performSync());
    print('[SyncService] Auto-sync started (every $intervalSeconds seconds)');
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
    print('[SyncService] Auto-sync stopped');
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
