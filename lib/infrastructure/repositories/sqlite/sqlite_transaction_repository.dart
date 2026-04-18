import 'package:sqflite/sqflite.dart';
import '../../../../domain/models/transaction_item.dart';
import '../../../../domain/models/account_item.dart';
import '../../../../domain/models/category.dart';
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
      '''SELECT t.*, c.name as cat_name, c.type as cat_type 
         FROM transactions t
         LEFT JOIN categories c ON t.category_id = c.id
         $whereClause 
         ORDER BY t.date DESC''',
      args
    );

    return maps.map((m) => TransactionItem(
      id: m['server_id'] ?? m['id'],
      date: m['date'],
      description: m['description'] ?? '',
      amount: Amount(
        m['amount_value'], 
        m['amount_currency'], 
        m['is_negative'] == 1
      ),
      account: AccountItem(
        id: m['account_id'], 
        name: m['account_name'] ?? 'Account ${m['account_id']}', 
        amount: Amount(0, m['amount_currency'], false), 
        flags: 0
      ),
      category: m['category_id'] != null ? Category(
        id: m['category_id'], 
        name: m['cat_name'] ?? 'General', 
        type: m['cat_type'] == 'INCOME' ? CategoryType.income : CategoryType.expense,
        subcategories: []
      ) : null,
      type: TransactionType.values.firstWhere((e) => e.name == m['type'], orElse: () => TransactionType.EXPENSE),
      isScheduled: false,
      isHeader: false,
      tags: [],
    )).toList();
  }

  @override
  Future<void> saveTransaction(TransactionItem transaction, {bool isSynced = true}) async {
    final db = await _dbHelper.database;
    await db.insert(
      'transactions',
      {
        'server_id': isSynced ? transaction.id : null,
        'amount_value': transaction.amount.value,
        'amount_currency': transaction.amount.currency,
        'is_negative': transaction.amount.isNegative ? 1 : 0,
        'type': transaction.type.name,
        'description': transaction.description,
        'date': transaction.date,
        'account_id': transaction.account.id,
        'account_name': transaction.account.name,
        'category_id': transaction.category?.id,
        'category_name': transaction.category?.name,
        'pending_sync': isSynced ? 0 : 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> saveAll(List<TransactionItem> transactions) async {
    if (transactions.isEmpty) return;
    
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (var tx in transactions) {
        await txn.rawInsert(
          '''INSERT OR REPLACE INTO transactions 
             (server_id, amount_value, amount_currency, is_negative, type, description, date, account_id, account_name, category_id, category_name, pending_sync) 
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
          [
            tx.id, 
            tx.amount.value, 
            tx.amount.currency, 
            tx.amount.isNegative ? 1 : 0,
            tx.type.name, 
            tx.description, 
            tx.date, 
            tx.account.id,
            tx.account.name,
            tx.category?.id,
            tx.category?.name,
            0
          ]
        );
      }
    });
  }

  @override
  Future<List<TransactionItem>> getPendingToSync() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('transactions', where: 'pending_sync = ?', whereArgs: [1]);
    return maps.map((m) => TransactionItem(
      id: m['id'],
      date: m['date'],
      description: m['description'] ?? '',
      amount: Amount(m['amount_value'], m['amount_currency'], m['is_negative'] == 1),
      account: AccountItem(id: m['account_id'], name: m['account_name'] ?? '', amount: Amount(0, 'EUR', false), flags: 0),
      type: TransactionType.values.firstWhere((e) => e.name == m['type'], orElse: () => TransactionType.EXPENSE),
      isScheduled: false,
      isHeader: false,
      tags: [],
    )).toList();
  }

  @override
  Future<void> markAsSynced(int localId, int serverId) async {
    final db = await _dbHelper.database;
    await db.update('transactions', {'pending_sync': 0, 'server_id': serverId}, where: 'id = ?', whereArgs: [localId]);
  }
}
