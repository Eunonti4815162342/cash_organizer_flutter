import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kReleaseMode, kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/models/account_item.dart';
import '../domain/models/transaction_item.dart';
import '../domain/models/category.dart';
import '../domain/models/financial_entity.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();
  static const String _serverUrl = "http://100.86.48.34:8085/api";

  static String get baseUrl {
    String url = _serverUrl.trim();
    if (kIsWeb) url = 'http://localhost:8085/api';
    return url;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _processResponse(http.Response response) {
    print('DEBUG [ApiService] Response: ${response.statusCode}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw 'SESSION_EXPIRED';
    } else {
      throw 'Error ${response.statusCode}: ${response.body}';
    }
  }

  Future<bool> isOnline() async {
    try {
      final url = '$baseUrl/auth/login';
      print('DEBUG [ApiService] Testing: $url');
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 2));
      return response.statusCode != 0;
    } catch (_) { return false; }
  }

  // --- AUTH ---
  Future<Map<String, dynamic>?> login(String email, String password, {bool rememberMe = false}) async {
    final url = '$baseUrl/auth/login';
    print('DEBUG [ApiService] Calling login at: $url');
    final response = await http.post(
      Uri.parse(url), 
      headers: {'Content-Type': 'application/json'}, 
      body: jsonEncode({'email': email, 'password': password, 'rememberMe': rememberMe})
    ).timeout(const Duration(seconds: 15));
    return _processResponse(response);
  }

  Future<bool> register(String email, String password) async {
    final response = await http.post(Uri.parse('$baseUrl/auth/register'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'password': password}));
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<void> logout() async { await _storage.delete(key: 'jwt_token'); }

  // --- ACCOUNTS ---
  Future<List<AccountItem>> fetchAccounts() async {
    final response = await http.get(Uri.parse('$baseUrl/accounts'), headers: await _getHeaders());
    final body = _processResponse(response);
    final List<dynamic> jsonList = body is List ? body : (body['content'] ?? []);
    return jsonList.map((json) => AccountItem.fromJson(json)).toList();
  }

  Future<AccountItem?> createAccount(Map<String, dynamic> accountData) async {
    final response = await http.post(Uri.parse('$baseUrl/accounts'), headers: await _getHeaders(), body: jsonEncode(accountData));
    return AccountItem.fromJson(_processResponse(response));
  }

  Future<AccountItem?> updateAccount(int id, Map<String, dynamic> accountData) async {
    final response = await http.put(Uri.parse('$baseUrl/accounts/$id'), headers: await _getHeaders(), body: jsonEncode(accountData));
    return AccountItem.fromJson(_processResponse(response));
  }

  Future<bool> deleteAccount(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/accounts/$id'), headers: await _getHeaders());
    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<bool> deleteAccountPermanently(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/accounts/$id/permanent'), headers: await _getHeaders());
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // --- ENTITIES ---
  Future<List<FinancialEntity>> fetchEntities() async {
    final response = await http.get(Uri.parse('$baseUrl/entities'), headers: await _getHeaders());
    final List<dynamic> jsonList = _processResponse(response);
    return jsonList.map((json) => FinancialEntity.fromJson(json)).toList();
  }

  Future<FinancialEntity?> createEntity(Map<String, dynamic> entityData) async {
    final response = await http.post(Uri.parse('$baseUrl/entities'), headers: await _getHeaders(), body: jsonEncode(entityData));
    return FinancialEntity.fromJson(_processResponse(response));
  }

  Future<bool> deleteEntity(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/entities/$id'), headers: await _getHeaders());
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // --- TRANSACTIONS ---
  Future<List<TransactionItem>> fetchTransactions({String? startDate, String? endDate, String? accountId}) async {
    String url = '$baseUrl/transactions?';
    if (startDate != null) url += 'startDate=$startDate&';
    if (endDate != null) url += 'endDate=$endDate&';
    if (accountId != null) url += 'accountId=$accountId&';
    final response = await http.get(Uri.parse(url), headers: await _getHeaders());
    final body = _processResponse(response);
    final List<dynamic> jsonList = body['content'] ?? []; 
    return jsonList.map((json) => TransactionItem.fromJson(json)).toList();
  }

  Future<TransactionItem?> createTransaction(Map<String, dynamic> transactionData) async {
    final response = await http.post(Uri.parse('$baseUrl/transactions'), headers: await _getHeaders(), body: jsonEncode(transactionData));
    return TransactionItem.fromJson(_processResponse(response));
  }

  Future<TransactionItem?> updateTransaction(int id, Map<String, dynamic> transactionData) async {
    final response = await http.put(Uri.parse('$baseUrl/transactions/$id'), headers: await _getHeaders(), body: jsonEncode(transactionData));
    return TransactionItem.fromJson(_processResponse(response));
  }

  Future<bool> deleteTransaction(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/transactions/$id'), headers: await _getHeaders());
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // --- CATEGORIES ---
  Future<List<Category>> fetchCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'), headers: await _getHeaders());
    final List<dynamic> jsonList = _processResponse(response);
    return jsonList.map((json) => Category.fromJson(json)).toList();
  }

  Future<Category?> createCategory(Category category, {int? parentId}) async {
    final response = await http.post(Uri.parse('$baseUrl/categories'), headers: await _getHeaders(), body: jsonEncode({'name': category.name, 'type': category.type == CategoryType.income ? 'INCOME' : 'EXPENSE', 'parent': parentId != null ? {'id': parentId} : null}));
    return Category.fromJson(_processResponse(response));
  }

  Future<Category?> updateCategory(int id, Category category) async {
    final response = await http.put(Uri.parse('$baseUrl/categories/$id'), headers: await _getHeaders(), body: jsonEncode(category.toJson()));
    return Category.fromJson(_processResponse(response));
  }

  Future<Subcategory?> updateSubcategory(int id, Subcategory subcategory) async {
    final response = await http.put(Uri.parse('$baseUrl/categories/subcategories/$id'), headers: await _getHeaders(), body: jsonEncode(subcategory.toJson()));
    return Subcategory.fromJson(_processResponse(response));
  }

  Future<Subcategory?> createSubcategory(int categoryId, Subcategory subcategory) async {
    final response = await http.post(Uri.parse('$baseUrl/categories/$categoryId/subcategories'), headers: await _getHeaders(), body: jsonEncode(subcategory.toJson()));
    return Subcategory.fromJson(_processResponse(response));
  }

  Future<bool> deleteSubcategory(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/categories/subcategories/$id'), headers: await _getHeaders());
    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<List<TransactionItem>> fetchTransactionsByCategory(int categoryId) async {
    final response = await http.get(Uri.parse('$baseUrl/categories/$categoryId/transactions'), headers: await _getHeaders());
    final List<dynamic> jsonList = _processResponse(response);
    return jsonList.map((json) => TransactionItem.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> deleteCategory(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/categories/$id'), headers: await _getHeaders());
      return {'success': response.statusCode == 200 || response.statusCode == 204};
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }

  // --- STATS ---
  Future<Map<String, double>> fetchCategoryStats({String? startDate, String? endDate, List<int>? accountIds, bool groupBySubcategory = false}) async {
    String url = '$baseUrl/reports/category-stats?';
    if (startDate != null) url += 'startDate=$startDate&';
    if (endDate != null) url += 'endDate=$endDate&';
    if (accountIds != null) url += 'accountIds=${accountIds.join(",")}&';
    if (groupBySubcategory) url += 'groupBySubcategory=true&';
    final response = await http.get(Uri.parse(url), headers: await _getHeaders());
    final Map<String, dynamic> data = _processResponse(response);
    return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  Future<Uint8List?> downloadPdfReport({required String title, required String chartType, String? startDate, String? endDate, List<int>? accountIds, List<int>? categoryIds, String lang = 'en'}) async {
    String url = '$baseUrl/reports/pdf?title=$title&chartType=$chartType&lang=$lang&';
    if (startDate != null) url += 'startDate=$startDate&';
    if (endDate != null) url += 'endDate=$endDate&';
    if (accountIds != null) url += 'accountIds=${accountIds.join(",")}&';
    if (categoryIds != null) url += 'categoryIds=${categoryIds.join(",")}&';
    final response = await http.get(Uri.parse(url), headers: await _getHeaders());
    return response.bodyBytes;
  }
}
