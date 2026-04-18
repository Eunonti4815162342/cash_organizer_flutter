import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../domain/repositories/transaction_repository.dart';
import '../domain/repositories/category_repository.dart';
import '../service_locator.dart';
import 'api_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  ITransactionRepository get _transactionRepo => getIt<ITransactionRepository>();
  ICategoryRepository get _categoryRepo => getIt<ICategoryRepository>();
  ApiService get _apiService => getIt<ApiService>();

  Future<void> performSync() async {
    if (kIsWeb) return; // No offline sync on web
    
    final bool online = await _apiService.isOnline();
    if (!online) return;

    // 1. Descargar y persistir Categorías de la API
    try {
      final categories = await _apiService.fetchCategories();
      if (categories.isNotEmpty) {
        await _categoryRepo.saveAll(categories);
      }
    } catch (_) {}

    // 2. Subir transacciones pendientes a la API
    final pending = await _transactionRepo.getPendingToSync();
    if (pending.isEmpty) return;

    for (var tx in pending) {
      try {
        final result = await _apiService.createTransaction({
          'amount': {'value': tx.amount.value, 'currency': tx.amount.currency},
          'account': {'id': tx.account.id},
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
}
