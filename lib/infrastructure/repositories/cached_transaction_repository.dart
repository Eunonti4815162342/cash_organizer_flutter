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
    // 1. LOCAL FIRST (CON TODOS LOS FILTROS)
    if (!kIsWeb) {
      final local = await _localRepo?.fetchTransactions(filters) ?? [];
      if (local.isNotEmpty) {
        _refreshInBackground(filters);
        return local;
      }
    }

    // 2. NETWORK FALLBACK (Solo si local vacío o Web)
    try {
      final remote = await _apiService.fetchTransactions(filters).timeout(const Duration(seconds: 3));
      if (remote.isNotEmpty && !kIsWeb) {
        await _localRepo?.saveAll(remote);
        return await _localRepo!.fetchTransactions(filters);
      }
      return remote;
    } catch (e) {
      return [];
    }
  }

  Future<void> _refreshInBackground(TransactionFilters filters) async {
    try {
      final remote = await _apiService.fetchTransactions(filters).timeout(const Duration(seconds: 5));
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
    }).catchError((_) => null);
    return saved;
  }

  @override
  Future<void> updateTransaction(TransactionItem transaction, {bool isSynced = true}) async {
    if (kIsWeb) {
      await _apiService.updateTransaction(transaction.id, transaction.toJson());
      return;
    }
    await _localRepo!.updateTransaction(transaction, isSynced: false);
    _apiService.updateTransaction(transaction.id, transaction.toJson()).catchError((_) => null);
  }

  @override
  Future<void> deleteTransaction(int id) async {
    if (!kIsWeb) await _localRepo?.deleteTransaction(id);
    if (id > 0) {
      _apiService.deleteTransaction(id).catchError((_) => null);
    }
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
