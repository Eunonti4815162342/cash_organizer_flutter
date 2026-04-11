import 'package:sqflite/sqflite.dart';
import '../../../../domain/models/account_item.dart';
import 'database_helper.dart';

class AccountDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> insertOrUpdate(AccountItem account) async {
    final db = await _dbHelper.database;
    await db.insert(
      'accounts',
      {
        'id': account.id,
        'name': account.name,
        'amount_value': account.amount.value,
        'amount_currency': account.amount.currency,
        'description': account.description,
        'last_updated': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AccountItem>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('accounts');

    return List.generate(maps.length, (i) {
      return AccountItem(
        id: maps[i]['id'],
        name: maps[i]['name'],
        amount: Amount(
          maps[i]['amount_value'],
          maps[i]['amount_currency'],
          maps[i]['amount_value'] < 0,
        ),
        flags: 0, // Simplificado para la demo local
        description: maps[i]['description'],
      );
    });
  }
}
