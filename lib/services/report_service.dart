import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/exceptions/app_exceptions.dart';
import '../core/error/error_handler.dart';
import '../core/logger/app_logger.dart';
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

      AppLogger.logRequest('GET', url, await _clientManager.getHeaders());

      final response = await http.get(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
      ).timeout(Duration(seconds: _clientManager.apiTimeout));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        AppLogger.logResponse(response.statusCode, url, 'Fetched ${data.length} category stats');
        return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
      } else {
        throw ErrorHandler.handleHttpError(response);
      }
    } on AppException {
      rethrow;
    } catch (e, stackTrace) {
      final exception = ErrorHandler.handleException(e, stackTrace);
      AppLogger.logException(exception);
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

      AppLogger.logRequest('GET', url, await _clientManager.getHeaders());

      final response = await http.get(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
      ).timeout(Duration(seconds: _clientManager.apiTimeout));

      if (response.statusCode == 200) {
        AppLogger.info('PDF report downloaded: $title');
        return response.bodyBytes;
      } else {
        throw ErrorHandler.handleHttpError(response);
      }
    } on AppException {
      rethrow;
    } catch (e, stackTrace) {
      final exception = ErrorHandler.handleException(e, stackTrace);
      AppLogger.logException(exception);
      rethrow;
    }
  }
}
