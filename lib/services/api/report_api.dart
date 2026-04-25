import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../core/logger/app_logger.dart';
import 'api_client.dart';

class ReportApi {
  final ApiClient _client;

  ReportApi(this._client);

  Future<Map<String, double>> fetchCategoryStats({
    String? startDate,
    String? endDate,
    List<int>? accountIds,
    bool groupBySubcategory = false,
  }) async {
    final params = <String, String>{};
    if (startDate != null) params['startDate'] = startDate;
    if (endDate != null) params['endDate'] = endDate;
    if (accountIds != null) params['accountIds'] = accountIds.join(',');
    if (groupBySubcategory) params['groupBySubcategory'] = 'true';
    
    final uri = Uri.parse('${_client.baseUrl}/reports/category-stats').replace(queryParameters: params);
    final headers = await _client.authHeaders();
    AppLogger.logRequest('GET', uri.toString(), headers);

    final response = await http.get(uri, headers: headers)
        .timeout(Duration(seconds: _client.apiTimeout));
        
    final Map<String, dynamic> data = _client.processResponse(response);
    return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  Future<Map<String, double>> fetchEntityStats({
    String? startDate,
    String? endDate,
    List<int>? accountIds,
  }) async {
    final params = <String, String>{};
    if (startDate != null) params['startDate'] = startDate;
    if (endDate != null) params['endDate'] = endDate;
    if (accountIds != null) params['accountIds'] = accountIds.join(',');
    
    final uri = Uri.parse('${_client.baseUrl}/reports/entity-stats').replace(queryParameters: params);
    final headers = await _client.authHeaders();
    AppLogger.logRequest('GET', uri.toString(), headers);

    final response = await http.get(uri, headers: headers)
        .timeout(Duration(seconds: _client.apiTimeout));
        
    final Map<String, dynamic> data = _client.processResponse(response);
    return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  Future<Map<String, double>> fetchBeneficiaryStats({
    String? startDate,
    String? endDate,
    List<int>? accountIds,
  }) async {
    final params = <String, String>{};
    if (startDate != null) params['startDate'] = startDate;
    if (endDate != null) params['endDate'] = endDate;
    if (accountIds != null) params['accountIds'] = accountIds.join(',');
    
    final uri = Uri.parse('${_client.baseUrl}/reports/beneficiary-stats').replace(queryParameters: params);
    final headers = await _client.authHeaders();
    AppLogger.logRequest('GET', uri.toString(), headers);

    final response = await http.get(uri, headers: headers)
        .timeout(Duration(seconds: _client.apiTimeout));
        
    final Map<String, dynamic> data = _client.processResponse(response);
    return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  Future<Uint8List?> downloadPdf({
    required String title,
    required String chartType,
    String? reportType,
    String? startDate,
    String? endDate,
    List<int>? accountIds,
    List<int>? categoryIds,
    String lang = 'en',
  }) async {
    final params = <String, String>{
      'title': title,
      'chartType': chartType,
      'lang': lang,
    };
    if (reportType != null) params['reportType'] = reportType;
    if (startDate != null) params['startDate'] = startDate;
    if (endDate != null) params['endDate'] = endDate;
    if (accountIds != null) params['accountIds'] = accountIds.join(',');
    if (categoryIds != null) params['categoryIds'] = categoryIds.join(',');
    
    final baseUrl = _client.baseUrl.endsWith('/') ? _client.baseUrl.substring(0, _client.baseUrl.length - 1) : _client.baseUrl;
    final uri = Uri.parse('$baseUrl/reports/download').replace(queryParameters: params);
    final headers = await _client.authHeaders();
    AppLogger.logRequest('GET', uri.toString(), headers);

    final response = await http.get(uri, headers: headers)
        .timeout(Duration(seconds: _client.apiTimeout));
        
    return response.bodyBytes;
  }
}
