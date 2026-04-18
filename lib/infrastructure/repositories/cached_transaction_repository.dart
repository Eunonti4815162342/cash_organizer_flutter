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
    try {
      final remoteTransactions = await _apiService.fetchTransactions(
        startDate: startDate,
        endDate: endDate,
        accountId: accountId,
      );
      
      if (!kIsWeb) {
        await _localRepo?.saveAll(remoteTransactions);
      }
      return remoteTransactions;
      
    } catch (e) {
      print('[CachedTransactionRepository] Error: $e');
      if (kIsWeb) return [];
      return await _localRepo?.fetchTransactions(
        startDate: startDate,
        endDate: endDate,
        accountId: accountId,
      ) ?? [];
    }
  }

  @override
  Future<void> saveTransaction(TransactionItem transaction, {bool isSynced = true}) async {
    if (!kIsWeb) {
      await _localRepo?.saveTransaction(transaction, isSynced: isSynced);
    }

    if (isSynced) {
      try {
        final result = await _apiService.createTransaction({
          'amount': {
            'value': transaction.amount.value, 
            'currency': transaction.amount.currency,
            'isNegative': transaction.amount.isNegative
          },
          'account': {'id': transaction.account.id},
          'toAccount': transaction.toAccount != null ? {'id': transaction.toAccount!.id} : null,
          'category': transaction.category != null ? {'id': transaction.category!.id} : null,
          'subcategory': transaction.subcategory != null ? {'id': transaction.subcategory!.id} : null,
          'type': transaction.type.name,
          'description': transaction.description,
          'date': transaction.date,
        });
        
        if (result != null && !kIsWeb) {
          await _localRepo?.markAsSynced(transaction.id, result.id);
        }
      } catch (e) {
        print('[CachedTransactionRepository] No se pudo sincronizar: $e');
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
  Future<void> markAsSynced(int localId, int serverId) async {
    if (!kIsWeb) await _localRepo?.markAsSynced(localId, serverId);
  }
}
