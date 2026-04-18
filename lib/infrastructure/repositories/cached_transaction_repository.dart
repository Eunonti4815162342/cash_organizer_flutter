import '../../domain/models/transaction_item.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../services/api_service.dart';
import 'sqlite/sqlite_transaction_repository.dart';
import '../../service_locator.dart';

class CachedTransactionRepository implements ITransactionRepository {
  final ApiService _apiService = getIt<ApiService>();
  final SqliteTransactionRepository _localRepo = SqliteTransactionRepository();

  @override
  Future<List<TransactionItem>> fetchTransactions({String? startDate, String? endDate, String? accountId}) async {
    // 1. Intentar siempre la API primero
    try {
      final remoteTransactions = await _apiService.fetchTransactions(
        startDate: startDate,
        endDate: endDate,
        accountId: accountId,
      );
      
      // Si la API responde (aunque sea vacío), guardamos en local y devolvemos
      // Esto garantiza que el local sea un espejo fiel del servidor
      await _localRepo.saveAll(remoteTransactions);
      return remoteTransactions;
      
    } catch (e) {
      print('[CachedTransactionRepository] Error de red detectado. Cargando de SQLite...');
      // 2. Si falla la red (SocketException, Modo Avión), tiramos de SQLite
      return await _localRepo.fetchTransactions(
        startDate: startDate,
        endDate: endDate,
        accountId: accountId,
      );
    }
  }

  @override
  Future<void> saveTransaction(TransactionItem transaction, {bool isSynced = true}) async {
    // Siempre guardamos en local primero
    await _localRepo.saveTransaction(transaction, isSynced: isSynced);

    if (isSynced) {
      try {
        final result = await _apiService.createTransaction({
          'amount': {'value': transaction.amount.value, 'currency': transaction.amount.currency},
          'account': {'id': transaction.account.id},
          'type': transaction.type.name,
          'description': transaction.description,
          'date': transaction.date,
        });
        
        if (result != null) {
          await _localRepo.markAsSynced(transaction.id, result.id);
        }
      } catch (e) {
        // Si la subida falla, la transacción se queda en local marcada como pending_sync = 1
        print('[CachedTransactionRepository] No se pudo sincronizar. Pendiente para después.');
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
