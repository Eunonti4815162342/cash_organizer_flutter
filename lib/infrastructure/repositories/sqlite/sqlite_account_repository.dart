import 'package:sqflite/sqflite.dart';
import '../../../../domain/models/account_item.dart';
import '../../../../domain/repositories/account_repository.dart';
import '../../persistence/sqlite/database_helper.dart';

class SqliteAccountRepository implements IAccountRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<List<AccountItem>> fetchAccounts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('accounts');

    return maps.map((m) => AccountItem(
      id: m['id'],
      name: m['name'],
      amount: Amount(
        m['amount_value'],
        m['amount_currency'],
        m['amount_value'] < 0,
      ),
      flags: 0,
      description: m['description'],
    )).toList();
  }

  @override
  Future<void> saveAccount(AccountItem account) async {
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

  @override
  Future<void> saveAll(List<List<AccountItem>> accounts) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (var account in accounts.expand((x) => x)) {
        await txn.insert(
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
    });
  }

  @override
  Future<AccountItem?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('accounts', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final m = maps.first;
    return AccountItem(
      id: m['id'] as int,
      name: m['name'] as String,
      amount: Amount(
        m['amount_value'] as int,
        m['amount_currency'] as String,
        (m['amount_value'] as int) < 0,
      ),
      flags: 0,
      description: m['description'] as String?,
    );
  }
}
