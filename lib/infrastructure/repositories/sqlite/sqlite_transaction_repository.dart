import 'package:sqflite/sqflite.dart';
import '../../../../domain/models/transaction_item.dart';
import '../../../../domain/models/account_item.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/beneficiary.dart';
import '../../../../domain/repositories/transaction_repository.dart';
import '../../../../service_locator.dart';
import '../../persistence/sqlite/database_helper.dart';

class SqliteTransactionRepository implements ITransactionRepository {
  final DatabaseHelper _dbHelper = getIt<DatabaseHelper>();

  @override
  Future<List<TransactionItem>> fetchTransactions({String? startDate, String? endDate, String? accountId}) async {
    final db = await _dbHelper.database;

    List<String> conditions = [];
    List<dynamic> args = [];

    if (startDate != null) {
      conditions.add('date >= ?');
      args.add(startDate);
    }
    if (endDate != null) {
      conditions.add('date <= ?');
      args.add(endDate);
    }

    if (accountId != null && accountId != "-1") {
      final ids = accountId.split(',');
      conditions.add('account_id IN (${ids.map((_) => '?').join(',')})');
      args.addAll(ids.map((id) => int.parse(id)));
    } else if (accountId == "-1") {
      return [];
    }

    String whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM transactions $whereClause ORDER BY date DESC',
      args,
    );

    return _mapRows(maps);
  }

  @override
  Future<TransactionItem> saveTransaction(TransactionItem tx, {bool isSynced = true}) async {
    final db = await _dbHelper.database;
    final int effectiveId = isSynced ? tx.id : -(DateTime.now().millisecondsSinceEpoch % 1000000000);

    final row = _toRow(tx, id: effectiveId, serverId: isSynced ? tx.id : null, pendingSync: isSynced ? 0 : 1);
    await db.insert(
      'transactions',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return _mapRows([row]).first;
  }

  @override
  Future<void> updateTransaction(TransactionItem tx, {bool isSynced = true}) async {
    final db = await _dbHelper.database;
    final row = _toRow(tx, id: tx.id, serverId: isSynced ? tx.id : null, pendingSync: isSynced ? 0 : 2);
    
    int updated = await db.update('transactions', row, where: 'server_id = ?', whereArgs: [tx.id]);
    if (updated == 0) {
      await db.update('transactions', row, where: 'id = ?', whereArgs: [tx.id]);
    }
  }

  @override
  Future<void> deleteTransaction(int id) async {
    final db = await _dbHelper.database;
    await db.delete('transactions', where: 'server_id = ?', whereArgs: [id]);
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> saveAll(List<TransactionItem> transactions) async {
    if (transactions.isEmpty) return;
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (var tx in transactions) {
        await txn.insert(
          'transactions',
          _toRow(tx, id: tx.id, serverId: tx.id, pendingSync: 0),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<TransactionItem?> getById(int id) async {
    final db = await _dbHelper.database;
    var maps = await db.query('transactions', where: 'server_id = ?', whereArgs: [id]);
    if (maps.isEmpty) maps = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _mapRows(maps).first;
  }

  @override
  Future<List<TransactionItem>> getPendingCreatesToSync() async {
    final db = await _dbHelper.database;
    final maps = await db.query('transactions', where: 'pending_sync = ?', whereArgs: [1]);
    return _mapRows(maps);
  }

  @override
  Future<List<TransactionItem>> getPendingToSync() async {
    final db = await _dbHelper.database;
    final maps = await db.query('transactions', where: 'pending_sync = ?', whereArgs: [2]);
    return _mapRows(maps);
  }

  @override
  Future<void> markAsSynced(int localId, int serverId) async {
    final db = await _dbHelper.database;
    await db.update('transactions', {'pending_sync': 0, 'server_id': serverId}, where: 'id = ?', whereArgs: [localId]);
  }

  Map<String, dynamic> _toRow(TransactionItem tx, {required int id, int? serverId, required int pendingSync}) {
    return {
      'id': id,
      'server_id': serverId,
      'amount_value': tx.amount.value,
      'amount_currency': tx.amount.currency,
      'is_negative': tx.amount.isNegative ? 1 : 0,
      'type': tx.type.name,
      'description': tx.description,
      'date': tx.date,
      'account_id': tx.account.id,
      'account_name': tx.account.name,
      'category_id': tx.category?.id,
      'category_name': tx.category?.name ?? 'General',
      'subcategory_id': tx.subcategory?.id,
      'subcategory_name': tx.subcategory?.name,
      'beneficiary_id': tx.beneficiary?.id,
      'beneficiary_name': tx.beneficiary?.name,
      'to_account_id': tx.toAccount?.id,
      'to_account_name': tx.toAccount?.name,
      'pending_sync': pendingSync,
    };
  }

  List<TransactionItem> _mapRows(List<Map<String, dynamic>> maps) {
    return maps.map((m) {
      Category? category;
      if (m['category_id'] != null || m['category_name'] != null) {
        category = Category(
          id: m['category_id'] as int? ?? 0,
          name: m['category_name'] as String? ?? 'General',
          type: m['type'] == 'INCOME' ? CategoryType.income : CategoryType.expense,
          subcategories: [],
        );
      }

      Subcategory? subcategory;
      if (m['subcategory_id'] != null) {
        subcategory = Subcategory(
          id: m['subcategory_id'] as int,
          name: m['subcategory_name'] as String? ?? 'General',
        );
      }

      Beneficiary? beneficiary;
      if (m['beneficiary_id'] != null) {
        beneficiary = Beneficiary(
          id: m['beneficiary_id'] as int,
          name: m['beneficiary_name'] as String? ?? 'Desconocido',
        );
      }

      AccountItem? toAccount;
      if (m['to_account_id'] != null) {
        toAccount = AccountItem(
          id: m['to_account_id'] as int,
          name: m['to_account_name'] as String? ?? '',
          amount: Amount(0, m['amount_currency'] as String, false),
          flags: 0,
        );
      }

      return TransactionItem(
        id: (m['server_id'] ?? m['id']) as int,
        date: m['date'] as String,
        description: m['description'] as String? ?? '',
        amount: Amount(m['amount_value'] as int, m['amount_currency'] as String, m['is_negative'] == 1),
        account: AccountItem(
          id: m['account_id'] as int,
          name: m['account_name'] as String? ?? '',
          amount: Amount(0, m['amount_currency'] as String, false),
          flags: 0,
        ),
        category: category,
        subcategory: subcategory,
        beneficiary: beneficiary,
        toAccount: toAccount,
        type: TransactionType.values.firstWhere((e) => e.name == m['type'], orElse: () => TransactionType.EXPENSE),
        isScheduled: false,
        isHeader: false,
        tags: [],
      );
    }).toList();
  }
}
