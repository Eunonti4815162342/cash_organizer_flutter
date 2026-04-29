import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:natave_flutter/domain/models/beneficiary.dart';
import 'package:natave_flutter/domain/repositories/beneficiary_repository.dart';
import 'package:natave_flutter/services/api_service.dart';
import 'package:natave_flutter/service_locator.dart';
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
      if (remote.isNotEmpty && !kIsWeb) await _localRepo?.saveAll(remote);
      return remote;
    } catch (e) {
      return [];
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      final remote = await _apiService.fetchBeneficiaries();
      if (remote.isNotEmpty && !kIsWeb) await _localRepo?.saveAll(remote);
    } catch (_) {}
  }

  @override
  Future<Map<String, dynamic>?> getTransactionSuggestion(int beneficiaryId) async {
    // 1. LEY DEL LOCAL-FIRST: Si tenemos memoria en el teléfono, la usamos YA.
    Map<String, dynamic>? localSuggestion;
    if (!kIsWeb) {
      localSuggestion = await _localRepo?.getTransactionSuggestion(beneficiaryId);
      if (localSuggestion != null) {
        // Disparamos la actualización del servidor en background, pero devolvemos el local de inmediato
        _updateMemoryFromServer(beneficiaryId);
        return localSuggestion;
      }
    }

    // 2. Si no hay nada en local o es Web, vamos al API esperando la respuesta
    try {
      final suggestion = await _apiService.getTransactionSuggestion(beneficiaryId).timeout(const Duration(seconds: 1));
      if (suggestion != null && !kIsWeb) {
        await _localRepo?.updateBeneficiaryMemory(
          beneficiaryId, 
          suggestion['categoryId'] as int?, 
          suggestion['subcategoryId'] as int?, 
          suggestion['transactionType'] as String?
        );
      }
      return suggestion;
    } catch (_) {
      return localSuggestion; // Si el API falla tras 1s, devolvemos lo que tuviéramos (aunque fuera nulo)
    }
  }

  Future<void> _updateMemoryFromServer(int beneficiaryId) async {
    try {
      final suggestion = await _apiService.getTransactionSuggestion(beneficiaryId).timeout(const Duration(seconds: 2));
      if (suggestion != null && !kIsWeb) {
        await _localRepo?.updateBeneficiaryMemory(
          beneficiaryId, 
          suggestion['categoryId'] as int?, 
          suggestion['subcategoryId'] as int?, 
          suggestion['transactionType'] as String?
        );
      }
    } catch (_) {}
  }

  @override
  Future<void> updateBeneficiaryMemory(int id, int? catId, int? subId, String? type) async {
    if (!kIsWeb) {
      await _localRepo?.updateBeneficiaryMemory(id, catId, subId, type);
    }
  }
}
