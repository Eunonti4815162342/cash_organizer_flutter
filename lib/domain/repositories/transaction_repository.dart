import '../models/transaction_item.dart';
import '../models/transaction_filters.dart';

abstract class ITransactionRepository {
  Future<List<TransactionItem>> fetchTransactions(TransactionFilters filters);
  
  Future<TransactionItem> saveTransaction(TransactionItem transaction, {bool isSynced = true});
  Future<void> updateTransaction(TransactionItem transaction, {bool isSynced = true});
  Future<void> deleteTransaction(int id);
  Future<void> saveAll(List<TransactionItem> transactions);
  Future<TransactionItem?> getById(int id);
  
  // Sync methods
  Future<List<TransactionItem>> getPendingCreatesToSync();
  Future<List<TransactionItem>> getPendingToSync();
  Future<void> markAsSynced(int localId, int serverId);
}
