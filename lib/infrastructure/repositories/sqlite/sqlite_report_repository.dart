import 'dart:typed_data';
import 'package:natave_flutter/domain/repositories/report_repository.dart';
import 'package:natave_flutter/infrastructure/persistence/sqlite/database_helper.dart';
import 'package:natave_flutter/domain/models/transaction_item.dart';
import 'package:natave_flutter/domain/models/account_item.dart';
import 'package:natave_flutter/domain/models/category.dart';
import 'package:natave_flutter/domain/models/beneficiary.dart';
import 'package:natave_flutter/domain/models/financial_entity.dart';
import 'package:natave_flutter/domain/models/transaction_filters.dart';
import 'package:natave_flutter/infrastructure/repositories/sqlite/sqlite_transaction_repository.dart';
import 'package:natave_flutter/services/storage/local_pdf_generator.dart';

class SqliteReportRepository implements IReportRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<Map<String, double>> fetchCategoryStats(TransactionFilters filters) async {
    final db = await _dbHelper.database;
    final labelColumn = filters.groupBySubcategory ? 't.subcategory_name' : 't.category_name';
    final f = SqliteTransactionRepository.buildFilterConditions(filters);
    
    // Filtro base: Solo gastos por defecto para el gráfico de distribución, 
    // a menos que se quiera ver ingresos (esto se puede mejorar luego)
    String clause = f['clause'];
    if (!clause.contains('is_negative')) {
      clause += ' AND t.is_negative = 1';
    }

    final List<Map<String, dynamic>> results = await db.rawQuery(
      'SELECT $labelColumn as label, SUM(t.amount_value) as total FROM transactions t WHERE $clause GROUP BY $labelColumn',
      f['args']
    );
    return { for (var row in results) (row['label']?.toString() ?? 'Otros'): (row['total'] as num).toDouble().abs() / 100.0 };
  }

  @override
  Future<Map<String, double>> fetchEntityStats(TransactionFilters filters) async {
    final db = await _dbHelper.database;
    final f = SqliteTransactionRepository.buildFilterConditions(filters);
    final List<Map<String, dynamic>> results = await db.rawQuery(
      'SELECT t.account_name as label, SUM(t.amount_value) as total FROM transactions t WHERE ${f['clause']} GROUP BY t.account_name',
      f['args']
    );
    return { for (var row in results) (row['label']?.toString() ?? 'Cuenta'): (row['total'] as num).toDouble() / 100.0 };
  }

  @override
  Future<Map<String, double>> fetchBeneficiaryStats(TransactionFilters filters) async {
    final db = await _dbHelper.database;
    final f = SqliteTransactionRepository.buildFilterConditions(filters);
    final List<Map<String, dynamic>> results = await db.rawQuery(
      'SELECT t.beneficiary_name as label, SUM(t.amount_value) as total FROM transactions t WHERE ${f['clause']} AND t.beneficiary_name IS NOT NULL GROUP BY t.beneficiary_name',
      f['args']
    );
    return { for (var row in results) row['label'].toString(): (row['total'] as num).toDouble() / 100.0 };
  }

  Future<Map<String, Map<String, double>>> _fetchCategoryStatsByCurrency(TransactionFilters filters) async {
    final db = await _dbHelper.database;
    final f = SqliteTransactionRepository.buildFilterConditions(filters);
    final List<Map<String, dynamic>> results = await db.rawQuery(
      'SELECT t.category_name as label, t.amount_currency as currency, SUM(t.amount_value) as total FROM transactions t WHERE ${f['clause']} GROUP BY t.category_name, t.amount_currency',
      f['args']
    );
    final Map<String, Map<String, double>> stats = {};
    for (var row in results) {
      final label = row['label']?.toString() ?? 'Otros';
      final currency = row['currency']?.toString() ?? 'EUR';
      stats.putIfAbsent(label, () => {});
      stats[label]![currency] = (row['total'] as num).toDouble() / 100.0;
    }
    return stats;
  }

  @override
  Future<Uint8List?> downloadPdf({
    required String title, 
    required String chartType, 
    required TransactionFilters filters, 
    String? reportType, 
    String lang = 'en'
  }) async {
    final db = await _dbHelper.database;
    
    // 1. Obtener datos para el resumen (categorías) respetando todos los filtros
    final summary = await _fetchCategoryStatsByCurrency(filters);
    final f = SqliteTransactionRepository.buildFilterConditions(filters);

    // 2. Obtener transacciones segregadas por Entidad y Cuenta real
    final List<Map<String, dynamic>> rows = await db.rawQuery('''
      SELECT t.*, a.entity_name as real_entity_name 
      FROM transactions t 
      LEFT JOIN accounts a ON t.account_id = a.id 
      WHERE ${f['clause']} 
      ORDER BY a.entity_name, t.account_name, t.date DESC
    ''', f['args']);
    
    final Map<String, Map<String, List<TransactionItem>>> segregatedData = {};

    for (var row in rows) {
      final tx = _mapToTransactionItem(row);
      final entityName = row['real_entity_name']?.toString() ?? 'General';
      final accountName = row['account_name']?.toString() ?? 'Default';

      segregatedData.putIfAbsent(entityName, () => {});
      segregatedData[entityName]!.putIfAbsent(accountName, () => []);
      segregatedData[entityName]![accountName]!.add(tx);
    }

    // 3. Generar el PDF usando el motor local
    return await LocalPdfReportGenerator.generate(
      title: title,
      period: '${filters.startDate?.split('T').first ?? "Inicio"} - ${filters.endDate?.split('T').first ?? "Hoy"}',
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
      account: AccountItem(id: m['account_id'] as int, name: m['account_name'] as String, amount: Amount(0, m['amount_currency'] as String, false), flags: 0),
      category: m['category_id'] != null ? Category(id: m['category_id'] as int, name: m['category_name'] as String, type: CategoryType.expense) : null,
      subcategory: m['subcategory_id'] != null ? Subcategory(id: m['subcategory_id'] as int, name: m['subcategory_name'] as String) : null,
      beneficiary: m['beneficiary_id'] != null ? Beneficiary(id: m['beneficiary_id'] as int, name: m['beneficiary_name'] as String) : null,
      type: TransactionType.values.firstWhere((e) => e.name == (m['type'] as String), orElse: () => TransactionType.EXPENSE),
      isScheduled: false, isHeader: false, tags: [],
    );
  }
}
