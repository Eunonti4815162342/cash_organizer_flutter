import 'package:sqflite/sqflite.dart';
import 'package:natave_flutter/domain/models/transaction_item.dart';
import 'package:natave_flutter/domain/models/account_item.dart';
import 'package:natave_flutter/domain/models/category.dart';
import 'package:natave_flutter/domain/models/beneficiary.dart';
import 'package:natave_flutter/domain/models/financial_entity.dart';
import 'package:natave_flutter/domain/models/transaction_filters.dart';
import 'package:natave_flutter/domain/repositories/transaction_repository.dart';
import 'package:natave_flutter/service_locator.dart';
import 'package:natave_flutter/infrastructure/persistence/sqlite/database_helper.dart';

class SqliteTransactionRepository implements ITransactionRepository {
  final DatabaseHelper _dbHelper = getIt<DatabaseHelper>();

  /// Construye los argumentos de filtrado para SQLite (Lógica compartida)
  static Map<String, dynamic> buildFilterConditions(TransactionFilters f, {String alias = 't'}) {
    List<String> conditions = ['1=1'];
    List<dynamic> args = [];

    if (f.startDate != null) { conditions.add('$alias.date >= ?'); args.add(f.startDate); }
    if (f.endDate != null) { conditions.add('$alias.date <= ?'); args.add(f.endDate); }
    
    if (f.accountIds != null && f.accountIds!.isNotEmpty) {
      conditions.add('$alias.account_id IN (${f.accountIds!.map((_) => '?').join(',')})');
      args.addAll(f.accountIds!);
    }
    if (f.categoryIds != null && f.categoryIds!.isNotEmpty) {
      conditions.add('$alias.category_id IN (${f.categoryIds!.map((_) => '?').join(',')})');
      args.addAll(f.categoryIds!);
    }
    if (f.subcategoryIds != null && f.subcategoryIds!.isNotEmpty) {
      conditions.add('$alias.subcategory_id IN (${f.subcategoryIds!.map((_) => '?').join(',')})');
      args.addAll(f.subcategoryIds!);
    }
    if (f.beneficiaryIds != null && f.beneficiaryIds!.isNotEmpty) {
      conditions.add('$alias.beneficiary_id IN (${f.beneficiaryIds!.map((_) => '?').join(',')})');
      args.addAll(f.beneficiaryIds!);
    }

    return {'clause': conditions.join(' AND '), 'args': args};
  }

  @override
  Future<List<TransactionItem>> fetchTransactions(TransactionFilters filters) async {
    final db = await _dbHelper.database;
    final f = buildFilterConditions(filters);

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT t.*, a.entity_id, a.entity_name as account_entity_name 
      FROM transactions t
      LEFT JOIN accounts a ON t.account_id = a.id
      WHERE ${f['clause']}
      ORDER BY t.date DESC
    ''', f['args']);
    
    return _mapRows(maps);
  }

  @override
  Future<TransactionItem> saveTransaction(TransactionItem tx, {bool isSynced = true}) async {
    final db = await _dbHelper.database;
    int? beneficiaryId = tx.beneficiary?.id;

    if (tx.beneficiary != null) {
      if (beneficiaryId == null || beneficiaryId <= 0) {
        beneficiaryId = await db.insert('beneficiaries', {
          'name': tx.beneficiary!.name,
          'last_category_id': tx.category?.id,
          'last_subcategory_id': tx.subcategory?.id,
          'last_type': tx.type.name,
        });
      } else {
        await db.update('beneficiaries', {
          'last_category_id': tx.category?.id,
          'last_subcategory_id': tx.subcategory?.id,
          'last_type': tx.type.name,
        }, where: 'id = ?', whereArgs: [beneficiaryId]);
      }
    }

    final int effectiveId = isSynced ? tx.id : -(DateTime.now().millisecondsSinceEpoch % 1000000000);
    final row = _toRow(tx, id: effectiveId, serverId: isSynced ? tx.id : null, pendingSync: isSynced ? 0 : 1, overrideBeneficiaryId: beneficiaryId);
    await db.insert('transactions', row, conflictAlgorithm: ConflictAlgorithm.replace);
    
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT t.*, a.entity_id, a.entity_name as account_entity_name 
      FROM transactions t
      LEFT JOIN accounts a ON t.account_id = a.id
      WHERE t.id = ?
    ''', [effectiveId]);
    
