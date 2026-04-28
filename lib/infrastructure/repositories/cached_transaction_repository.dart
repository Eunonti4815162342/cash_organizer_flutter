import 'package:flutter/foundation.dart' show kIsWeb;
import '../../domain/models/transaction_item.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../services/api_service.dart';
import '../../service_locator.dart';

class CachedTransactionRepository implements ITransactionRepository {
  final ApiService _apiService = getIt<ApiService>();
  ITransactionRepository? get _localRepo => kIsWeb ? null : getIt<ITransactionRepository>(instanceName: 'local_transaction');

  @override
  Future<List<TransactionItem>> fetchTransactions({String? startDate, String? endDate, String? accountId}) async {
    if (!kIsWeb) {
      final local = await _localRepo?.fetchTransactions(startDate: startDate, endDate: endDate, accountId: accountId) ?? [];
      if (local.isNotEmpty) {
        _refreshInBackground(startDate, endDate, accountId);
        return local;
      }
    }

    try {
      final remote = await _apiService.fetchTransactions(startDate: startDate, endDate: endDate, accountId: accountId);
      if (remote.isNotEmpty && !kIsWeb) {
        await _localRepo?.saveAll(remote);
      }
      return remote;
    } catch (e) {
      return [];
    }
  }

  Future<void> _refreshInBackground(String? start, String? end, String? accId) async {
    try {
      final remote = await _apiService.fetchTransactions(startDate: start, endDate: end, accountId: accId);
      if (remote.isNotEmpty && !kIsWeb) {
        await _localRepo?.saveAll(remote);
      }
    } catch (_) {}
  }

  @override
  Future<TransactionItem> saveTransaction(TransactionItem transaction, {bool isSynced = true}) async {
    if (kIsWeb) {
      final remote = await _apiService.createTransaction(transaction.toJson());
      return remote ?? transaction;
    }
    
    final saved = await _localRepo!.saveTransaction(transaction, isSynced: false);
    _apiService.createTransaction(transaction.toJson()).then((remote) {
      if (remote != null) _localRepo?.markAsSynced(saved.id, remote.id);
    }).catchError((_) {
      return null; // Devolvemos null explícito para evitar error de tipo
    });
    
    return saved;
  }

  @override
  Future<void> updateTransaction(TransactionItem transaction, {bool isSynced = true}) async {
    if (kIsWeb) {
      await _apiService.updateTransaction(transaction.id, transaction.toJson());
      return;
    }
    await _localRepo!.updateTransaction(transaction, isSynced: false);
    _apiService.updateTransaction(transaction.id, transaction.toJson()).catchError((_) {
      return null;
    });
  }

  @override
  Future<void> deleteTransaction(int id) async {
    if (!kIsWeb) await _localRepo?.deleteTransaction(id);
    _apiService.deleteTransaction(id).catchError((_) {
      return false; // deleteTransaction suele devolver Future<bool> en la API
    });
  }

  @override
  Future<void> saveAll(List<TransactionItem> transactions) async {
    if (!kIsWeb) await _localRepo?.saveAll(transactions);
  }

  @override
  Future<TransactionItem?> getById(int id) async {
    if (kIsWeb) return null;
    return await _localRepo?.getById(id);
  }

  @override
  Future<List<TransactionItem>> getPendingCreatesToSync() => _localRepo?.getPendingCreatesToSync() ?? Future.value([]);
  
  @override
  Future<List<TransactionItem>> getPendingToSync() => _localRepo?.getPendingToSync() ?? Future.value([]);
  
  @override
  Future<void> markAsSynced(int localId, int serverId) => _localRepo?.markAsSynced(localId, serverId) ?? Future.value();
}
