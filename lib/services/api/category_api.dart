import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/category.dart';
import '../../domain/models/transaction_item.dart';
import 'api_client.dart';

class CategoryApi {
  final ApiClient _client;

  CategoryApi(this._client);

  Future<List<Category>> fetchAll() async {
    final response = await http.get(
      Uri.parse('${_client.baseUrl}/categories'),
      headers: await _client.authHeaders(),
    );
    final List<dynamic> list = _client.processResponse(response);
    return list.map((json) => Category.fromJson(json)).toList();
  }

  Future<Category?> create(Category category, {int? parentId}) async {
    final response = await http.post(
      Uri.parse('${_client.baseUrl}/categories'),
      headers: await _client.authHeaders(),
      body: jsonEncode({
        'name': category.name,
        'type': category.type == CategoryType.income ? 'INCOME' : 'EXPENSE',
        'parent': parentId != null ? {'id': parentId} : null,
      }),
    );
    return Category.fromJson(_client.processResponse(response));
  }

  Future<Category?> update(int id, Category category) async {
    final response = await http.put(
      Uri.parse('${_client.baseUrl}/categories/$id'),
      headers: await _client.authHeaders(),
      body: jsonEncode(category.toJson()),
    );
    return Category.fromJson(_client.processResponse(response));
  }

  Future<Subcategory?> updateSubcategory(int id, Subcategory subcategory) async {
    final response = await http.put(
      Uri.parse('${_client.baseUrl}/categories/subcategories/$id'),
      headers: await _client.authHeaders(),
      body: jsonEncode(subcategory.toJson()),
    );
    return Subcategory.fromJson(_client.processResponse(response));
  }

  Future<Subcategory?> createSubcategory(int categoryId, Subcategory subcategory) async {
    final response = await http.post(
      Uri.parse('${_client.baseUrl}/categories/$categoryId/subcategories'),
      headers: await _client.authHeaders(),
      body: jsonEncode(subcategory.toJson()),
    );
    return Subcategory.fromJson(_client.processResponse(response));
  }

  Future<bool> deleteSubcategory(int id) async {
    final response = await http.delete(
      Uri.parse('${_client.baseUrl}/categories/subcategories/$id'),
      headers: await _client.authHeaders(),
    );
    return _client.isSuccess(response.statusCode);
  }

  Future<List<TransactionItem>> fetchTransactionsByCategory(int categoryId, {int page = 0, int size = 20}) async {
    final uri = Uri.parse('${_client.baseUrl}/categories/$categoryId/transactions')
        .replace(queryParameters: {'page': '$page', 'size': '$size'});
    final response = await http.get(uri, headers: await _client.authHeaders());
    final body = _client.processResponse(response);
    final List<dynamic> list = body is List ? body : (body['content'] ?? []);
    return list.map((json) => TransactionItem.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> delete(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${_client.baseUrl}/categories/$id'),
        headers: await _client.authHeaders(),
      );
      return {'success': _client.isSuccess(response.statusCode)};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