    return _mapRows(result).first;
  }

  @override
  Future<void> updateTransaction(TransactionItem tx, {bool isSynced = true}) async {
    final db = await _dbHelper.database;
    int? beneficiaryId = tx.beneficiary?.id;

    if (tx.beneficiary != null) {
      if (beneficiaryId == null || beneficiaryId <= 0) {
        beneficiaryId = await db.insert('beneficiaries', {
          'name': tx.beneficiary!.name,
          'last_category_id': tx.category?.id,
          'last_subcategory_id': tx.subcategory?.id,
          'last_type': tx.type.name,
        });
      } else {
        await db.update('beneficiaries', {
          'last_category_id': tx.category?.id,
          'last_subcategory_id': tx.subcategory?.id,
          'last_type': tx.type.name,
        }, where: 'id = ?', whereArgs: [beneficiaryId]);
      }
    }

    final row = _toRow(tx, id: tx.id, serverId: isSynced ? tx.id : null, pendingSync: isSynced ? 0 : 2, overrideBeneficiaryId: beneficiaryId);
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
        await txn.insert('transactions', _toRow(tx, id: tx.id, serverId: tx.id, pendingSync: 0), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  @override
  Future<TransactionItem?> getById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT t.*, a.entity_id, a.entity_name as account_entity_name 
      FROM transactions t
      LEFT JOIN accounts a ON t.account_id = a.id
      WHERE t.server_id = ? OR t.id = ?
    ''', [id, id]);
    if (maps.isEmpty) return null;
    return _mapRows(maps).first;
  }

  @override
  Future<List<TransactionItem>> getPendingCreatesToSync() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT t.*, a.entity_id, a.entity_name as account_entity_name 
      FROM transactions t
      LEFT JOIN accounts a ON t.account_id = a.id
      WHERE t.pending_sync = 1
    ''');
    return _mapRows(maps);
  }

  @override
  Future<List<TransactionItem>> getPendingToSync() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT t.*, a.entity_id, a.entity_name as account_entity_name 
      FROM transactions t
      LEFT JOIN accounts a ON t.account_id = a.id
      WHERE t.pending_sync = 2
    ''');
    return _mapRows(maps);
  }

  @override
  Future<void> markAsSynced(int localId, int serverId) async {
    final db = await _dbHelper.database;
    await db.update('transactions', {'pending_sync': 0, 'server_id': serverId}, where: 'id = ?', whereArgs: [localId]);
  }

  Map<String, dynamic> _toRow(TransactionItem tx, {required int id, int? serverId, required int pendingSync, int? overrideBeneficiaryId}) {
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
      'beneficiary_id': overrideBeneficiaryId ?? tx.beneficiary?.id,
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
        category = Category(id: m['category_id'] as int? ?? 0, name: m['category_name'] as String? ?? 'General', type: m['type'] == 'INCOME' ? CategoryType.income : CategoryType.expense, subcategories: []);
      }
      Subcategory? subcategory;
      if (m['subcategory_id'] != null) {
        subcategory = Subcategory(id: m['subcategory_id'] as int, name: m['subcategory_name'] as String? ?? 'General');
      }
      Beneficiary? beneficiary;
      if (m['beneficiary_id'] != null) {
        beneficiary = Beneficiary(id: m['beneficiary_id'] as int, name: m['beneficiary_name'] as String? ?? 'Desconocido');
      }
      FinancialEntity? entity;
      if (m['entity_id'] != null) {
        entity = FinancialEntity(id: m['entity_id'] as int, name: m['account_entity_name'] as String? ?? '', type: EntityType.PHYSICAL);
      }
      AccountItem? toAccount;
      if (m['to_account_id'] != null) {
        toAccount = AccountItem(id: m['to_account_id'] as int, name: m['to_account_name'] as String? ?? '', amount: Amount(0, m['amount_currency'] as String, false), flags: 0);
      }
      return TransactionItem(
        id: (m['server_id'] ?? m['id']) as int,
        date: m['date'] as String,
        description: m['description'] as String? ?? '',
        amount: Amount(m['amount_value'] as int, m['amount_currency'] as String, m['is_negative'] == 1),
        account: AccountItem(id: m['account_id'] as int, name: m['account_name'] as String? ?? '', amount: Amount(0, m['amount_currency'] as String, false), flags: 0, entity: entity),
        category: category,
        subcategory: subcategory,
        beneficiary: beneficiary,
        toAccount: toAccount,
        type: TransactionType.values.firstWhere((e) => e.name == m['type'], orElse: () => TransactionType.EXPENSE),
        isScheduled: false, isHeader: false, tags: [],
      );
    }).toList();
  }
}
