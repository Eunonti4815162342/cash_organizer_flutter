import 'package:flutter/foundation.dart';
import '../../../domain/models/account_item.dart';
import '../../../domain/models/transaction_item.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../../../domain/repositories/account_repository.dart';

class DashboardProvider extends ChangeNotifier {
  final ITransactionRepository _transactionRepo;
  final IAccountRepository _accountRepo;

  List<AccountItem> _accounts = [];
  AccountItem? _selectedAccount;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);
  String _categoryMode = 'EXPENSE';
  Map<String, double> _categoryData = {};
  double _totalCategoryAmount = 0;
  bool _isLoading = true;
  int _touchedIndex = -1;

  DashboardProvider(this._transactionRepo, this._accountRepo);

  List<AccountItem> get accounts => _accounts;
  AccountItem? get selectedAccount => _selectedAccount;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  String get categoryMode => _categoryMode;
  Map<String, double> get categoryData => _categoryData;
  double get totalCategoryAmount => _totalCategoryAmount;
  bool get isLoading => _isLoading;
  int get touchedIndex => _touchedIndex;

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _accounts = await _transactionRepo.fetchAllAccounts();
      await refreshDashboard();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final txs = await _transactionRepo.fetchTransactions(
        startDate: _startDate.toIso8601String(),
        endDate: _endDate.toIso8601String(),
      );

      Map<String, double> catTotals = {};
      double sum = 0;

      for (var tx in txs) {
        if (tx.account == null) continue;
        if (_selectedAccount != null && tx.account?.id != _selectedAccount!.id) continue;

        if (tx.type.name == _categoryMode) {
          String catName = tx.category?.name ?? 'General';
          double val = ((tx.amount?.value ?? 0) / 100).abs();
          catTotals[catName] = (catTotals[catName] ?? 0) + val;
          sum += val;
        }
      }

      _categoryData = catTotals;
      _totalCategoryAmount = sum;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectAccount(AccountItem? account) {
    _selectedAccount = account;
    refreshDashboard();
  }

  Future<void> setDateRange(DateTime start, DateTime end) async {
    _startDate = start;
    _endDate = end;
    await refreshDashboard();
  }

  Future<void> setCategoryMode(String mode) async {
    _categoryMode = mode;
    await refreshDashboard();
  }

  void setTouchedIndex(int index) {
    _touchedIndex = index;
    notifyListeners();
  }
}
