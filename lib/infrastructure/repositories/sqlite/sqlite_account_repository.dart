import 'package:sqflite/sqflite.dart';
import '../../../../domain/models/account_item.dart';
import '../../../../domain/models/financial_entity.dart';
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
  Future<AccountItem> saveAccount(AccountItem account, {bool isSynced = true}) async {
    final db = await _dbHelper.database;
    final int effectiveId = isSynced ? account.id : -(DateTime.now().millisecondsSinceEpoch % 1000000000);

    final row = _toRow(account, id: effectiveId, serverId: isSynced ? account.id : null, pendingSync: isSynced ? 0 : 1);
    await db.insert(
      'accounts',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return _fromRow(row);
  }

  @override
  Future<void> updateAccount(AccountItem account, {bool isSynced = true}) async {
    final db = await _dbHelper.database;
    final row = _toRow(account, id: account.id, serverId: isSynced ? account.id : null, pendingSync: isSynced ? 0 : 2)
      ..remove('id')
      ..remove('server_id');
    
    int updated = await db.update('accounts', row, where: 'server_id = ?', whereArgs: [account.id]);
    if (updated == 0) {
      await db.update('accounts', row, where: 'id = ?', whereArgs: [account.id]);
    }
  }

  @override
  Future<void> reconcile(List<AccountItem> serverAccounts) async {
    final db = await _dbHelper.database;
    final serverIds = serverAccounts.map((a) => a.id).toList();
    
    await db.transaction((txn) async {
      // 1. Guardar/Actualizar todas las del servidor
      for (final account in serverAccounts) {
        await txn.insert(
          'accounts',
          _toRow(account, id: account.id, serverId: account.id, pendingSync: 0),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      // 2. Borrar las que están en local con server_id pero NO en la lista del servidor
      // Ignoramos las que tienen pending_sync > 0 porque son cambios locales aún no subidos
      if (serverIds.isNotEmpty) {
        final placeholders = List.filled(serverIds.length, '?').join(',');
        await txn.delete(
          'accounts',
          where: 'server_id IS NOT NULL AND pending_sync = 0 AND server_id NOT IN ($placeholders)',
          whereArgs: serverIds,
        );
      } else {
        await txn.delete('accounts', where: 'server_id IS NOT NULL AND pending_sync = 0');
      }
    });
  }

  @override
  Future<AccountItem?> getById(int id) async {
    final db = await _dbHelper.database;
    var maps = await db.query('accounts', where: 'server_id = ?', whereArgs: [id]);
    if (maps.isEmpty) maps = await db.query('accounts', where: 'id = ?', whereArgs: [id]);
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

  @override
  Future<void> markAsSynced(int localId, int serverId) async {
    final db = await _dbHelper.database;
    await db.update('accounts', {'server_id': serverId, 'pending_sync': 0}, where: 'id = ?', whereArgs: [localId]);
  }

  AccountItem _fromRow(Map<String, dynamic> m) {
    FinancialEntity? entity;
    if (m['entity_id'] != null) {
      entity = FinancialEntity(
        id: m['entity_id'] as int,
        name: m['entity_name'] as String? ?? 'Desconocido',
        type: EntityType.LEGAL,
      );
    }

    return AccountItem(
      id: (m['server_id'] ?? m['id']) as int,
      name: m['name'] as String,
      amount: Amount(m['amount_value'] as int, m['amount_currency'] as String, m['is_negative'] == 1),
      flags: 0,
      description: m['description'] as String?,
      accountType: m['account_type'] as String?,
      notes: m['notes'] as String?,
      entity: entity,
    );
  }

  Map<String, dynamic> _toRow(AccountItem account, {required int id, int? serverId, required int pendingSync}) {
    return {
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
      'entity_id': account.entity?.id,
      'entity_name': account.entity?.name,
    };
  }
}
