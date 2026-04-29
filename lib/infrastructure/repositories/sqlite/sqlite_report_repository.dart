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
    final labelColumn = groupBySubcategory ? 't.subcategory_name' : 't.category_name';
    
    String query = 'SELECT $labelColumn as label, SUM(t.amount_value) as total FROM transactions t WHERE 1=1';
    final args = <dynamic>[];
    if (startDate != null) { query += ' AND t.date >= ?'; args.add(startDate); }
    if (endDate != null) { query += ' AND t.date <= ?'; args.add(endDate); }
    if (accountIds != null && accountIds.isNotEmpty) {
      query += ' AND t.account_id IN (${accountIds.map((_) => '?').join(',')})';
      args.addAll(accountIds);
    }
    query += ' GROUP BY $labelColumn';
    final List<Map<String, dynamic>> results = await db.rawQuery(query, args);
    return { for (var row in results) (row['label']?.toString() ?? 'Uncategorized'): (row['total'] as num).toDouble() / 100.0 };
  }

  Future<Map<String, Map<String, double>>> _fetchCategoryStatsByCurrency({
    String? startDate,
    String? endDate,
    List<int>? accountIds,
  }) async {
    final db = await _dbHelper.database;
    String query = '''
      SELECT t.category_name as label, t.amount_currency as currency, SUM(t.amount_value) as total 
      FROM transactions t
      WHERE 1=1
    ''';
    final args = <dynamic>[];
    if (startDate != null) { query += ' AND t.date >= ?'; args.add(startDate); }
    if (endDate != null) { query += ' AND t.date <= ?'; args.add(endDate); }
    if (accountIds != null && accountIds.isNotEmpty) {
      query += ' AND t.account_id IN (${accountIds.map((_) => '?').join(',')})';
      args.addAll(accountIds);
    }
    query += ' GROUP BY t.category_name, t.amount_currency';
    
    final List<Map<String, dynamic>> results = await db.rawQuery(query, args);
    final Map<String, Map<String, double>> stats = {};

    for (var row in results) {
      final label = row['label']?.toString() ?? 'Otros';
      final currency = row['currency']?.toString() ?? 'EUR';
      final total = (row['total'] as num).toDouble() / 100.0;
      
      stats.putIfAbsent(label, () => {});
      stats[label]![currency] = total;
    }
    return stats;
  }

  @override
  Future<Map<String, double>> fetchEntityStats({ String? startDate, String? endDate, List<int>? accountIds }) async => fetchCategoryStats(startDate: startDate, endDate: endDate, accountIds: accountIds);

  @override
  Future<Map<String, double>> fetchBeneficiaryStats({ String? startDate, String? endDate, List<int>? accountIds }) async => fetchCategoryStats(startDate: startDate, endDate: endDate, accountIds: accountIds);

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
    
    final summary = await _fetchCategoryStatsByCurrency(
      startDate: startDate,
      endDate: endDate,
      accountIds: accountIds,
    );

    // JOIN con la tabla 'accounts' para sacar el 'entity_name' real
    String query = '''
      SELECT t.*, a.entity_name as real_entity_name 
      FROM transactions t
      LEFT JOIN accounts a ON t.account_id = a.id
      WHERE 1=1
    ''';
    final args = <dynamic>[];
    if (startDate != null) { query += ' AND t.date >= ?'; args.add(startDate); }
    if (endDate != null) { query += ' AND t.date <= ?'; args.add(endDate); }
    if (accountIds != null && accountIds.isNotEmpty) {
      query += ' AND t.account_id IN (${accountIds.map((_) => '?').join(',')})';
      args.addAll(accountIds);
    }
    query += ' ORDER BY a.entity_name, t.account_name, t.date DESC';

    final List<Map<String, dynamic>> rows = await db.rawQuery(query, args);
    final Map<String, Map<String, List<TransactionItem>>> segregatedData = {};

    for (var row in rows) {
      final tx = _mapToTransactionItem(row);
      final entityName = row['real_entity_name']?.toString() ?? 'General';
      final accountName = row['account_name']?.toString() ?? 'Default';

      segregatedData.putIfAbsent(entityName, () => {});
      segregatedData[entityName]!.putIfAbsent(accountName, () => []);
      segregatedData[entityName]![accountName]!.add(tx);
    }

    return await LocalPdfReportGenerator.generate(
      title: title,
      period: '${startDate?.split('T').first ?? "Inception"} - ${endDate?.split('T').first ?? "Today"}',
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
      amount: Amount(m['amount_value'] as int, m['amount_currency'] as String, m['is_negative'] == 1),
      account: AccountItem(id: m['account_id'] as int, name: m['account_name'] as String, amount: Amount(0, 'EUR', false), flags: 0),
      category: m['category_id'] != null ? Category(id: m['category_id'] as int, name: m['category_name'] as String, type: CategoryType.expense) : null,
      subcategory: m['subcategory_id'] != null ? Subcategory(id: m['subcategory_id'] as int, name: m['subcategory_name'] as String) : null,
      beneficiary: m['beneficiary_id'] != null ? Beneficiary(id: m['beneficiary_id'] as int, name: m['beneficiary_name'] as String) : null,
      type: TransactionType.values.firstWhere((e) => e.name == (m['type'] as String), orElse: () => TransactionType.EXPENSE),
      isScheduled: false,
      isHeader: false,
      tags: [],
    );
  }
}
