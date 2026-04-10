import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../domain/models/account_item.dart';
import '../domain/models/transaction_item.dart';
import '../domain/models/category.dart';
import '../domain/models/financial_entity.dart';

class ApiService {
  // IP del servidor Jenkins/API
  static const String _pcIp = '192.168.1.145'; 
  // Puerto configurado en Jenkins para el contenedor
  static const String _port = '8084';
  
  static String get baseUrl {
    if (kIsWeb) {
      // Para web, usamos la IP del servidor en lugar de localhost
      return 'http://$_pcIp:$_port/api';
    }
    return 'http://$_pcIp:$_port/api'; 
  }

  // --- AUTH ---
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/v2/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Login error: $e');
    }
    return null;
  }

  Future<bool> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/v2/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  // --- ACCOUNTS ---
  Future<List<AccountItem>> fetchAccounts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/accounts'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => AccountItem.fromJson(json)).toList();
      }
    } catch (e) {
      print('Exception fetching accounts: $e');
    }
    return []; 
  }

  Future<AccountItem?> createAccount(Map<String, dynamic> accountData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/accounts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(accountData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AccountItem.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Exception creating account: $e');
    }
    return null;
  }

  Future<AccountItem?> updateAccount(int id, Map<String, dynamic> accountData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/accounts/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(accountData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AccountItem.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Exception updating account: $e');
    }
    return null;
  }

  Future<bool> deleteAccount(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/accounts/$id'));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAccountPermanently(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/accounts/$id/permanent'));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // --- ENTITIES ---
  Future<List<FinancialEntity>> fetchEntities() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/entities'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => FinancialEntity.fromJson(json)).toList();
      }
    } catch (e) {
      print('Exception fetching entities: $e');
    }
    return [];
  }

  Future<FinancialEntity?> createEntity(Map<String, dynamic> entityData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/entities'),
        headers: {'Content-Type': 'application/json'},
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
      final response = await http.delete(Uri.parse('$baseUrl/entities/$id'));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // --- TRANSACTIONS ---
  Future<List<TransactionItem>> fetchTransactions({String? startDate, String? endDate, String? accountId}) async {
    try {
      Map<String, String> queryParams = {};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (accountId != null) queryParams['accountId'] = accountId;

      final uri = Uri.parse('$baseUrl/transactions').replace(queryParameters: queryParams);
      
      final response = await http.get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 5));
          
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => TransactionItem.fromJson(json)).toList();
      }
    } catch (e) {
      print('Exception fetching transactions: $e');
    }
    return [];
  }

  Future<TransactionItem?> createTransaction(Map<String, dynamic> transactionData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(transactionData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return TransactionItem.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Exception creating transaction: $e');
    }
    return null;
  }

  Future<TransactionItem?> updateTransaction(int id, Map<String, dynamic> transactionData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/transactions/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(transactionData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return TransactionItem.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Exception updating transaction: $e');
    }
    return null;
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/transactions/$id'));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // --- CATEGORIES ---
  Future<List<Category>> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Category.fromJson(json)).toList();
      }
    } catch (e) {
      print('Exception fetching categories: $e');
    }
    return [];
  }

  Future<Category?> createCategory(Category category, {int? parentId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories'),
        headers: {'Content-Type': 'application/json'},
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
      print('Exception creating category: $e');
    }
    return null;
  }

  Future<Category?> updateCategory(int id, Category category) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/categories/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(category.toJson()),
      );
      return response.statusCode == 200 ? Category.fromJson(jsonDecode(response.body)) : null;
    } catch (e) {
      return null;
    }
  }

  Future<Subcategory?> updateSubcategory(int id, Subcategory subcategory) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/categories/subcategories/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(subcategory.toJson()),
      );
      return response.statusCode == 200 ? Subcategory.fromJson(jsonDecode(response.body)) : null;
    } catch (e) {
      return null;
    }
  }

  Future<Subcategory?> createSubcategory(int categoryId, Subcategory subcategory) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories/$categoryId/subcategories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(subcategory.toJson()),
      );
      return (response.statusCode == 200 || response.statusCode == 201)
          ? Subcategory.fromJson(jsonDecode(response.body))
          : null;
    } catch (e) {
      return null;
    }
  }
}
