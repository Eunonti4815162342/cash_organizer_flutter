import 'package:sqflite/sqflite.dart';
import '../../../../domain/models/account_item.dart';
import '../../../../domain/repositories/account_repository.dart';
import '../../../../service_locator.dart';
import '../../persistence/sqlite/database_helper.dart';

class SqliteAccountRepository implements IAccountRepository {
  final DatabaseHelper _dbHelper = getIt<DatabaseHelper>();

  @override
  Future<List<AccountItem>> fetchAccounts() async {
    final db = await _dbHelper.database;
    final maps = await db.query('accounts');
    return maps.map(_fromRow).toList();
  }

  @override
  Future<void> saveAccount(AccountItem account, {bool isSynced = true}) async {
    final db = await _dbHelper.database;
    await db.insert('accounts', _toRow(account, pendingSync: isSynced ? 0 : 1),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> updateAccount(AccountItem account, {bool isSynced = true}) async {
    final db = await _dbHelper.database;
    final row = _toRow(account, pendingSync: isSynced ? 0 : 2)..remove('id');
    await db.update('accounts', row, where: 'id = ?', whereArgs: [account.id]);
  }

  @override
  Future<void> saveAll(List<AccountItem> accounts) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (var account in accounts) {
        await txn.insert('accounts', _toRow(account, pendingSync: 0),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  @override
  Future<AccountItem?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('accounts', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _fromRow(maps.first);
  }

  @override
  Future<List<AccountItem>> getPendingToSync() async {
    final db = await _dbHelper.database;
    final maps = await db.query('accounts', where: 'pending_sync > ?', whereArgs: [0]);
    return maps.map(_fromRow).toList();
  }

  @override
  Future<void> markAsSynced(int localId, int serverId) async {
    final db = await _dbHelper.database;
    await db.update('accounts', {'pending_sync': 0}, where: 'id = ?', whereArgs: [localId]);
  }

  AccountItem _fromRow(Map<String, dynamic> m) => AccountItem(
    id: m['id'] as int,
    name: m['name'] as String,
    amount: Amount(m['amount_value'] as int, m['amount_currency'] as String, m['is_negative'] == 1),
    flags: 0,
    description: m['description'] as String?,
    accountType: m['account_type'] as String?,
    notes: m['notes'] as String?,
  );

  Map<String, dynamic> _toRow(AccountItem account, {required int pendingSync}) => {
    'id': account.id,
    'name': account.name,
    'amount_value': account.amount.value,
    'amount_currency': account.amount.currency,
    'is_negative': account.amount.isNegative ? 1 : 0,
    'description': account.description,
    'account_type': account.accountType,
    'notes': account.notes,
    'last_updated': DateTime.now().toIso8601String(),
    'pending_sync': pendingSync,
  };
}
