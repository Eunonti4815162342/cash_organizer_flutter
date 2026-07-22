import '../../domain/models/financial_entity.dart';

abstract class IEntityRepository {
  Future<List<FinancialEntity>> fetchEntities();
  Future<void> saveAll(List<FinancialEntity> entities);
  Future<void> reconcile(List<FinancialEntity> serverEntities);
  Future<FinancialEntity?> createEntity(Map<String, dynamic> data);
  Future<bool> deleteEntity(int id);
}
