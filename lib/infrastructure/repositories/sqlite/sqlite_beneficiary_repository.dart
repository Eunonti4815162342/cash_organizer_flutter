import 'package:sqflite/sqflite.dart';
import '../../../../domain/models/beneficiary.dart';
import '../../../../domain/repositories/beneficiary_repository.dart';
import '../../../../service_locator.dart';
import '../../persistence/sqlite/database_helper.dart';

class SqliteBeneficiaryRepository implements IBeneficiaryRepository {
  final DatabaseHelper _dbHelper = getIt<DatabaseHelper>();

  @override
  Future<List<Beneficiary>> getAllBeneficiaries() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('beneficiaries');
    return maps.map((m) => Beneficiary(
      id: m['id'] as int,
      name: m['name'] as String,
      lastCategoryId: m['last_category_id'] as int?,
      lastSubcategoryId: m['last_subcategory_id'] as int?,
      lastTransactionType: m['last_type'] as String?,
    )).toList();
  }

  @override
  Future<Map<String, dynamic>?> getTransactionSuggestion(int beneficiaryId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('beneficiaries', where: 'id = ?', whereArgs: [beneficiaryId]);
    if (maps.isEmpty) return null;

    final b = maps.first;
    if (b['last_category_id'] == null) return null;

    return {
      'categoryId': b['last_category_id'],
      'subcategoryId': b['last_subcategory_id'],
      'transactionType': b['last_type'],
    };
  }

  @override
  Future<void> saveAll(List<Beneficiary> beneficiaries) async {
    if (beneficiaries.isEmpty) return;
    final db = await _dbHelper.database;
    
    await db.transaction((txn) async {
      for (var b in beneficiaries) {
        // MERGE INTELIGENTE: Si el registro existe, actualiza el nombre pero PRESERVA la memoria local (last_category) si el server manda null
        await txn.rawInsert('''
          INSERT INTO beneficiaries (id, name, last_category_id, last_subcategory_id, last_type)
          VALUES (?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            name = excluded.name,
            last_category_id = COALESCE(excluded.last_category_id, last_category_id),
            last_subcategory_id = COALESCE(excluded.last_subcategory_id, last_subcategory_id),
            last_type = COALESCE(excluded.last_type, last_type)
        ''', [
          b.id, 
          b.name, 
          b.lastCategoryId, 
          b.lastSubcategoryId, 
          b.lastTransactionType
        ]);
      }
    });
  }

  @override
  Future<void> updateBeneficiaryMemory(int id, int? catId, int? subId, String? type) async {
    final db = await _dbHelper.database;
    await db.update(
      'beneficiaries',
      {
        'last_category_id': catId,
        'last_subcategory_id': subId,
        'last_type': type,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
