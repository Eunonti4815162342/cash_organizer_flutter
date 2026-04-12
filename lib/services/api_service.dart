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
  
  // CONFIGURACIÓN DE PRODUCCIÓN (Cloudflare Tunnel)
  static const String _prodUrl = 'api.eunonti.com'; 
  
  // CONFIGURACIÓN LOCAL (Tu PC)
  static const String _localIp = '192.168.1.192'; 
  static const String _localPort = '8085'; 
  
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://$_prodUrl/api'; // Producción siempre por HTTPS vía Cloudflare
    } else {
      if (kIsWeb) {
        return 'http://localhost:$_localPort/api';
      } else {
        return 'http://$_localIp:$_localPort/api';
      }
    }
  }

  Future<bool> isOnline() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/v2/auth/login')).timeout(const Duration(seconds: 3));
      // Si responde (incluso con error de auth 405/400), el servidor está vivo.
      return response.statusCode != 0;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- AUTH ---
  Future<Map<String, dynamic>?> login(String email, String password, {bool rememberMe = false}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/v2/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email, 
          'password': password,
          'rememberMe': rememberMe
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('[ApiService] Login Exception: $e');
    }
    return null;
  }

  Future<void> logout() async {
    print('[ApiService] Logging out, clearing token...');
    await _storage.delete(key: 'jwt_token');
  }

  Future<bool> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/v2/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('[ApiService] Register Exception: $e');
      return false;
    }
  }

  // --- ACCOUNTS ---
  Future<List<AccountItem>> fetchAccounts() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/accounts'), headers: headers)
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => AccountItem.fromJson(json)).toList();
      }
    } catch (e) {
      print('[ApiService] Fetch Accounts Exception: $e');
    }
    return []; 
  }

  Future<AccountItem?> createAccount(Map<String, dynamic> accountData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/accounts'),
        headers: headers,
        body: jsonEncode(accountData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AccountItem.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('[ApiService] Create Account Exception: $e');
    }
    return null;
  }

  Future<AccountItem?> updateAccount(int id, Map<String, dynamic> accountData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/accounts/$id'),
        headers: headers,
        body: jsonEncode(accountData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AccountItem.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('[ApiService] Update Account Exception: $e');
    }
    return null;
  }

  Future<bool> deleteAccount(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(Uri.parse('$baseUrl/accounts/$id'), headers: headers);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAccountPermanently(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(Uri.parse('$baseUrl/accounts/$id/permanent'), headers: headers);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // --- ENTITIES ---
  Future<List<FinancialEntity>> fetchEntities() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/entities'), headers: headers)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => FinancialEntity.fromJson(json)).toList();
      }
    } catch (e) {
      print('[ApiService] Fetch Entities Exception: $e');
    }
    return [];
  }

  Future<FinancialEntity?> createEntity(Map<String, dynamic> entityData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/entities'),
        headers: headers,
        body: jsonEncode(entityData),
      );
      return (response.statusCode == 200 || response.statusCode == 201)
          ? FinancialEntity.fromJson(jsonDecode(response.body))
          : null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteEntity(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(Uri.parse('$baseUrl/entities/$id'), headers: headers);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // --- TRANSACTIONS ---
  Future<List<TransactionItem>> fetchTransactions({String? startDate, String? endDate, String? accountId}) async {
    try {
      final headers = await _getHeaders();
      Map<String, String> queryParams = {};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (accountId != null) queryParams['accountId'] = accountId;

      final uri = Uri.parse('$baseUrl/transactions').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
          
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> jsonList = body['content']; // Extraer contenido de la página
        return jsonList.map((json) => TransactionItem.fromJson(json)).toList();
      }
    } catch (e) {
      print('[ApiService] Fetch Transactions Exception: $e');
    }
    return [];
  }

  Future<TransactionItem?> createTransaction(Map<String, dynamic> transactionData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: headers,
        body: jsonEncode(transactionData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return TransactionItem.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('[ApiService] Create Transaction Exception: $e');
    }
    return null;
  }

  Future<TransactionItem?> updateTransaction(int id, Map<String, dynamic> transactionData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/transactions/$id'),
        headers: headers,
        body: jsonEncode(transactionData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return TransactionItem.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('[ApiService] Update Transaction Exception: $e');
    }
    return null;
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(Uri.parse('$baseUrl/transactions/$id'), headers: headers);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // --- CATEGORIES ---
  Future<List<Category>> fetchCategories() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/categories'), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Category.fromJson(json)).toList();
      }
    } catch (e) {
      print('[ApiService] Fetch Categories Exception: $e');
    }
    return [];
  }

  Future<Category?> createCategory(Category category, {int? parentId}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/categories'),
        headers: headers,
        body: jsonEncode({
          'name': category.name,
          'type': category.type == CategoryType.income ? 'INCOME' : 'EXPENSE',
          'parent': parentId != null ? {'id': parentId} : null,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Category.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('[ApiService] Create Category Exception: $e');
    }
    return null;
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
      
      final Map<String, String> queryParams = {
        'title': title,
        'chartType': chartType,
      };
      
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (accountIds != null && accountIds.isNotEmpty) queryParams['accountIds'] = accountIds.join(',');
      if (categoryIds != null && categoryIds.isNotEmpty) queryParams['categoryIds'] = categoryIds.join(',');

      final uri = Uri.parse('$baseUrl/reports/pdf').replace(queryParameters: queryParams);
      
      print('[ApiService] Downloading PDF from: $uri');
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      print('[ApiService] PDF Download Exception: $e');
    }
    return null;
  }

  Future<Category?> updateCategory(int id, Category category) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/categories/$id'),
        headers: headers,
        body: jsonEncode(category.toJson()),
      );
      return response.statusCode == 200 ? Category.fromJson(jsonDecode(response.body)) : null;
    } catch (e) {
      return null;
    }
  }

  Future<Subcategory?> updateSubcategory(int id, Subcategory subcategory) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/categories/subcategories/$id'),
        headers: headers,
        body: jsonEncode(subcategory.toJson()),
      );
      return response.statusCode == 200 ? Subcategory.fromJson(jsonDecode(response.body)) : null;
    } catch (e) {
      return null;
    }
  }

  Future<Subcategory?> createSubcategory(int categoryId, Subcategory subcategory) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/categories/$categoryId/subcategories'),
        headers: headers,
        body: jsonEncode(subcategory.toJson()),
      );
      return (response.statusCode == 200 || response.statusCode == 201)
          ? Subcategory.fromJson(jsonDecode(response.body))
          : null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, double>> fetchCategoryStats({
    String? startDate,
    String? endDate,
    List<int>? accountIds,
    bool groupBySubcategory = false,
  }) async {
    try {
      final headers = await _getHeaders();
      final Map<String, String> queryParams = {};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (accountIds != null && accountIds.isNotEmpty) queryParams['accountIds'] = accountIds.join(',');
      if (groupBySubcategory) queryParams['groupBySubcategory'] = 'true';

      final uri = Uri.parse('$baseUrl/reports/category-stats').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
      }
    } catch (e) {
      print('[ApiService] Fetch Category Stats Exception: $e');
    }
    return {};
  }
}
