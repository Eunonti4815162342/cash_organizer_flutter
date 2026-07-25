import 'package:sqflite/sqflite.dart';
import 'package:natave_flutter/domain/models/category.dart';
import 'package:natave_flutter/domain/models/financial_entity.dart';
import 'package:natave_flutter/domain/repositories/category_repository.dart';
import 'package:natave_flutter/service_locator.dart';
import 'package:natave_flutter/infrastructure/persistence/sqlite/database_helper.dart';

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
          .map((s) => Subcategory(id: s['id'] as int, name: s['name'] as String))
          .toList();

      FinancialEntity? entity;
      if (c['financial_entity_id'] != null) {
        entity = FinancialEntity(id: c['financial_entity_id'] as int, name: c['financial_entity_name'] as String? ?? '', type: EntityType.PHYSICAL);
      }

      return Category(id: categoryId, name: c['name'] as String, type: c['type'] == 'INCOME' ? CategoryType.income : CategoryType.expense, subcategories: subcategories, financialEntity: entity);
    }).toList();
  }

  @override
  Future<Category?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final c = maps.first;
    final subMaps = await db.query('subcategories', where: 'category_id = ?', whereArgs: [id]);
    final subcategories = subMaps.map((s) => Subcategory(id: s['id'] as int, name: s['name'] as String)).toList();

    FinancialEntity? entity;
    if (c['financial_entity_id'] != null) {
      entity = FinancialEntity(id: c['financial_entity_id'] as int, name: c['financial_entity_name'] as String? ?? '', type: EntityType.PHYSICAL);
    }

    return Category(id: c['id'] as int, name: c['name'] as String, type: c['type'] == 'INCOME' ? CategoryType.income : CategoryType.expense, subcategories: subcategories, financialEntity: entity);
  }

  @override
  Future<void> reconcile(List<Category> serverCategories) async {
    final db = await _dbHelper.database;
    final serverCatIds = serverCategories.map((c) => c.id).toList();
    final serverSubIds = serverCategories.expand((c) => c.subcategories.map((s) => s.id)).toList();

    await db.transaction((txn) async {
      // 1. Sincronizar categorías y sus subcategorías
      for (var cat in serverCategories) {
        await txn.insert('categories', {'id': cat.id, 'name': cat.name, 'type': cat.type == CategoryType.income ? 'INCOME' : 'EXPENSE', 'financial_entity_id': cat.financialEntity?.id, 'financial_entity_name': cat.financialEntity?.name}, conflictAlgorithm: ConflictAlgorithm.replace);
        for (var sub in cat.subcategories) {
          await txn.insert('subcategories', {'id': sub.id, 'name': sub.name, 'category_id': cat.id}, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      
      // 2. Borrar categorías locales que no existen en el servidor. Una lista
      // vacía es una respuesta válida (el usuario se quedó sin categorías),
      // no un fallo: reconcile() solo se invoca tras una respuesta de red
      // correcta, así que no limpiar en ese caso deja huérfanas para siempre.
      if (serverCatIds.isNotEmpty) {
        final catPlaceholders = List.filled(serverCatIds.length, '?').join(',');
        await txn.delete('categories', where: 'id NOT IN ($catPlaceholders)', whereArgs: serverCatIds);
      } else {
        await txn.delete('categories');
      }

      // 3. Borrar subcategorías locales que no existen en el servidor.
      if (serverSubIds.isNotEmpty) {
        final subPlaceholders = List.filled(serverSubIds.length, '?').join(',');
        await txn.delete('subcategories', where: 'id NOT IN ($subPlaceholders)', whereArgs: serverSubIds);
      } else {
        await txn.delete('subcategories');
      }
    });
  }

  @override
  Future<void> saveAll(List<Category> categories) async {
    if (categories.isEmpty) return;
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (var cat in categories) {
        await txn.insert('categories', {'id': cat.id, 'name': cat.name, 'type': cat.type == CategoryType.income ? 'INCOME' : 'EXPENSE', 'financial_entity_id': cat.financialEntity?.id, 'financial_entity_name': cat.financialEntity?.name}, conflictAlgorithm: ConflictAlgorithm.replace);
        for (var sub in cat.subcategories) {
          await txn.insert('subcategories', {'id': sub.id, 'name': sub.name, 'category_id': cat.id}, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }
  
  @override
  Future<void> saveCategory(Category category) async {
    final db = await _dbHelper.database;
    await db.insert('categories', {'id': category.id, 'name': category.name, 'type': category.type == CategoryType.income ? 'INCOME' : 'EXPENSE', 'financial_entity_id': category.financialEntity?.id, 'financial_entity_name': category.financialEntity?.name}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> saveSubcategory(int categoryId, Subcategory sub) async {
    final db = await _dbHelper.database;
    await db.insert('subcategories', {'id': sub.id == 0 ? null : sub.id, 'name': sub.name, 'category_id': categoryId}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('subcategories', where: 'category_id = ?', whereArgs: [id]);
      await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
    });
  }

  @override
  Future<void> deleteSubcategory(int id) async {
    final db = await _dbHelper.database;
    await db.delete('subcategories', where: 'id = ?', whereArgs: [id]);
  }
}
