import '../models/transaction_item.dart';

abstract class ITransactionRepository {
  Future<List<TransactionItem>> fetchTransactions({String? startDate, String? endDate, String? accountId});
  Future<void> saveTransaction(TransactionItem transaction, {bool isSynced = true});
  Future<void> updateTransaction(TransactionItem transaction, {bool isSynced = true});
  Future<void> saveAll(List<TransactionItem> transactions);
  Future<List<TransactionItem>> getPendingToSync();
  Future<List<TransactionItem>> getPendingUpdatesToSync();
  Future<void> markAsSynced(int localId, int serverId);
}
