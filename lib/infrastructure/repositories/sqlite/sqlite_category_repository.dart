import 'package:sqflite/sqflite.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/repositories/category_repository.dart';
import '../../persistence/sqlite/database_helper.dart';

class SqliteCategoryRepository implements ICategoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<List<Category>> fetchCategories() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('categories');

    // Mapeo simple de categorías principales (la demo se centra en primer nivel)
    return maps.map((m) => Category(
      id: m['id'],
      name: m['name'],
      type: m['type'] == 'INCOME' ? CategoryType.income : CategoryType.expense,
      iconName: m['icon'],
      subcategories: [], // Las subcategorías se pueden cargar bajo demanda si es necesario
    )).toList();
  }

  @override
  Future<void> saveCategory(Category category) async {
    final db = await _dbHelper.database;
    await db.insert(
      'categories',
      {
        'id': category.id,
        'name': category.name,
        'type': category.type == CategoryType.income ? 'INCOME' : 'EXPENSE',
        'icon': category.iconName,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
            'icon': category.iconName,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<Category?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final m = maps.first;
    return Category(
      id: m['id'] as int,
      name: m['name'] as String,
      type: (m['type'] as String) == 'INCOME' ? CategoryType.income : CategoryType.expense,
      iconName: m['icon'] as String?,
      subcategories: [],
    );
  }
}
