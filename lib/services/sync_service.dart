import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:natave_flutter/domain/models/transaction_filters.dart';
import '../domain/repositories/transaction_repository.dart';
import '../domain/repositories/account_repository.dart';
import '../domain/repositories/category_repository.dart';
import '../domain/repositories/beneficiary_repository.dart';
import '../domain/repositories/entity_repository.dart';
import '../service_locator.dart';
import 'api_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  ITransactionRepository get _transactionRepo => getIt<ITransactionRepository>();
  IAccountRepository get _accountRepo => getIt<IAccountRepository>();
  ICategoryRepository get _categoryRepo => getIt<ICategoryRepository>();
  IEntityRepository get _entityRepo => getIt<IEntityRepository>();
  IBeneficiaryRepository get _beneficiaryRepo => getIt<IBeneficiaryRepository>();
  ApiService get _apiService => getIt<ApiService>();

  Future<void> performSync() async {
    if (kIsWeb) return;

    try {
      final bool online = await _apiService.isOnline();
      if (!online) return;

      // 1. DESCARGA DE METADATOS Y ENTIDADES CORE
      await _syncEntities();
      await _syncCategories();
      await _syncBeneficiaries();
      await _syncAccounts();

      // 2. DESCARGA DE TRANSACCIONES (Espejo total)
      await _syncAllTransactions();

      // 3. SUBIDA DE CAMBIOS LOCALES PENDIENTES
      await _syncPendingAccountCreates();
      await _syncPendingTransactionCreates();
      await _syncPendingTransactionUpdates();
      await _syncPendingAccountUpdates();

    } catch (e) {
      // Fallo silencioso en background
    }
  }

  Future<void> _syncEntities() async {
    try {
      final entities = await _apiService.fetchEntities();
      if (entities.isNotEmpty) await _entityRepo.saveAll(entities);
    } catch (_) {}
  }

  Future<void> _syncCategories() async {
    try {
      final categories = await _apiService.fetchCategories();
      if (categories.isNotEmpty) await _categoryRepo.saveAll(categories);
    } catch (_) {}
  }

  Future<void> _syncBeneficiaries() async {
    try {
      await _beneficiaryRepo.getAllBeneficiaries();
    } catch (_) {}
  }

  Future<void> _syncAccounts() async {
    try {
      final accounts = await _apiService.fetchAccounts();
      if (accounts.isNotEmpty) await _accountRepo.saveAll(accounts);
    } catch (_) {}
  }

  Future<void> _syncAllTransactions() async {
    try {
      // Descargamos las transacciones usando el nuevo objeto de filtros vacío (todas)
      final txs = await _apiService.fetchTransactions(const TransactionFilters());
      if (txs.isNotEmpty) await _transactionRepo.saveAll(txs);
    } catch (_) {}
  }

  Future<void> _syncPendingTransactionCreates() async {
    final pending = await _transactionRepo.getPendingCreatesToSync();
    for (final tx in pending) {
      try {
        final result = await _apiService.createTransaction(tx.toJson());
        if (result != null) await _transactionRepo.markAsSynced(tx.id, result.id);
      } catch (_) {}
    }
  }

  Future<void> _syncPendingTransactionUpdates() async {
    final pending = await _transactionRepo.getPendingToSync();
    for (final tx in pending) {
      try {
        await _apiService.updateTransaction(tx.id, tx.toJson());
        await _transactionRepo.markAsSynced(tx.id, tx.id);
      } catch (_) {}
    }
  }

  Future<void> _syncPendingAccountCreates() async {
    final pending = await _accountRepo.getPendingCreatesToSync();
    for (final account in pending) {
      try {
        final result = await _apiService.createAccount(account.toJson());
        if (result != null) await _accountRepo.markAsSynced(account.id, result.id);
      } catch (_) {}
    }
  }

  Future<void> _syncPendingAccountUpdates() async {
    final pending = await _accountRepo.getPendingToSync();
    for (final account in pending) {
      try {
        await _apiService.updateAccount(account.id, account.toJson());
        await _accountRepo.markAsSynced(account.id, account.id);
      } catch (_) {}
    }
  }
}
