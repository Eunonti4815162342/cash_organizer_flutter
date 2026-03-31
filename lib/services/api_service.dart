import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../domain/models/account_item.dart';
import '../domain/models/transaction_item.dart';
import '../domain/models/category.dart';
import '../domain/models/financial_entity.dart';

class ApiService {
  // Cambia esta IP por la IP de tu ordenador si pruebas en un dispositivo físico
  static const String _defaultIp = 'localhost'; 
  
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://$_defaultIp:8080/api';
    }
    // Para el emulador de Android, 10.0.2.2 apunta al localhost de la máquina host
    return 'http://10.0.2.2:8080/api'; 
  }

  // --- ACCOUNTS ---
  Future<List<AccountItem>> fetchAccounts() async {
    try {
      print('Fetching accounts from $baseUrl/accounts');
      final response = await http.get(Uri.parse('$baseUrl/accounts'))
          .timeout(const Duration(seconds: 5));
      
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
      final response = await http.delete(
        Uri.parse('$baseUrl/accounts/$id'),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Exception deleting account: $e');
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
      if (response.statusCode == 200 || response.statusCode == 201) {
        return FinancialEntity.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Exception creating entity: $e');
    }
    return null;
  }

  // --- TRANSACTIONS ---
  Future<List<TransactionItem>> fetchTransactions() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/transactions'))
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
      final response = await http.delete(
        Uri.parse('$baseUrl/transactions/$id'),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Exception deleting transaction: $e');
      return false;
    }
  }

  // --- CATEGORIES ---
  Future<List<Category>> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'))
          .timeout(const Duration(seconds: 5));
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

  Future<Subcategory?> createSubcategory(int categoryId, Subcategory subcategory) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories/$categoryId/subcategories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(subcategory.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Subcategory.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Exception creating subcategory: $e');
    }
    return null;
  }
}
