import 'dart:typed_data';
import '../domain/models/account_item.dart';
import '../domain/models/transaction_item.dart';
import '../domain/models/category.dart';
import '../domain/models/financial_entity.dart';
import '../domain/models/beneficiary.dart';
import 'package:natave_flutter/domain/models/transaction_filters.dart';
import 'package:natave_flutter/services/api/api_client.dart';
import 'package:natave_flutter/services/api/auth_api.dart';
import 'package:natave_flutter/services/api/account_api.dart';
import 'package:natave_flutter/services/api/transaction_api.dart';
import 'package:natave_flutter/services/api/category_api.dart';
import 'package:natave_flutter/services/api/entity_api.dart';
import 'package:natave_flutter/services/api/beneficiary_api.dart';

class ApiService {
  final ApiClient client = ApiClient();

  ApiClient get apiClient => client;

  late final AuthApi _auth = AuthApi(client);
  late final AccountApi _accounts = AccountApi(client);
  late final TransactionApi _transactions = TransactionApi(client);
  late final CategoryApi _categories = CategoryApi(client);
  late final EntityApi _entities = EntityApi(client);
  late final BeneficiaryApi _beneficiaries = BeneficiaryApi(client);

  static String get baseUrl => ApiClient().baseUrl;

  Future<bool> isOnline() => _auth.isOnline();

  // --- AUTH ---
  Future<Map<String, dynamic>?> login(String email, String password, {bool rememberMe = false}) =>
      _auth.login(email, password, rememberMe: rememberMe);
  Future<bool> register(String email, String password) => _auth.register(email, password);
  Future<bool> forgotPassword(String email) => _auth.forgotPassword(email);
  Future<bool> resetPassword(String token, String newPassword) => _auth.resetPassword(token, newPassword);
  Future<void> logout() => _auth.logout();

  // --- ACCOUNTS ---
  Future<List<AccountItem>> fetchAccounts() => _accounts.fetchAll();
  Future<AccountItem?> createAccount(Map<String, dynamic> data) => _accounts.create(data);
  Future<AccountItem?> updateAccount(int id, Map<String, dynamic> data) => _accounts.update(id, data);
  Future<bool> deleteAccount(int id) => _accounts.delete(id);
  Future<bool> deleteAccountPermanently(int id) => _accounts.deletePermanently(id);

  // --- ENTITIES ---
  Future<List<FinancialEntity>> fetchEntities() => _entities.fetchAll();
  Future<FinancialEntity?> createEntity(Map<String, dynamic> data) => _entities.create(data);
  Future<bool> deleteEntity(int id) => _entities.delete(id);

  // --- TRANSACTIONS ---
  Future<List<TransactionItem>> fetchTransactions(TransactionFilters filters) => _transactions.fetch(filters);
  Future<int> fetchTotalTransactions(TransactionFilters filters) => _transactions.fetchTotal(filters);
  Future<TransactionItem?> createTransaction(Map<String, dynamic> data) => _transactions.create(data);
  Future<TransactionItem?> updateTransaction(int id, Map<String, dynamic> data) => _transactions.update(id, data);
  Future<bool> deleteTransaction(int id) => _transactions.delete(id);

  // --- BENEFICIARIES ---
  Future<List<Beneficiary>> fetchBeneficiaries() => _beneficiaries.fetchAll();
  Future<Beneficiary?> createBeneficiary(Beneficiary beneficiary) => _beneficiaries.create(beneficiary);
  Future<Map<String, dynamic>?> getTransactionSuggestion(int beneficiaryId) =>
      _beneficiaries.getTransactionSuggestion(beneficiaryId);

  // --- CATEGORIES ---
  Future<List<Category>> fetchCategories() => _categories.fetchAll();
  Future<Category?> createCategory(Category category, {int? parentId}) =>
      _categories.create(category, parentId: parentId);
  Future<Category?> updateCategory(int id, Category category) => _categories.update(id, category);
  Future<Subcategory?> updateSubcategory(int id, Subcategory sub) => _categories.updateSubcategory(id, sub);
  Future<Subcategory?> createSubcategory(int categoryId, Subcategory sub) =>
      _categories.createSubcategory(categoryId, sub);
  Future<bool> deleteSubcategory(int id) => _categories.deleteSubcategory(id);
  Future<List<TransactionItem>> fetchTransactionsByCategory(int categoryId) =>
      _categories.fetchTransactionsByCategory(categoryId);
  Future<Map<String, dynamic>> deleteCategory(int id) => _categories.delete(id);
}
