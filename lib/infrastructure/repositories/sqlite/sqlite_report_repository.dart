import 'dart:typed_data';
import 'package:natave_flutter/domain/repositories/report_repository.dart';
import 'package:natave_flutter/infrastructure/persistence/sqlite/database_helper.dart';
import 'package:natave_flutter/domain/models/transaction_item.dart';
import 'package:natave_flutter/domain/models/account_item.dart';
import 'package:natave_flutter/domain/models/category.dart';
import 'package:natave_flutter/domain/models/beneficiary.dart';
import 'package:natave_flutter/services/storage/local_pdf_generator.dart';

class SqliteReportRepository implements IReportRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<Map<String, double>> fetchCategoryStats({
    String? startDate,
    String? endDate,
    List<int>? accountIds,
    bool groupBySubcategory = false,
  }) async {
    final db = await _dbHelper.database;
    final labelColumn = groupBySubcategory ? 'subcategory_name' : 'category_name';
    
    String query = '''
      SELECT $labelColumn as label, SUM(amount_value) as total 
      FROM transactions 
      WHERE 1=1
    ''';
    
    final args = <dynamic>[];
    if (startDate != null) {
      query += ' AND date >= ?';
      args.add(startDate);
    }
    if (endDate != null) {
      query += ' AND date <= ?';
      args.add(endDate);
    }
    if (accountIds != null && accountIds.isNotEmpty) {
      query += ' AND account_id IN (${accountIds.map((_) => '?').join(',')})';
      args.addAll(accountIds);
    }
    
    query += ' GROUP BY $labelColumn';
    
    final List<Map<String, dynamic>> results = await db.rawQuery(query, args);
    
    return {
      for (var row in results)
        (row['label']?.toString() ?? 'Uncategorized'): (row['total'] as num).toDouble() / 100.0
    };
  }

  @override
  Future<Map<String, double>> fetchEntityStats({
    String? startDate,
    String? endDate,
    List<int>? accountIds,
  }) async {
    final db = await _dbHelper.database;
    
    String query = '''
      SELECT account_name as label, SUM(amount_value) as total 
      FROM transactions 
      WHERE 1=1
    ''';
    
    final args = <dynamic>[];
    if (startDate != null) {
      query += ' AND date >= ?';
      args.add(startDate);
    }
    if (endDate != null) {
      query += ' AND date <= ?';
      args.add(endDate);
    }
    if (accountIds != null && accountIds.isNotEmpty) {
      query += ' AND account_id IN (${accountIds.map((_) => '?').join(',')})';
      args.addAll(accountIds);
    }
    
    query += ' GROUP BY account_name';
    
    final List<Map<String, dynamic>> results = await db.rawQuery(query, args);
    
    return {
      for (var row in results)
        (row['label']?.toString() ?? 'Unknown Account'): (row['total'] as num).toDouble() / 100.0
    };
  }

  @override
  Future<Map<String, double>> fetchBeneficiaryStats({
    String? startDate,
    String? endDate,
    List<int>? accountIds,
  }) async {
    final db = await _dbHelper.database;
    
    String query = '''
      SELECT beneficiary_name as label, SUM(amount_value) as total 
      FROM transactions 
      WHERE beneficiary_name IS NOT NULL
    ''';
    
    final args = <dynamic>[];
    if (startDate != null) {
      query += ' AND date >= ?';
      args.add(startDate);
    }
    if (endDate != null) {
      query += ' AND date <= ?';
      args.add(endDate);
    }
    if (accountIds != null && accountIds.isNotEmpty) {
      query += ' AND account_id IN (${accountIds.map((_) => '?').join(',')})';
      args.addAll(accountIds);
    }
    
    query += ' GROUP BY beneficiary_name';
    
    final List<Map<String, dynamic>> results = await db.rawQuery(query, args);
    
    return {
      for (var row in results)
        row['label'].toString(): (row['total'] as num).toDouble() / 100.0
    };
  }

  @override
  Future<Uint8List?> downloadPdf({
    required String title,
    required String chartType,
    String? reportType,
    String? startDate,
    String? endDate,
    List<int>? accountIds,
    List<int>? categoryIds,
    List<int>? beneficiaryIds,
    String lang = 'en',
  }) async {
    final db = await _dbHelper.database;
    
    final summary = await fetchCategoryStats(
      startDate: startDate,
      endDate: endDate,
      accountIds: accountIds,
    );

    String query = 'SELECT * FROM transactions WHERE 1=1';
    final args = <dynamic>[];
    if (startDate != null) { query += ' AND date >= ?'; args.add(startDate); }
    if (endDate != null) { query += ' AND date <= ?'; args.add(endDate); }
    if (accountIds != null && accountIds.isNotEmpty) {
      query += ' AND account_id IN (${accountIds.map((_) => '?').join(',')})';
      args.addAll(accountIds);
    }
    query += ' ORDER BY account_name, date DESC';

    final List<Map<String, dynamic>> rows = await db.rawQuery(query, args);
    final Map<String, Map<String, List<TransactionItem>>> segregatedData = {};

    for (var row in rows) {
      final tx = _mapToTransactionItem(row);
      final fullName = row['account_name']?.toString() ?? 'Default';
      final entityName = fullName.split(' > ').first;
      final accountName = fullName;

      segregatedData.putIfAbsent(entityName, () => {});
      segregatedData[entityName]!.putIfAbsent(accountName, () => []);
      segregatedData[entityName]![accountName]!.add(tx);
    }

    return await LocalPdfReportGenerator.generate(
      title: title,
      period: '${startDate ?? "Inception"} - ${endDate ?? "Today"}',
      summary: summary,
      segregatedData: segregatedData,
      lang: lang,
    );
  }

  TransactionItem _mapToTransactionItem(Map<String, dynamic> m) {
    return TransactionItem(
      id: m['id'] as int,
      date: m['date'] as String,
      description: m['description'] as String? ?? '',
      amount: Amount(
        m['amount_value'] as int,
        m['amount_currency'] as String,
        m['is_negative'] == 1,
      ),
      account: AccountItem(
        id: m['account_id'] as int,
        name: m['account_name'] as String,
        amount: Amount(0, 'EUR', false),
        flags: 0,
      ),
      category: m['category_id'] != null ? Category(
        id: m['category_id'] as int,
        name: m['category_name'] as String,
        type: CategoryType.expense,
      ) : null,
      subcategory: m['subcategory_id'] != null ? Subcategory(
        id: m['subcategory_id'] as int,
        name: m['subcategory_name'] as String,
      ) : null,
      beneficiary: m['beneficiary_id'] != null ? Beneficiary(
        id: m['beneficiary_id'] as int,
        name: m['beneficiary_name'] as String,
      ) : null,
      type: TransactionType.values.firstWhere(
        (e) => e.name == (m['type'] as String),
        orElse: () => TransactionType.EXPENSE,
      ),
      isScheduled: false,
      isHeader: false,
      tags: [],
    );
  }
}
