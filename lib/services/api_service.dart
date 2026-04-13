import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/models/account_item.dart';
import '../domain/models/transaction_item.dart';
import '../domain/models/category.dart';
import '../domain/models/financial_entity.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();
  
  static const String _host = '100.86.48.34';
  static const int _port = 8085;

  // Método robusto para construir URIs sin errores de espacios
  Uri _getUri(String path, [Map<String, dynamic>? queryParams]) {
    if (kIsWeb) {
      return Uri.http('localhost:$_port', '/api$path', queryParams?.map((k, v) => MapEntry(k, v.toString())));
    }
    return Uri.http('$_host:$_port', '/api$path', queryParams?.map((k, v) => MapEntry(k, v.toString())));
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> isOnline() async {
    try {
      final response = await http.get(_getUri('/v2/auth/login')).timeout(const Duration(seconds: 2));
      return response.statusCode != 0;
    } catch (_) { return false; }
  }

  // --- AUTH ---
  Future<Map<String, dynamic>?> login(String email, String password, {bool rememberMe = false}) async {
    try {
      final response = await http.post(
        _getUri('/v2/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email, 
          'password': password,
          'rememberMe': rememberMe
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw 'Status ${response.statusCode}: ${response.body}';
      }
    } catch (e) { throw e.toString(); }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<bool> register(String email, String password) async {
    try {
      final response = await http.post(
        _getUri('/v2/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) { throw e.toString(); }
  }

  // --- ACCOUNTS ---
  Future<List<AccountItem>> fetchAccounts() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(_getUri('/accounts'), headers: headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => AccountItem.fromJson(json)).toList();
      }
    } catch (_) { }
    return []; 
  }

  Future<AccountItem?> createAccount(Map<String, dynamic> accountData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(_getUri('/accounts'), headers: headers, body: jsonEncode(accountData));
      return (response.statusCode == 200 || response.statusCode == 201) ? AccountItem.fromJson(jsonDecode(response.body)) : null;
    } catch (_) { return null; }
  }

  Future<AccountItem?> updateAccount(int id, Map<String, dynamic> accountData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(_getUri('/accounts/$id'), headers: headers, body: jsonEncode(accountData));
      return (response.statusCode == 200 || response.statusCode == 201) ? AccountItem.fromJson(jsonDecode(response.body)) : null;
    } catch (_) { return null; }
  }

  Future<bool> deleteAccount(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(_getUri('/accounts/$id'), headers: headers);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) { return false; }
  }

  Future<bool> deleteAccountPermanently(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(_getUri('/accounts/$id/permanent'), headers: headers);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) { return false; }
  }

  // --- ENTITIES ---
  Future<List<FinancialEntity>> fetchEntities() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(_getUri('/entities'), headers: headers).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => FinancialEntity.fromJson(json)).toList();
      }
    } catch (_) { }
    return [];
  }

  Future<FinancialEntity?> createEntity(Map<String, dynamic> entityData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(_getUri('/entities'), headers: headers, body: jsonEncode(entityData));
      return (response.statusCode == 200 || response.statusCode == 201) ? FinancialEntity.fromJson(jsonDecode(response.body)) : null;
    } catch (_) { return null; }
  }

  Future<bool> deleteEntity(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(_getUri('/entities/$id'), headers: headers);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) { return false; }
  }

  // --- TRANSACTIONS ---
  Future<List<TransactionItem>> fetchTransactions({String? startDate, String? endDate, String? accountId}) async {
    try {
      final headers = await _getHeaders();
      Map<String, String> queryParams = {};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (accountId != null) queryParams['accountId'] = accountId;

      final response = await http.get(_getUri('/transactions', queryParams), headers: headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> jsonList = body['content']; 
        return jsonList.map((json) => TransactionItem.fromJson(json)).toList();
      }
    } catch (_) { }
    return [];
  }

  Future<TransactionItem?> createTransaction(Map<String, dynamic> transactionData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(_getUri('/transactions'), headers: headers, body: jsonEncode(transactionData));
      return (response.statusCode == 200 || response.statusCode == 201) ? TransactionItem.fromJson(jsonDecode(response.body)) : null;
    } catch (_) { return null; }
  }

  Future<TransactionItem?> updateTransaction(int id, Map<String, dynamic> transactionData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(_getUri('/transactions/$id'), headers: headers, body: jsonEncode(transactionData));
      return (response.statusCode == 200 || response.statusCode == 201) ? TransactionItem.fromJson(jsonDecode(response.body)) : null;
    } catch (_) { return null; }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(_getUri('/transactions/$id'), headers: headers);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) { return false; }
  }

  // --- CATEGORIES ---
  Future<List<Category>> fetchCategories() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(_getUri('/categories'), headers: headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Category.fromJson(json)).toList();
      }
    } catch (_) { }
    return [];
  }

  Future<Category?> createCategory(Category category, {int? parentId}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(_getUri('/categories'), headers: headers, body: jsonEncode({
        'name': category.name,
        'type': category.type == CategoryType.income ? 'INCOME' : 'EXPENSE',
        'parent': parentId != null ? {'id': parentId} : null,
      }));
      return (response.statusCode == 200 || response.statusCode == 201) ? Category.fromJson(jsonDecode(response.body)) : null;
    } catch (_) { return null; }
  }

  Future<Category?> updateCategory(int id, Category category) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(_getUri('/categories/$id'), headers: headers, body: jsonEncode(category.toJson()));
      return response.statusCode == 200 ? Category.fromJson(jsonDecode(response.body)) : null;
    } catch (_) { return null; }
  }

  Future<Subcategory?> updateSubcategory(int id, Subcategory subcategory) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(_getUri('/categories/subcategories/$id'), headers: headers, body: jsonEncode(subcategory.toJson()));
      return response.statusCode == 200 ? Subcategory.fromJson(jsonDecode(response.body)) : null;
    } catch (_) { return null; }
  }

  Future<Subcategory?> createSubcategory(int categoryId, Subcategory subcategory) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(_getUri('/categories/$categoryId/subcategories'), headers: headers, body: jsonEncode(subcategory.toJson()));
      return (response.statusCode == 200 || response.statusCode == 201) ? Subcategory.fromJson(jsonDecode(response.body)) : null;
    } catch (_) { return null; }
  }

  Future<bool> deleteSubcategory(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(_getUri('/categories/subcategories/$id'), headers: headers);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) { return false; }
  }

  // --- STATS & REPORTS ---
  Future<Map<String, double>> fetchCategoryStats({
    String? startDate,
    String? endDate,
    List<int>? accountIds,
    bool groupBySubcategory = false,
  }) async {
    try {
      final headers = await _getHeaders();
      final Map<String, dynamic> queryParams = {};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (accountIds != null && accountIds.isNotEmpty) queryParams['accountIds'] = accountIds.join(',');
      if (groupBySubcategory) queryParams['groupBySubcategory'] = true;

      final response = await http.get(_getUri('/reports/category-stats', queryParams), headers: headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
      }
    } catch (_) { }
    return {};
  }

  Future<Uint8List?> downloadPdfReport({
    required String title,
    required String chartType,
    String? startDate,
    String? endDate,
    List<int>? accountIds,
    List<int>? categoryIds,
  }) async {
    try {
      final headers = await _getHeaders();
      final Map<String, dynamic> queryParams = {'title': title, 'chartType': chartType};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (accountIds != null && accountIds.isNotEmpty) queryParams['accountIds'] = accountIds.join(',');
      if (categoryIds != null && categoryIds.isNotEmpty) queryParams['categoryIds'] = categoryIds.join(',');

      final response = await http.get(_getUri('/reports/pdf', queryParams), headers: headers).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (_) { }
    return null;
  }

  Future<List<TransactionItem>> fetchTransactionsByCategory(int categoryId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(_getUri('/categories/$categoryId/transactions'), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => TransactionItem.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> deleteCategory(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(_getUri('/categories/$id'), headers: headers);
      return {'success': response.statusCode == 200 || response.statusCode == 204};
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }
}
