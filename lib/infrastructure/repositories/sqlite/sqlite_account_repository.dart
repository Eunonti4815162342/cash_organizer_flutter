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

  /// Guarda una cuenta nueva. Si isSynced=false (offline), genera un ID
  /// local negativo basado en timestamp y deja server_id = NULL.
  /// Devuelve el AccountItem con el ID efectivo asignado.
  @override
  Future<AccountItem> saveAccount(AccountItem account, {bool isSynced = true}) async {
    final db = await _dbHelper.database;
    final int effectiveId;
    final int? serverId;

    if (isSynced) {
      effectiveId = account.id;
      serverId = account.id;
    } else {
      // ID local negativo único basado en timestamp
      effectiveId = -(DateTime.now().millisecondsSinceEpoch % 1000000000);
      serverId = null;
    }

    await db.insert(
      'accounts',
      _toRow(account, id: effectiveId, serverId: serverId, pendingSync: isSynced ? 0 : 1),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return AccountItem(
      id: effectiveId,
      name: account.name,
      amount: account.amount,
      flags: account.flags,
      description: account.description,
      accountType: account.accountType,
      notes: account.notes,
      entity: account.entity,
    );
  }

  @override
  Future<void> updateAccount(AccountItem account, {bool isSynced = true}) async {
    final db = await _dbHelper.database;
    final row = _toRow(account, id: account.id, serverId: isSynced ? account.id : null, pendingSync: isSynced ? 0 : 2)
      ..remove('id')
      ..remove('server_id');
    row['pending_sync'] = isSynced ? 0 : 2;
    // Actualiza por server_id si existe, si no por id local
    final updated = await db.update('accounts', row, where: 'server_id = ?', whereArgs: [account.id]);
    if (updated == 0) {
      await db.update('accounts', row, where: 'id = ?', whereArgs: [account.id]);
    }
  }

  @override
  Future<void> saveAll(List<AccountItem> accounts) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (final account in accounts) {
        await txn.insert(
          'accounts',
          _toRow(account, id: account.id, serverId: account.id, pendingSync: 0),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<AccountItem?> getById(int id) async {
    final db = await _dbHelper.database;
    // Busca por server_id primero, luego por id local
    var maps = await db.query('accounts', where: 'server_id = ?', whereArgs: [id]);
    if (maps.isEmpty) {
      maps = await db.query('accounts', where: 'id = ?', whereArgs: [id]);
    }
    if (maps.isEmpty) return null;
    return _fromRow(maps.first);
  }

  @override
  Future<List<AccountItem>> getPendingCreatesToSync() async {
    final db = await _dbHelper.database;
    final maps = await db.query('accounts', where: 'pending_sync = ?', whereArgs: [1]);
    return maps.map(_fromRow).toList();
  }

  @override
  Future<List<AccountItem>> getPendingToSync() async {
    final db = await _dbHelper.database;
    final maps = await db.query('accounts', where: 'pending_sync = ?', whereArgs: [2]);
    return maps.map(_fromRow).toList();
  }

  /// Cuando una cuenta offline se sincroniza: actualiza server_id, limpia
  /// pending_sync, y reasigna account_id en transacciones con el ID temporal.
  @override
  Future<void> markAsSynced(int localId, int serverId) async {
    final db = await _dbHelper.database;
    await db.update(
      'accounts',
      {'server_id': serverId, 'pending_sync': 0},
      where: 'id = ?',
      whereArgs: [localId],
    );
    // Reasigna referencias en transacciones que usaban el ID temporal
    await db.update(
      'transactions',
      {'account_id': serverId},
      where: 'account_id = ?',
      whereArgs: [localId],
    );
  }

  AccountItem _fromRow(Map<String, dynamic> m) => AccountItem(
    id: (m['server_id'] ?? m['id']) as int,
    name: m['name'] as String,
    amount: Amount(m['amount_value'] as int, m['amount_currency'] as String, m['is_negative'] == 1),
    flags: 0,
    description: m['description'] as String?,
    accountType: m['account_type'] as String?,
    notes: m['notes'] as String?,
  );

  Map<String, dynamic> _toRow(AccountItem account, {
    required int id,
    required int? serverId,
    required int pendingSync,
  }) =>
      {
        'id': id,
        'server_id': serverId,
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
