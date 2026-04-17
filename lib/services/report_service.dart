import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'http_client_manager.dart';

class ReportService {
  final HttpClientManager _clientManager;

  ReportService(this._clientManager);

  Future<Map<String, double>> fetchCategoryStats({
    String? startDate,
    String? endDate,
    List<int>? accountIds,
    bool groupBySubcategory = false,
  }) async {
    try {
      String url = '${_clientManager.baseUrl}/reports/category-stats?';
      if (startDate != null) url += 'startDate=$startDate&';
      if (endDate != null) url += 'endDate=$endDate&';
      if (accountIds != null) url += 'accountIds=${accountIds.join(",")}&';
      if (groupBySubcategory) url += 'groupBySubcategory=true&';

      final response = await http.get(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
      } else {
        throw 'Error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Uint8List?> downloadPdfReport({
    required String title,
    required String chartType,
    String? startDate,
    String? endDate,
    List<int>? accountIds,
    List<int>? categoryIds,
    String lang = 'en',
  }) async {
    try {
      String url = '${_clientManager.baseUrl}/reports/pdf?title=$title&chartType=$chartType&lang=$lang&';
      if (startDate != null) url += 'startDate=$startDate&';
      if (endDate != null) url += 'endDate=$endDate&';
      if (accountIds != null) url += 'accountIds=${accountIds.join(",")}&';
      if (categoryIds != null) url += 'categoryIds=${categoryIds.join(",")}&';

      final response = await http.get(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw 'Error ${response.statusCode}';
      }
    } catch (e) {
      rethrow;
    }
  }
}
