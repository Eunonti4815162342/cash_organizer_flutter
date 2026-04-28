import 'package:flutter/foundation.dart' show kIsWeb;
import '../../domain/models/financial_entity.dart';
import '../../domain/repositories/entity_repository.dart';
import '../../services/api_service.dart';
import '../../service_locator.dart';

class CachedEntityRepository implements IEntityRepository {
  final ApiService _apiService = getIt<ApiService>();
  IEntityRepository? get _localRepo => kIsWeb ? null : getIt<IEntityRepository>(instanceName: 'local_entity');

  @override
  Future<List<FinancialEntity>> fetchEntities() async {
    try {
      final remote = await _apiService.fetchEntities();
      if (remote.isNotEmpty && !kIsWeb) {
        await _localRepo?.saveAll(remote);
      }
      return remote;
    } catch (e) {
      if (kIsWeb) return [];
      return await _localRepo?.fetchEntities() ?? [];
    }
  }

  @override
  Future<void> saveAll(List<FinancialEntity> entities) async {
    if (!kIsWeb) {
      await _localRepo?.saveAll(entities);
    }
  }
}
