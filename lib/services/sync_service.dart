import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../domain/repositories/transaction_repository.dart';
import '../domain/repositories/account_repository.dart';
import '../domain/repositories/category_repository.dart';
import '../service_locator.dart';
import 'api_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  ITransactionRepository get _transactionRepo => getIt<ITransactionRepository>();
  IAccountRepository get _accountRepo => getIt<IAccountRepository>();
  ICategoryRepository get _categoryRepo => getIt<ICategoryRepository>();
  ApiService get _apiService => getIt<ApiService>();

  Future<void> performSync() async {
    if (kIsWeb) return;

    final bool online = await _apiService.isOnline();
    if (!online) return;

    await _syncCategories();
    await _syncPendingAccountCreates();   // primero cuentas — transacciones las referencian
    await _syncPendingTransactionCreates();
    await _syncPendingTransactionUpdates();
    await _syncPendingAccountUpdates();
  }

  Future<void> _syncCategories() async {
    try {
      final categories = await _apiService.fetchCategories();
      if (categories.isNotEmpty) {
        await _categoryRepo.saveAll(categories);
      }
    } catch (_) {}
  }

  Future<void> _syncPendingTransactionCreates() async {
    final pending = await _transactionRepo.getPendingToSync();
    for (final tx in pending) {
      try {
        final result = await _apiService.createTransaction({
          'amount': {
            'value': tx.amount.value,
            'currency': tx.amount.currency,
            'isNegative': tx.amount.isNegative,
          },
          'account': {'id': tx.account.id},
          'toAccount': tx.toAccount != null ? {'id': tx.toAccount!.id} : null,
          'category': tx.category != null ? {'id': tx.category!.id} : null,
          'subcategory': tx.subcategory != null ? {'id': tx.subcategory!.id} : null,
          'type': tx.type.name,
          'description': tx.description,
          'date': tx.date,
        });
        if (result != null) {
          await _transactionRepo.markAsSynced(tx.id, result.id);
        }
      } catch (_) {}
    }
  }

  Future<void> _syncPendingTransactionUpdates() async {
    final pending = await _transactionRepo.getPendingUpdatesToSync();
    for (final tx in pending) {
      try {
        await _apiService.updateTransaction(tx.id, {
          'amount': {
            'value': tx.amount.value,
            'currency': tx.amount.currency,
            'isNegative': tx.amount.isNegative,
          },
          'account': {'id': tx.account.id},
          'toAccount': tx.toAccount != null ? {'id': tx.toAccount!.id} : null,
          'category': tx.category != null ? {'id': tx.category!.id} : null,
          'subcategory': tx.subcategory != null ? {'id': tx.subcategory!.id} : null,
          'type': tx.type.name,
          'description': tx.description,
          'date': tx.date,
        });
        await _transactionRepo.markAsSynced(tx.id, tx.id);
      } catch (_) {}
    }
  }

  Future<void> _syncPendingAccountCreates() async {
    final pending = await _accountRepo.getPendingCreatesToSync();
    for (final account in pending) {
      try {
        final result = await _apiService.createAccount({
          'name': account.name,
          'description': account.description,
          'amount': {
            'value': account.amount.value,
            'currency': account.amount.currency,
            'isNegative': account.amount.isNegative,
          },
          'accountType': account.accountType ?? 'CASH',
          'notes': account.notes,
          'active': true,
        });
        if (result != null) {
          // localId es el ID negativo temporal; serverId es el real del backend.
          // markAsSynced también reasigna account_id en transacciones pendientes.
          await _accountRepo.markAsSynced(account.id, result.id);
        }
      } catch (_) {}
    }
  }

  Future<void> _syncPendingAccountUpdates() async {
    final pending = await _accountRepo.getPendingToSync();
    for (final account in pending) {
      try {
        await _apiService.updateAccount(account.id, {
          'name': account.name,
          'description': account.description,
          'amount': {
            'value': account.amount.value,
            'currency': account.amount.currency,
            'isNegative': account.amount.isNegative,
          },
          'accountType': account.accountType ?? 'CASH',
          'notes': account.notes,
          'active': true,
        });
        await _accountRepo.markAsSynced(account.id, account.id);
      } catch (_) {}
    }
  }
}
