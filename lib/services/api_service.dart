import 'dart:typed_data';
import '../domain/models/account_item.dart';
import '../domain/models/transaction_item.dart';
import '../domain/models/category.dart';
import '../domain/models/financial_entity.dart';
import '../domain/models/beneficiary.dart';
import 'api/api_client.dart';
import 'api/auth_api.dart';
import 'api/account_api.dart';
import 'api/transaction_api.dart';
import 'api/category_api.dart';
import 'api/entity_api.dart';
import 'api/report_api.dart';
import 'api/beneficiary_api.dart';

/// Thin facade over the split Api classes. Preserves the legacy API surface
/// used by 13 callers while delegating each concern to its dedicated client.
class ApiService {
  final ApiClient _client = ApiClient();
  late final AuthApi _auth = AuthApi(_client);
  late final AccountApi _accounts = AccountApi(_client);
  late final TransactionApi _transactions = TransactionApi(_client);
  late final CategoryApi _categories = CategoryApi(_client);
  late final EntityApi _entities = EntityApi(_client);
  late final ReportApi _reports = ReportApi(_client);
  late final BeneficiaryApi _beneficiaries = BeneficiaryApi(_client);

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
  Future<List<TransactionItem>> fetchTransactions({String? startDate, String? endDate, String? accountId}) =>
      _transactions.fetch(startDate: startDate, endDate: endDate, accountId: accountId);
  Future<TransactionItem?> createTransaction(Map<String, dynamic> data) => _transactions.create(data);
  Future<TransactionItem?> updateTransaction(int id, Map<String, dynamic> data) => _transactions.update(id, data);
  Future<bool> deleteTransaction(int id) => _transactions.delete(id);

  // --- BENEFICIARIES ---
  Future<List<Beneficiary>> fetchBeneficiaries() => _beneficiaries.fetchAll();
  Future<TransactionItem?> getTransactionSuggestion(int beneficiaryId) =>
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

  // --- REPORTS ---
  Future<Map<String, double>> fetchCategoryStats({
    String? startDate,
    String? endDate,
    List<int>? accountIds,
    bool groupBySubcategory = false,
  }) =>
      _reports.fetchCategoryStats(
        startDate: startDate,
        endDate: endDate,
        accountIds: accountIds,
        groupBySubcategory: groupBySubcategory,
      );

  Future<Uint8List?> downloadPdfReport({
    required String title,
    required String chartType,
    String? startDate,
    String? endDate,
    List<int>? accountIds,
    List<int>? categoryIds,
    String lang = 'en',
  }) =>
      _reports.downloadPdf(
        title: title,
        chartType: chartType,
        startDate: startDate,
        endDate: endDate,
        accountIds: accountIds,
        categoryIds: categoryIds,
        lang: lang,
      );
}
