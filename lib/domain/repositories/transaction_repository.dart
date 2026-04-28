import '../models/transaction_item.dart';

abstract class ITransactionRepository {
  Future<List<TransactionItem>> fetchTransactions({String? startDate, String? endDate, String? accountId});
  Future<TransactionItem> saveTransaction(TransactionItem transaction, {bool isSynced = true});
  Future<void> updateTransaction(TransactionItem transaction, {bool isSynced = true});
  Future<void> deleteTransaction(int id);
  Future<void> saveAll(List<TransactionItem> transactions);
  Future<TransactionItem?> getById(int id);
  Future<List<TransactionItem>> getPendingCreatesToSync();
  Future<List<TransactionItem>> getPendingToSync(); // para updates (pending_sync=2)
  Future<void> markAsSynced(int localId, int serverId);
}
