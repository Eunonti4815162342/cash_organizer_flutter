import 'package:sqflite/sqflite.dart';
import '../../../../domain/models/transaction_item.dart';
import '../../../../domain/models/account_item.dart';
import '../../../../domain/repositories/transaction_repository.dart';
import '../../persistence/sqlite/database_helper.dart';

class SqliteTransactionRepository implements ITransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<List<TransactionItem>> fetchTransactions() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('transactions');

    // Mapeo detallado de transacciones locales
    return maps.map((m) => TransactionItem(
      id: m['id'],
      date: m['date'],
      description: m['description'] ?? '',
      amount: Amount(m['amount_value'], m['amount_currency'], m['amount_value'] < 0),
      // Cuentas y categorías básicas cargadas por ID. 
      // Se requiere hidratación adicional en capas superiores si es necesario.
      account: AccountItem(id: m['account_id'], name: 'Account ${m['account_id']}', amount: Amount(0, '', false), flags: 0),
      toAccount: m['to_account_id'] != null ? AccountItem(id: m['to_account_id'], name: 'Account ${m['to_account_id']}', amount: Amount(0, '', false), flags: 0) : null,
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
        'type': transaction.type.name,
        'description': transaction.description,
        'date': transaction.date,
        'account_id': transaction.account.id,
        'to_account_id': transaction.toAccount?.id,
        'category_id': transaction.category?.id,
        'subcategory_id': transaction.subcategory?.id,
        'pending_sync': isSynced ? 0 : 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> saveAll(List<TransactionItem> transactions) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (var tx in transactions) {
        await txn.insert(
          'transactions',
          {
            'server_id': tx.id,
            'amount_value': tx.amount.value,
            'amount_currency': tx.amount.currency,
            'type': tx.type.name,
            'description': tx.description,
            'date': tx.date,
            'account_id': tx.account.id,
            'to_account_id': tx.toAccount?.id,
            'category_id': tx.category?.id,
            'subcategory_id': tx.subcategory?.id,
            'pending_sync': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<List<TransactionItem>> getPendingToSync() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('transactions', where: 'pending_sync = ?', whereArgs: [1]);
    
    // Mapeo básico para sincronización. El Worker usará estos datos para llamar a la API.
    return maps.map((m) => TransactionItem(
      id: m['id'],
      date: m['date'],
      description: m['description'] ?? '',
      amount: Amount(m['amount_value'], m['amount_currency'], m['amount_value'] < 0),
      account: AccountItem(id: m['account_id'], name: '', amount: Amount(0, '', false), flags: 0),
      type: TransactionType.values.firstWhere((e) => e.name == m['type'], orElse: () => TransactionType.EXPENSE),
      isScheduled: false,
      isHeader: false,
      tags: [],
    )).toList();
  }

  @override
  Future<void> markAsSynced(int localId, int serverId) async {
    final db = await _dbHelper.database;
    await db.update(
      'transactions',
      {'pending_sync': 0, 'server_id': serverId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }
}
