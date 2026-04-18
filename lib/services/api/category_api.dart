import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/category.dart';
import '../../domain/models/transaction_item.dart';
import '../../core/logger/app_logger.dart';
import 'api_client.dart';

class CategoryApi {
  final ApiClient _client;

  CategoryApi(this._client);

  Future<List<Category>> fetchAll() async {
    final url = '${_client.baseUrl}/categories';
    final headers = await _client.authHeaders();
    AppLogger.logRequest('GET', url, headers);

    final response = await http.get(Uri.parse(url), headers: headers)
        .timeout(Duration(seconds: _client.apiTimeout));
        
    final List<dynamic> list = _client.processResponse(response);
    return list.map((json) => Category.fromJson(json)).toList();
  }

  Future<Category?> create(Category category, {int? parentId}) async {
    final url = '${_client.baseUrl}/categories';
    final headers = await _client.authHeaders();
    final body = jsonEncode({
      'name': category.name,
      'type': category.type == CategoryType.income ? 'INCOME' : 'EXPENSE',
      'parent': parentId != null ? {'id': parentId} : null,
    });
    
    AppLogger.logRequest('POST', url, headers);

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    ).timeout(Duration(seconds: _client.apiTimeout));
    
    return Category.fromJson(_client.processResponse(response));
  }

  Future<Category?> update(int id, Category category) async {
    final url = '${_client.baseUrl}/categories/$id';
    final headers = await _client.authHeaders();
    AppLogger.logRequest('PUT', url, headers);

    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(category.toJson()),
    ).timeout(Duration(seconds: _client.apiTimeout));
    
    return Category.fromJson(_client.processResponse(response));
  }

  Future<Subcategory?> updateSubcategory(int id, Subcategory subcategory) async {
    final url = '${_client.baseUrl}/categories/subcategories/$id';
    final headers = await _client.authHeaders();
    AppLogger.logRequest('PUT', url, headers);

    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(subcategory.toJson()),
    ).timeout(Duration(seconds: _client.apiTimeout));
    
    return Subcategory.fromJson(_client.processResponse(response));
  }

  Future<Subcategory?> createSubcategory(int categoryId, Subcategory subcategory) async {
    final url = '${_client.baseUrl}/categories/$categoryId/subcategories';
    final headers = await _client.authHeaders();
    AppLogger.logRequest('POST', url, headers);

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(subcategory.toJson()),
    ).timeout(Duration(seconds: _client.apiTimeout));
    
    return Subcategory.fromJson(_client.processResponse(response));
  }

  Future<bool> deleteSubcategory(int id) async {
    final url = '${_client.baseUrl}/categories/subcategories/$id';
    final headers = await _client.authHeaders();
    AppLogger.logRequest('DELETE', url, headers);

    final response = await http.delete(Uri.parse(url), headers: headers)
        .timeout(Duration(seconds: _client.apiTimeout));
        
    return _client.isSuccess(response.statusCode);
  }

  Future<List<TransactionItem>> fetchTransactionsByCategory(int categoryId, {int page = 0, int size = 20}) async {
    final uri = Uri.parse('${_client.baseUrl}/categories/$categoryId/transactions')
        .replace(queryParameters: {'page': '$page', 'size': '$size'});
    final headers = await _client.authHeaders();
    AppLogger.logRequest('GET', uri.toString(), headers);

    final response = await http.get(uri, headers: headers)
        .timeout(Duration(seconds: _client.apiTimeout));
        
    final body = _client.processResponse(response);
    final List<dynamic> list = body is List ? body : (body['content'] ?? []);
    return list.map((json) => TransactionItem.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> delete(int id) async {
    final url = '${_client.baseUrl}/categories/$id';
    final headers = await _client.authHeaders();
    AppLogger.logRequest('DELETE', url, headers);

    try {
      final response = await http.delete(Uri.parse(url), headers: headers)
          .timeout(Duration(seconds: _client.apiTimeout));
      return {'success': _client.isSuccess(response.statusCode)};
    } catch (e) {
      AppLogger.error('Delete category error', e);
      return {'success': false, 'message': e.toString()};
    }
  }
}
