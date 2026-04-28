import 'package:flutter/foundation.dart' show kIsWeb;
import '../../domain/models/beneficiary.dart';
import '../../domain/repositories/beneficiary_repository.dart';
import '../../services/api_service.dart';
import '../../service_locator.dart';
import 'sqlite/sqlite_beneficiary_repository.dart';

class CachedBeneficiaryRepository implements IBeneficiaryRepository {
  final ApiService _apiService = getIt<ApiService>();
  
  SqliteBeneficiaryRepository? get _localRepo => kIsWeb ? null : getIt<SqliteBeneficiaryRepository>(instanceName: 'local_beneficiary');

  @override
  Future<List<Beneficiary>> getAllBeneficiaries() async {
    if (!kIsWeb) {
      final local = await _localRepo?.getAllBeneficiaries() ?? [];
      if (local.isNotEmpty) {
        _refreshInBackground();
        return local;
      }
    }

    try {
      final remote = await _apiService.fetchBeneficiaries();
      if (remote.isNotEmpty && !kIsWeb) {
        await _localRepo?.saveAll(remote);
      }
      return remote;
    } catch (e) {
      return [];
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      final remote = await _apiService.fetchBeneficiaries();
      if (remote.isNotEmpty && !kIsWeb) {
        await _localRepo?.saveAll(remote);
      }
    } catch (_) {}
  }

  @override
  Future<Map<String, dynamic>?> getTransactionSuggestion(int beneficiaryId) async {
    // 1. Intentar API
    try {
      final suggestion = await _apiService.getTransactionSuggestion(beneficiaryId);
      if (suggestion != null) {
        // SEMBRADO DE MEMORIA: Guardamos lo que el servidor sabe en el SQLite local
        if (!kIsWeb) {
          await _localRepo?.updateBeneficiaryMemory(
            beneficiaryId, 
            suggestion['categoryId'] as int?, 
            suggestion['subcategoryId'] as int?, 
            suggestion['transactionType'] as String?
          );
        }
        return suggestion;
      }
    } catch (_) {}

    // 2. FALLBACK A MEMORIA LOCAL (Solo si la red falló o no dio sugerencia)
    if (!kIsWeb) {
      return await _localRepo?.getTransactionSuggestion(beneficiaryId);
    }
    
    return null;
  }

  @override
  Future<void> updateBeneficiaryMemory(int id, int? catId, int? subId, String? type) async {
    if (!kIsWeb) {
      await _localRepo?.updateBeneficiaryMemory(id, catId, subId, type);
    }
  }
}
