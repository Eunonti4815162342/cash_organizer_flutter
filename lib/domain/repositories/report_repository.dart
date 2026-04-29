import 'dart:typed_data';

abstract class IReportRepository {
  Future<Map<String, double>> fetchCategoryStats({
    String? startDate,
    String? endDate,
    List<int>? accountIds,
    bool groupBySubcategory = false,
  });

  Future<Map<String, double>> fetchEntityStats({
    String? startDate,
    String? endDate,
    List<int>? accountIds,
  });

  Future<Map<String, double>> fetchBeneficiaryStats({
    String? startDate,
    String? endDate,
    List<int>? accountIds,
  });

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
  });
}
