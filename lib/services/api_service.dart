import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../domain/models/account_item.dart';
import '../domain/models/transaction_item.dart';
import '../domain/models/category.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    }
    return 'http://10.0.2.2:8080/api'; 
  }

  Future<List<AccountItem>> fetchAccounts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/accounts'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => AccountItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load accounts');
      }
    } catch (e) {
      return []; 
    }
  }

  Future<List<TransactionItem>> fetchTransactions() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/transactions'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => TransactionItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<Category>> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      return [];
    }
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
      return null;
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
      return null;
    }
    return null;
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
      return null;
    }
    return null;
  }
}