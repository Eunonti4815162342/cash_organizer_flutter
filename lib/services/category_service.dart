import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/models/category.dart';
import 'http_client_manager.dart';

class CategoryService {
  final HttpClientManager _clientManager;

  CategoryService(this._clientManager);

  Future<List<Category>> fetchCategories() async {
    try {
      final url = '${_clientManager.baseUrl}/categories';
      final response = await http.get(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Category.fromJson(json)).toList();
      } else {
        throw 'Error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Category?> createCategory(Category category, {int? parentId}) async {
    try {
      final url = '${_clientManager.baseUrl}/categories';
      final response = await http.post(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
        body: jsonEncode({
          'name': category.name,
          'type': category.type == CategoryType.income ? 'INCOME' : 'EXPENSE',
          'parent': parentId != null ? {'id': parentId} : null
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Category.fromJson(jsonDecode(response.body));
      } else {
        throw 'Error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Category?> updateCategory(int id, Category category) async {
    try {
      final url = '${_clientManager.baseUrl}/categories/$id';
      final response = await http.put(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
        body: jsonEncode(category.toJson()),
      );

      if (response.statusCode == 200) {
        return Category.fromJson(jsonDecode(response.body));
      } else {
        throw 'Error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      final url = '${_clientManager.baseUrl}/categories/$id';
      final response = await http.delete(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<Subcategory?> createSubcategory(int categoryId, Subcategory subcategory) async {
    try {
      final url = '${_clientManager.baseUrl}/categories/$categoryId/subcategories';
      final response = await http.post(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
        body: jsonEncode(subcategory.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Subcategory.fromJson(jsonDecode(response.body));
      } else {
        throw 'Error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Subcategory?> updateSubcategory(int id, Subcategory subcategory) async {
    try {
      final url = '${_clientManager.baseUrl}/categories/subcategories/$id';
      final response = await http.put(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
        body: jsonEncode(subcategory.toJson()),
      );

      if (response.statusCode == 200) {
        return Subcategory.fromJson(jsonDecode(response.body));
      } else {
        throw 'Error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteSubcategory(int id) async {
    try {
      final url = '${_clientManager.baseUrl}/categories/subcategories/$id';
      final response = await http.delete(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}
