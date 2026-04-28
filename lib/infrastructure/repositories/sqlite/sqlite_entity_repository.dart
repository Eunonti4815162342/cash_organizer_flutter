import 'package:sqflite/sqflite.dart';
import '../../../../domain/models/financial_entity.dart';
import '../../../../domain/repositories/entity_repository.dart';
import '../../../../service_locator.dart';
import '../../persistence/sqlite/database_helper.dart';

class SqliteEntityRepository implements IEntityRepository {
  final DatabaseHelper _dbHelper = getIt<DatabaseHelper>();

  @override
  Future<List<FinancialEntity>> fetchEntities() async {
    final db = await _dbHelper.database;
    final maps = await db.query('entities');
    return maps.map((m) => FinancialEntity(
      id: m['id'] as int,
      name: m['name'] as String,
      type: EntityType.values.firstWhere((e) => e.name == m['type'], orElse: () => EntityType.LEGAL),
    )).toList();
  }

  @override
  Future<void> saveAll(List<FinancialEntity> entities) async {
    if (entities.isEmpty) return;
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (final entity in entities) {
        await txn.insert(
          'entities',
          {
            'id': entity.id,
            'name': entity.name,
            'type': entity.type.name,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
