import 'package:flutter/foundation.dart' show kIsWeb;
import '../../domain/models/transaction_item.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../services/api_service.dart';
import '../../service_locator.dart';

class CachedTransactionRepository implements ITransactionRepository {
  final ApiService _apiService = getIt<ApiService>();

  ITransactionRepository? get _localRepo =>
      kIsWeb ? null : getIt<ITransactionRepository>(instanceName: 'local_transaction');

  @override
  Future<List<TransactionItem>> fetchTransactions({String? startDate, String? endDate, String? accountId}) async {
    try {
      final remote = await _apiService.fetchTransactions(startDate: startDate, endDate: endDate, accountId: accountId);
      if (!kIsWeb) await _localRepo?.saveAll(remote);
      return remote;
    } catch (e) {
      if (kIsWeb) return [];
      return await _localRepo?.fetchTransactions(startDate: startDate, endDate: endDate, accountId: accountId) ?? [];
    }
  }

  @override
  Future<void> saveTransaction(TransactionItem transaction, {bool isSynced = true}) async {
    try {
      final result = await _apiService.createTransaction(_buildPayload(transaction));
      if (result != null && !kIsWeb) {
        await _localRepo?.saveAll([result]);
      }
    } catch (e) {
      if (!kIsWeb) {
        await _localRepo?.saveTransaction(transaction, isSynced: false);
      }
    }
  }

  @override
  Future<void> updateTransaction(TransactionItem transaction, {bool isSynced = true}) async {
    try {
      final result = await _apiService.updateTransaction(transaction.id, _buildPayload(transaction));
      if (result != null && !kIsWeb) {
        await _localRepo?.saveAll([result]);
      }
    } catch (e) {
      if (!kIsWeb) {
        await _localRepo?.updateTransaction(transaction, isSynced: false);
      }
    }
  }

  @override
  Future<void> saveAll(List<TransactionItem> transactions) async {
    if (!kIsWeb) await _localRepo?.saveAll(transactions);
  }

  @override
  Future<List<TransactionItem>> getPendingToSync() async {
    if (kIsWeb) return [];
    return await _localRepo?.getPendingToSync() ?? [];
  }

  @override
  Future<List<TransactionItem>> getPendingUpdatesToSync() async {
    if (kIsWeb) return [];
    return await _localRepo?.getPendingUpdatesToSync() ?? [];
  }

  @override
  Future<void> markAsSynced(int localId, int serverId) async {
    if (!kIsWeb) await _localRepo?.markAsSynced(localId, serverId);
  }

  Map<String, dynamic> _buildPayload(TransactionItem tx) => {
    'amount': {
      'value': tx.amount.value,
      'currency': tx.amount.currency,
      'isNegative': tx.amount.isNegative,
    },
    'account': {'id': tx.account.id},
    'toAccount': tx.toAccount != null ? {'id': tx.toAccount!.id} : null,
    'category': tx.category != null ? {'id': tx.category!.id} : null,
    'subcategory': tx.subcategory != null ? {'id': tx.subcategory!.id} : null,
    'beneficiary': tx.beneficiary != null ? {'id': tx.beneficiary!.id} : null,
    'type': tx.type.name,
    'description': tx.description,
    'date': tx.date,
  };
}
