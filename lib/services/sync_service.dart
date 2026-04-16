import 'dart:async';
import '../infrastructure/repositories/cached_transaction_repository.dart';
import '../infrastructure/repositories/cached_category_repository.dart';
import '../domain/repositories/transaction_repository.dart';
import '../domain/repositories/category_repository.dart';
import 'api_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ITransactionRepository _transactionRepo = CachedTransactionRepository();
  final ICategoryRepository _categoryRepo = CachedCategoryRepository();
  final ApiService _apiService = ApiService();

  Future<void> performSync() async {
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
