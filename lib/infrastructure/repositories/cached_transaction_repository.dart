import '../../domain/models/transaction_item.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../services/api_service.dart';
import 'sqlite/sqlite_transaction_repository.dart';

class CachedTransactionRepository implements ITransactionRepository {
  final ApiService _apiService = ApiService();
  final SqliteTransactionRepository _localRepo = SqliteTransactionRepository();

  @override
  Future<List<TransactionItem>> fetchTransactions({String? startDate, String? endDate, String? accountId}) async {
    try {
      // 1. Intentar obtener transacciones remotas
      final remoteTransactions = await _apiService.fetchTransactions(
        startDate: startDate,
        endDate: endDate,
        accountId: accountId,
      );
      
      if (remoteTransactions.isNotEmpty) {
        // 2. Si hay éxito, cachearlas en local
        await _localRepo.saveAll(remoteTransactions);
        return remoteTransactions;
      }
    } catch (e) {
      print('[CachedTransactionRepository] Error fetching remote, falling back to local: $e');
    }

    // 3. Si falla o estamos offline, devolver de SQLite
    return await _localRepo.fetchTransactions();
  }

  @override
  Future<void> saveTransaction(TransactionItem transaction, {bool isSynced = true}) async {
    // 1. Guardar localmente de inmediato (Offline first)
    // Si isSynced es falso, se guardará con flag 'pendingSync'
    await _localRepo.saveTransaction(transaction, isSynced: isSynced);

    if (isSynced) {
      // Intentar subir al servidor
      final result = await _apiService.createTransaction({
        'amount': {'value': transaction.amount.value, 'currency': transaction.amount.currency},
        'account': {'id': transaction.account.id},
        'type': transaction.type.name,
        'description': transaction.description,
        'date': transaction.date,
      });
      
      if (result != null) {
        // Si subió bien, marcar como sincronizado localmente con su server_id
        await _localRepo.markAsSynced(transaction.id, result.id);
      }
    }
  }

  @override
  Future<void> saveAll(List<TransactionItem> transactions) async {
    await _localRepo.saveAll(transactions);
  }

  @override
  Future<List<TransactionItem>> getPendingToSync() {
    return _localRepo.getPendingToSync();
  }

  @override
  Future<void> markAsSynced(int localId, int serverId) {
    return _localRepo.markAsSynced(localId, serverId);
  }
}
