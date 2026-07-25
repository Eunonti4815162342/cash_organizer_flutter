import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:natave_flutter/domain/models/transaction_item.dart';
import 'package:natave_flutter/domain/models/transaction_filters.dart';
import 'package:natave_flutter/domain/repositories/transaction_repository.dart';
import 'package:natave_flutter/services/api_service.dart';
import 'package:natave_flutter/service_locator.dart';

class CachedTransactionRepository implements ITransactionRepository {
  final ApiService _apiService = getIt<ApiService>();
  ITransactionRepository? get _localRepo => kIsWeb ? null : getIt<ITransactionRepository>(instanceName: 'local_transaction');

  /// Si el beneficiario de [transaction] es nuevo (id=0, sentinel de "crear"),
  /// lo crea primero contra el servidor y devuelve una copia de la
  /// transacción apuntando a ese beneficiario ya con id real.
  ///
  /// Antes esto no se hacía: un beneficiario nuevo se guardaba solo con un id
  /// autogenerado en SQLite local, y ese id (que el servidor no conoce) se
  /// enviaba tal cual al crear/actualizar la transacción. El servidor lo
  /// rechazaba con un 500 por violar la FK, el error quedaba silenciado, y la
  /// transacción se quedaba "pendiente de sincronizar" para siempre —
  /// apareciendo en local (p.ej. en el Dashboard) sin que el usuario pudiera
  /// borrarla de verdad, ya que en el servidor nunca llegó a existir.
  Future<TransactionItem> _resolveNewBeneficiary(TransactionItem transaction) async {
    if (transaction.beneficiary == null || transaction.beneficiary!.id != 0) return transaction;
    try {
      final created = await _apiService.createBeneficiary(transaction.beneficiary!);
      if (created == null) return transaction;
      return TransactionItem(
        id: transaction.id,
        date: transaction.date,
        description: transaction.description,
        amount: transaction.amount,
        account: transaction.account,
        category: transaction.category,
        subcategory: transaction.subcategory,
        beneficiary: created,
        toAccount: transaction.toAccount,
        type: transaction.type,
        notes: transaction.notes,
        statusFlags: transaction.statusFlags,
        isScheduled: transaction.isScheduled,
        isHeader: transaction.isHeader,
        tags: transaction.tags,
      );
    } catch (_) {
      // Sin conexión: seguimos con el beneficiario local tal cual; se
      // resolverá la próxima vez que el usuario lo use con conexión.
      return transaction;
    }
  }

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
      final remote = await _apiService.fetchTransactions(filters);
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
      final remote = await _apiService.fetchTransactions(filters);
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
    final effective = await _resolveNewBeneficiary(transaction);
    if (kIsWeb) {
      final remote = await _apiService.createTransaction(effective.toJson());
      return remote ?? effective;
    }
    final saved = await _localRepo!.saveTransaction(effective, isSynced: false);
    try {
      final remote = await _apiService.createTransaction(effective.toJson());
      if (remote != null) {
        await _localRepo?.markAsSynced(saved.id, remote.id);
      }
    } catch (_) {}
    return saved;
  }

  @override
  Future<void> updateTransaction(TransactionItem transaction, {bool isSynced = true}) async {
    final effective = await _resolveNewBeneficiary(transaction);
    if (kIsWeb) {
      await _apiService.updateTransaction(effective.id, effective.toJson());
      return;
    }
    await _localRepo!.updateTransaction(effective, isSynced: false);
    try {
      await _apiService.updateTransaction(effective.id, effective.toJson());
    } catch (_) {}
  }

  @override
  Future<void> deleteTransaction(int id) async {
    // id puede venir "negativo" (id temporal local) si la UI aún tiene en
    // memoria una copia de antes de que terminase de sincronizarse. En ese
    // caso, getById ya resuelve el server_id real (ver _mapRows), así que lo
    // consultamos antes de borrar en vez de asumir que no existe en el server.
    int? remoteId = id > 0 ? id : null;
    if (!kIsWeb) {
      if (remoteId == null) {
        final existing = await _localRepo?.getById(id);
        if (existing != null && existing.id > 0) remoteId = existing.id;
      }
      await _localRepo?.deleteTransaction(id);
    } else {
      remoteId = id;
    }
    if (remoteId != null && remoteId > 0) {
      try {
        await _apiService.deleteTransaction(remoteId);
      } catch (_) {}
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
