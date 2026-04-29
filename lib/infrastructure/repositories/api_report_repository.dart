import 'dart:typed_data';
import 'package:natave_flutter/domain/repositories/report_repository.dart';
import 'package:natave_flutter/services/api/api_client.dart';
import 'package:natave_flutter/core/logger/app_logger.dart';
import 'package:http/http.dart' as http;

class ApiReportRepository implements IReportRepository {
  final ApiClient _client;

  ApiReportRepository(this._client);

  @override
  Future<Map<String, double>> fetchCategoryStats({
    String? startDate,
    String? endDate,
    List<int>? accountIds,
    bool groupBySubcategory = false,
  }) async {
    final params = <String, String>{
      'groupBySubcategory': groupBySubcategory.toString(),
    };
    if (startDate != null) params['startDate'] = startDate;
    if (endDate != null) params['endDate'] = endDate;
    if (accountIds != null && accountIds.isNotEmpty) {
      params['accountIds'] = accountIds.join(',');
    }

    final response = await _client.get('/reports/category-stats', queryParameters: params);
    return (response as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  @override
  Future<Map<String, double>> fetchEntityStats({
    String? startDate,
    String? endDate,
    List<int>? accountIds,
  }) async {
    final params = <String, String>{};
    if (startDate != null) params['startDate'] = startDate;
    if (endDate != null) params['endDate'] = endDate;
    if (accountIds != null && accountIds.isNotEmpty) {
      params['accountIds'] = accountIds.join(',');
    }

    final response = await _client.get('/reports/entity-stats', queryParameters: params);
    return (response as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  @override
  Future<Map<String, double>> fetchBeneficiaryStats({
    String? startDate,
    String? endDate,
    List<int>? accountIds,
  }) async {
    final params = <String, String>{};
    if (startDate != null) params['startDate'] = startDate;
    if (endDate != null) params['endDate'] = endDate;
    if (accountIds != null && accountIds.isNotEmpty) {
      params['accountIds'] = accountIds.join(',');
    }

    final response = await _client.get('/reports/beneficiary-stats', queryParameters: params);
    return (response as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble()));
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
    final params = <String, String>{
      'title': title,
      'chartType': chartType,
      'lang': lang,
    };
    if (reportType != null) params['reportType'] = reportType;
    if (startDate != null) params['startDate'] = startDate;
    if (endDate != null) params['endDate'] = endDate;
    
    if (accountIds != null && accountIds.isNotEmpty) {
      params['accountIds'] = accountIds.join(',');
    }
    if (categoryIds != null && categoryIds.isNotEmpty) {
      params['categoryIds'] = categoryIds.join(',');
    }
    if (beneficiaryIds != null && beneficiaryIds.isNotEmpty) {
      params['beneficiaryIds'] = beneficiaryIds.join(',');
    }
    
    final baseUrl = _client.baseUrl.endsWith('/') ? _client.baseUrl.substring(0, _client.baseUrl.length - 1) : _client.baseUrl;
    final uri = Uri.parse('$baseUrl/reports/download').replace(queryParameters: params);
    final headers = await _client.authHeaders();
    AppLogger.logRequest('GET', uri.toString(), headers);

    final response = await http.get(uri, headers: headers)
        .timeout(Duration(seconds: _client.apiTimeout));
        
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      _client.processResponse(response);
      return null;
    }
  }
}
