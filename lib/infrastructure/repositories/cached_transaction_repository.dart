import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:natave_flutter/domain/models/transaction_item.dart';
import 'package:natave_flutter/domain/models/transaction_filters.dart';
import 'package:natave_flutter/domain/repositories/transaction_repository.dart';
import 'package:natave_flutter/services/api_service.dart';
import 'package:natave_flutter/service_locator.dart';

class CachedTransactionRepository implements ITransactionRepository {
  final ApiService _apiService = getIt<ApiService>();
  ITransactionRepository? get _localRepo => kIsWeb ? null : getIt<ITransactionRepository>(instanceName: 'local_transaction');

  @override
  Future<List<TransactionItem>> fetchTransactions(TransactionFilters filters) async {
    if (!kIsWeb) {
      final local = await _localRepo?.fetchTransactions(filters) ?? [];
      if (local.isNotEmpty) {
        _refreshInBackground(filters);
        return local;
      }
    }
    try {
      final remote = await _apiService.fetchTransactions(filters).timeout(const Duration(seconds: 3));
      if (!kIsWeb) {
        await _localRepo?.reconcile(remote, filters);
        return await _localRepo!.fetchTransactions(filters);
      }
      return remote;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<int> countTransactions(TransactionFilters filters) async {
    if (!kIsWeb) {
      return await _localRepo?.countTransactions(filters) ?? 0;
    }
    try {
      return await _apiService.fetchTotalTransactions(filters);
    } catch (_) {
      return 0;
    }
  }

  Future<void> _refreshInBackground(TransactionFilters filters) async {
    try {
      final remote = await _apiService.fetchTransactions(filters).timeout(const Duration(seconds: 5));
      if (!kIsWeb) {
        await _localRepo?.reconcile(remote, filters);
      }
    } catch (_) {}
  }

  @override
  Future<void> reconcile(List<TransactionItem> serverTransactions, TransactionFilters filters) async {
    if (!kIsWeb) await _localRepo?.reconcile(serverTransactions, filters);
  }

  @override
  Future<TransactionItem> saveTransaction(TransactionItem transaction, {bool isSynced = true}) async {
    if (kIsWeb) {
      final remote = await _apiService.createTransaction(transaction.toJson());
      return remote ?? transaction;
    }
    final saved = await _localRepo!.saveTransaction(transaction, isSynced: false);
    try {
      final remote = await _apiService.createTransaction(transaction.toJson());
      if (remote != null) {
        await _localRepo?.markAsSynced(saved.id, remote.id);
      }
    } catch (_) {}
    return saved;
  }

  @override
  Future<void> updateTransaction(TransactionItem transaction, {bool isSynced = true}) async {
    if (kIsWeb) {
      await _apiService.updateTransaction(transaction.id, transaction.toJson());
      return;
    }
    await _localRepo!.updateTransaction(transaction, isSynced: false);
    try {
      await _apiService.updateTransaction(transaction.id, transaction.toJson());
    } catch (_) {}
  }

  @override
  Future<void> deleteTransaction(int id) async {
    if (!kIsWeb) await _localRepo?.deleteTransaction(id);
    try {
      if (id > 0) {
        await _apiService.deleteTransaction(id);
      }
    } catch (_) {}
  }

  @override
  Future<void> saveAll(List<TransactionItem> transactions) async {
    if (!kIsWeb) await _localRepo?.saveAll(transactions);
  }

  @override
  Future<TransactionItem?> getById(int id) async {
    if (!kIsWeb) return await _localRepo?.getById(id);
    return null;
  }

  @override
  Future<List<TransactionItem>> getPendingCreatesToSync() => _localRepo?.getPendingCreatesToSync() ?? Future.value([]);
  @override
  Future<List<TransactionItem>> getPendingToSync() => _localRepo?.getPendingToSync() ?? Future.value([]);
  @override
  Future<void> markAsSynced(int localId, int serverId) => _localRepo?.markAsSynced(localId, serverId) ?? Future.value();
}
