import 'package:sqflite/sqflite.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/repositories/category_repository.dart';
import '../../persistence/sqlite/database_helper.dart';

class SqliteCategoryRepository implements ICategoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<List<Category>> fetchCategories() async {
    final db = await _dbHelper.database;
    
    // Cargamos todas las categorías
    final List<Map<String, dynamic>> categoryMaps = await db.query('categories');
    // Cargamos todas las subcategorías
    final List<Map<String, dynamic>> subMaps = await db.query('subcategories');

    List<Category> categories = [];

    for (var m in categoryMaps) {
      final id = m['id'] as int;
      final subs = subMaps
          .where((s) => s['category_id'] == id)
          .map((s) => Subcategory(
                id: s['id'] as int,
                name: s['name'] as String,
                iconName: s['icon'] as String?,
              ))
          .toList();

      categories.add(Category(
        id: id,
        name: m['name'] as String,
        type: m['type'] == 'INCOME' ? CategoryType.income : CategoryType.expense,
        iconName: m['icon'] as String?,
        subcategories: subs,
      ));
    }

    return categories;
  }

  @override
  Future<void> saveCategory(Category category) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert(
        'categories',
        {
          'id': category.id,
          'name': category.name,
          'type': category.type == CategoryType.income ? 'INCOME' : 'EXPENSE',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Limpiar subcategorías viejas para esta categoría
      await txn.delete('subcategories', where: 'category_id = ?', whereArgs: [category.id]);

      // Insertar las nuevas
      for (var sub in category.subcategories) {
        await txn.insert('subcategories', {
          'id': sub.id,
          'name': sub.name,
          'category_id': category.id,
        });
      }
    });
  }

  @override
  Future<void> saveAll(List<Category> categories) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (var category in categories) {
        await txn.insert(
          'categories',
          {
            'id': category.id,
            'name': category.name,
            'type': category.type == CategoryType.income ? 'INCOME' : 'EXPENSE',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        await txn.delete('subcategories', where: 'category_id = ?', whereArgs: [category.id]);

        for (var sub in category.subcategories) {
          await txn.insert('subcategories', {
            'id': sub.id,
            'name': sub.name,
            'category_id': category.id,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  @override
  Future<Category?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    
    final subMaps = await db.query('subcategories', where: 'category_id = ?', whereArgs: [id]);
    final subs = subMaps.map((s) => Subcategory(
      id: s['id'] as int,
      name: s['name'] as String,
    )).toList();

    final m = maps.first;
    return Category(
      id: m['id'] as int,
      name: m['name'] as String,
      type: (m['type'] as String) == 'INCOME' ? CategoryType.income : CategoryType.expense,
      subcategories: subs,
    );
  }
}
