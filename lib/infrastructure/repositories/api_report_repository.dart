import 'dart:typed_data';
import 'package:natave_flutter/domain/repositories/report_repository.dart';
import 'package:natave_flutter/domain/models/transaction_filters.dart';
import 'package:natave_flutter/services/api/api_client.dart';
import 'package:natave_flutter/core/logger/app_logger.dart';
import 'package:http/http.dart' as http;

class ApiReportRepository implements IReportRepository {
  final ApiClient _client;

  ApiReportRepository(this._client);

  @override
  Future<Map<String, double>> fetchCategoryStats(TransactionFilters filters) async {
    final params = <String, String>{
      'groupBySubcategory': filters.groupBySubcategory.toString(),
    };
    if (filters.startDate != null) params['startDate'] = filters.startDate!;
    if (filters.endDate != null) params['endDate'] = filters.endDate!;
    if (filters.accountIds != null && filters.accountIds!.isNotEmpty) {
      params['accountIds'] = filters.accountIds!.join(',');
    }
    if (filters.categoryIds != null && filters.categoryIds!.isNotEmpty) {
      params['categoryIds'] = filters.categoryIds!.join(',');
    }
    if (filters.beneficiaryIds != null && filters.beneficiaryIds!.isNotEmpty) {
      params['beneficiaryIds'] = filters.beneficiaryIds!.join(',');
    }

    final response = await _client.get('/reports/category-stats', queryParameters: params);
    return (response as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble() / 100.0));
  }

  @override
  Future<Map<String, double>> fetchEntityStats(TransactionFilters filters) async {
    final params = <String, String>{};
    if (filters.startDate != null) params['startDate'] = filters.startDate!;
    if (filters.endDate != null) params['endDate'] = filters.endDate!;
    if (filters.accountIds != null && filters.accountIds!.isNotEmpty) {
      params['accountIds'] = filters.accountIds!.join(',');
    }

    final response = await _client.get('/reports/entity-stats', queryParameters: params);
    return (response as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble() / 100.0));
  }

  @override
  Future<Map<String, double>> fetchBeneficiaryStats(TransactionFilters filters) async {
    final params = <String, String>{};
    if (filters.startDate != null) params['startDate'] = filters.startDate!;
    if (filters.endDate != null) params['endDate'] = filters.endDate!;
    if (filters.accountIds != null && filters.accountIds!.isNotEmpty) {
      params['accountIds'] = filters.accountIds!.join(',');
    }

    final response = await _client.get('/reports/beneficiary-stats', queryParameters: params);
    return (response as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble() / 100.0));
  }

  @override
  Future<Uint8List?> downloadPdf({
    required String title,
    required String chartType,
    required TransactionFilters filters,
    String? reportType,
    String lang = 'en',
  }) async {
    final params = <String, String>{
      'title': title,
      'chartType': chartType,
      'lang': lang,
    };
    if (reportType != null) params['reportType'] = reportType;
    if (filters.startDate != null) params['startDate'] = filters.startDate!;
    if (filters.endDate != null) params['endDate'] = filters.endDate!;
    
    if (filters.accountIds != null && filters.accountIds!.isNotEmpty) {
      params['accountIds'] = filters.accountIds!.join(',');
    }
    if (filters.categoryIds != null && filters.categoryIds!.isNotEmpty) {
      params['categoryIds'] = filters.categoryIds!.join(',');
    }
    if (filters.beneficiaryIds != null && filters.beneficiaryIds!.isNotEmpty) {
      params['beneficiaryIds'] = filters.beneficiaryIds!.join(',');
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
