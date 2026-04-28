import 'package:sqflite/sqflite.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/repositories/category_repository.dart';
import '../../../../service_locator.dart';
import '../../persistence/sqlite/database_helper.dart';

class SqliteCategoryRepository implements ICategoryRepository {
  final DatabaseHelper _dbHelper = getIt<DatabaseHelper>();

  @override
  Future<List<Category>> fetchCategories() async {
    final db = await _dbHelper.database;
    
    final List<Map<String, dynamic>> catMaps = await db.query('categories');
    final List<Map<String, dynamic>> subMaps = await db.query('subcategories');

    return catMaps.map((c) {
      final categoryId = c['id'] as int;
      final subcategories = subMaps
          .where((s) => (s['category_id'] as int) == categoryId)
          .map((s) => Subcategory(
                id: s['id'] as int,
                name: s['name'] as String,
              ))
          .toList();

      return Category(
        id: categoryId,
        name: c['name'] as String,
        type: c['type'] == 'INCOME' ? CategoryType.income : CategoryType.expense,
        subcategories: subcategories,
      );
    }).toList();
  }

  @override
  Future<Category?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    
    final c = maps.first;
    final subMaps = await db.query('subcategories', where: 'category_id = ?', whereArgs: [id]);
    
    final subcategories = subMaps.map((s) => Subcategory(
      id: s['id'] as int,
      name: s['name'] as String,
    )).toList();

    return Category(
      id: c['id'] as int,
      name: c['name'] as String,
      type: c['type'] == 'INCOME' ? CategoryType.income : CategoryType.expense,
      subcategories: subcategories,
    );
  }

  @override
  Future<void> saveAll(List<Category> categories) async {
    if (categories.isEmpty) return;
    final db = await _dbHelper.database;
    
    await db.transaction((txn) async {
      for (var cat in categories) {
        await txn.insert('categories', {
          'id': cat.id,
          'name': cat.name,
          'type': cat.type == CategoryType.income ? 'INCOME' : 'EXPENSE',
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        for (var sub in cat.subcategories) {
          await txn.insert('subcategories', {
            'id': sub.id,
            'name': sub.name,
            'category_id': cat.id,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }
  
  @override
  Future<void> saveCategory(Category category) async {
    final db = await _dbHelper.database;
    await db.insert('categories', {
      'id': category.id,
      'name': category.name,
      'type': category.type == CategoryType.income ? 'INCOME' : 'EXPENSE',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
