import 'dart:typed_data';
import '../models/transaction_filters.dart';

abstract class IReportRepository {
  Future<Map<String, double>> fetchCategoryStats(TransactionFilters filters);
  Future<Map<String, double>> fetchEntityStats(TransactionFilters filters);
  Future<Map<String, double>> fetchBeneficiaryStats(TransactionFilters filters);

  Future<Uint8List?> downloadPdf({
    required String title,
    required String chartType,
    required TransactionFilters filters,
    String? reportType,
    String lang = 'en',
  });
}
