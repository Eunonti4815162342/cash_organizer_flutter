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
  Future<void> reconcile(List<FinancialEntity> serverEntities) async {
    final db = await _dbHelper.database;
    final serverIds = serverEntities.map((e) => e.id).toList();
    
    await db.transaction((txn) async {
      for (final entity in serverEntities) {
        await txn.insert(
          'entities',
          {'id': entity.id, 'name': entity.name, 'type': entity.type.name},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      if (serverIds.isNotEmpty) {
        final placeholders = List.filled(serverIds.length, '?').join(',');
        await txn.delete('entities', where: 'id NOT IN ($placeholders)', whereArgs: serverIds);
      } else {
        await txn.delete('entities');
      }
    });
  }
}
