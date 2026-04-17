import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/models/category.dart';
import '../core/exceptions/app_exceptions.dart';
import '../core/error/error_handler.dart';
import '../core/logger/app_logger.dart';
import 'http_client_manager.dart';

class CategoryService {
  final HttpClientManager _clientManager;

  CategoryService(this._clientManager);

  Future<List<Category>> fetchCategories() async {
    try {
      final url = '${_clientManager.baseUrl}/categories';
      AppLogger.logRequest('GET', url, await _clientManager.getHeaders());

      final response = await http.get(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
      ).timeout(Duration(seconds: _clientManager.apiTimeout));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        AppLogger.logResponse(response.statusCode, url, 'Fetched ${jsonList.length} categories');
        return jsonList.map((json) => Category.fromJson(json)).toList();
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

  Future<Category?> createCategory(Category category, {int? parentId}) async {
    try {
      final url = '${_clientManager.baseUrl}/categories';
      AppLogger.logRequest('POST', url, await _clientManager.getHeaders());

      final response = await http.post(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
        body: jsonEncode({
          'name': category.name,
          'type': category.type == CategoryType.income ? 'INCOME' : 'EXPENSE',
          'parent': parentId != null ? {'id': parentId} : null
        }),
      ).timeout(Duration(seconds: _clientManager.apiTimeout));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = Category.fromJson(jsonDecode(response.body));
        AppLogger.info('Category created successfully');
        return result;
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

  Future<Category?> updateCategory(int id, Category category) async {
    try {
      final url = '${_clientManager.baseUrl}/categories/$id';
      AppLogger.logRequest('PUT', url, await _clientManager.getHeaders());

      final response = await http.put(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
        body: jsonEncode(category.toJson()),
      ).timeout(Duration(seconds: _clientManager.apiTimeout));

      if (response.statusCode == 200) {
        final result = Category.fromJson(jsonDecode(response.body));
        AppLogger.info('Category $id updated successfully');
        return result;
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

  Future<bool> deleteCategory(int id) async {
    try {
      final url = '${_clientManager.baseUrl}/categories/$id';
      AppLogger.logRequest('DELETE', url, await _clientManager.getHeaders());

      final response = await http.delete(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
      ).timeout(Duration(seconds: _clientManager.apiTimeout));

      final success = response.statusCode == 200 || response.statusCode == 204;
      if (success) {
        AppLogger.info('Category $id deleted successfully');
      }
      return success;
    } catch (e, stackTrace) {
      AppLogger.error('Delete category error', e, stackTrace);
      return false;
    }
  }

  Future<Subcategory?> createSubcategory(int categoryId, Subcategory subcategory) async {
    try {
      final url = '${_clientManager.baseUrl}/categories/$categoryId/subcategories';
      AppLogger.logRequest('POST', url, await _clientManager.getHeaders());

      final response = await http.post(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
        body: jsonEncode(subcategory.toJson()),
      ).timeout(Duration(seconds: _clientManager.apiTimeout));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = Subcategory.fromJson(jsonDecode(response.body));
        AppLogger.info('Subcategory created successfully');
        return result;
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

  Future<Subcategory?> updateSubcategory(int id, Subcategory subcategory) async {
    try {
      final url = '${_clientManager.baseUrl}/categories/subcategories/$id';
      AppLogger.logRequest('PUT', url, await _clientManager.getHeaders());

      final response = await http.put(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
        body: jsonEncode(subcategory.toJson()),
      ).timeout(Duration(seconds: _clientManager.apiTimeout));

      if (response.statusCode == 200) {
        final result = Subcategory.fromJson(jsonDecode(response.body));
        AppLogger.info('Subcategory $id updated successfully');
        return result;
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

  Future<bool> deleteSubcategory(int id) async {
    try {
      final url = '${_clientManager.baseUrl}/categories/subcategories/$id';
      AppLogger.logRequest('DELETE', url, await _clientManager.getHeaders());

      final response = await http.delete(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
      ).timeout(Duration(seconds: _clientManager.apiTimeout));

      final success = response.statusCode == 200 || response.statusCode == 204;
      if (success) {
        AppLogger.info('Subcategory $id deleted successfully');
      }
      return success;
    } catch (e, stackTrace) {
      AppLogger.error('Delete subcategory error', e, stackTrace);
      return false;
    }
  }
}
