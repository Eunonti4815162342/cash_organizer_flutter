import '../../domain/models/financial_entity.dart';

abstract class IEntityRepository {
  Future<List<FinancialEntity>> fetchEntities();
  Future<void> saveAll(List<FinancialEntity> entities);
}
