import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:natave_flutter/domain/models/financial_entity.dart';
import 'package:natave_flutter/domain/repositories/entity_repository.dart';
import 'package:natave_flutter/services/api_service.dart';
import 'package:natave_flutter/service_locator.dart';

class CachedEntityRepository implements IEntityRepository {
  final ApiService _apiService = getIt<ApiService>();
  IEntityRepository? get _localRepo => kIsWeb ? null : getIt<IEntityRepository>(instanceName: 'local_entity');

  @override
  Future<List<FinancialEntity>> fetchEntities() async {
    // 1. LOCAL FIRST (INSTANTÁNEO)
    if (!kIsWeb) {
      final local = await _localRepo?.fetchEntities() ?? [];
      if (local.isNotEmpty) {
        _refreshInBackground();
        return local;
      }
    }

    // 2. NETWORK FALLBACK (Si local está vacío o es Web)
    try {
      final remote = await _apiService.fetchEntities();
      if (!kIsWeb) await _localRepo?.reconcile(remote);
      return remote;
    } catch (e) {
      return [];
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      final remote = await _apiService.fetchEntities();
      if (!kIsWeb) await _localRepo?.reconcile(remote);
    } catch (_) {}
  }

  @override
  Future<void> saveAll(List<FinancialEntity> entities) async {
    if (!kIsWeb) await _localRepo?.saveAll(entities);
  }

  @override
  Future<void> reconcile(List<FinancialEntity> serverEntities) async {
    if (!kIsWeb) await _localRepo?.reconcile(serverEntities);
  }

  @override
  Future<FinancialEntity?> createEntity(Map<String, dynamic> data) async {
    final created = await _apiService.createEntity(data);
    if (!kIsWeb && created != null) await _localRepo?.saveAll([created]);
    return created;
  }

  @override
  Future<bool> deleteEntity(int id) async {
    final success = await _apiService.deleteEntity(id);
    if (success && !kIsWeb) await _localRepo?.deleteEntity(id);
    return success;
  }
}
