import 'package:flutter/foundation.dart';
import '../../../domain/models/account_item.dart';
import '../../../domain/models/transaction_item.dart';
import '../../../domain/models/category.dart' as cat_model;
import '../../../domain/repositories/transaction_repository.dart';
import '../../../services/session_service.dart';
import '../../../services/api_service.dart';

class TransactionFormProvider extends ChangeNotifier {
  final ITransactionRepository _transactionRepo;
  final SessionService _sessionService;
  final ApiService _apiService;
  final TransactionItem? initialTransaction;

  String _selectedTypeLabel = 'EXPENSE';
  AccountItem? _selectedAccount;
  AccountItem? _selectedToAccount;
  cat_model.Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String _amount = '0.00';
  String _description = '';

  List<AccountItem> _accounts = [];
  List<cat_model.Category> _allCategories = [];
  bool _isLoading = true;

  TransactionFormProvider(
    this._transactionRepo,
    this._sessionService,
    this._apiService, {
    this.initialTransaction,
  });

  String get selectedTypeLabel => _selectedTypeLabel;
  AccountItem? get selectedAccount => _selectedAccount;
  AccountItem? get selectedToAccount => _selectedToAccount;
  cat_model.Category? get selectedCategory => _selectedCategory;
  DateTime get selectedDate => _selectedDate;
  String get amount => _amount;
  String get description => _description;
  List<AccountItem> get accounts => _accounts;
  List<cat_model.Category> get allCategories => _allCategories;
  bool get isLoading => _isLoading;

  List<cat_model.Category> get filteredCategories =>
      _allCategories.where((c) => c.type.name.toUpperCase() == _selectedTypeLabel.toUpperCase()).toList();

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _accounts = await _apiService.fetchAccounts();
      _allCategories = await _apiService.fetchCategories();

      if (initialTransaction != null && _accounts.isNotEmpty) {
        _selectedTypeLabel = initialTransaction!.type.name;
        _amount = (initialTransaction!.amount.value / 100).abs().toStringAsFixed(2);
        _description = initialTransaction!.description;
        _selectedDate = DateTime.parse(initialTransaction!.date);
        _selectedAccount = _accounts.firstWhere(
          (a) => a.id == initialTransaction!.account.id,
          orElse: () => _accounts.first,
        );
        if (initialTransaction!.toAccount != null) {
          _selectedToAccount = _accounts.firstWhere(
            (a) => a.id == initialTransaction!.toAccount!.id,
            orElse: () => _accounts.first,
          );
        }
        if (initialTransaction!.category != null && _allCategories.isNotEmpty) {
          _selectedCategory = _allCategories.firstWhere(
            (c) => c.id == initialTransaction!.category!.id,
            orElse: () => _allCategories.first,
          );
        }
      } else {
        if (_sessionService.lastSelectedDate != null) {
          _selectedDate = _sessionService.lastSelectedDate!;
        }
        if (_accounts.isNotEmpty) {
          _selectedAccount = _accounts.first;
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setTransactionType(String type) {
    _selectedTypeLabel = type;
    _selectedCategory = null;
    notifyListeners();
  }

  void setSelectedAccount(AccountItem account) {
    _selectedAccount = account;
    notifyListeners();
  }

  void setSelectedToAccount(AccountItem? account) {
    _selectedToAccount = account;
    notifyListeners();
  }

  void setSelectedCategory(cat_model.Category category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setAmount(String amount) {
    _amount = amount;
    notifyListeners();
  }

  void setDescription(String description) {
    _description = description;
    notifyListeners();
  }

  Future<bool> saveTransaction() async {
    try {
      double amountValue = double.tryParse(_amount) ?? 0.0;

      final tx = TransactionItem(
        id: initialTransaction?.id ?? 0,
        date: _selectedDate.toIso8601String(),
        description: _description,
        amount: Amount(
          (amountValue * 100).toInt(),
          _selectedAccount!.amount.currency,
          _selectedTypeLabel == 'EXPENSE',
        ),
        account: _selectedAccount!,
        toAccount: _selectedToAccount,
        category: _selectedCategory,
        type: TransactionType.values.firstWhere((e) => e.name == _selectedTypeLabel),
        isScheduled: false,
        isHeader: false,
        tags: [],
      );

      await _transactionRepo.saveTransaction(tx, isSynced: true);
      _sessionService.lastSelectedDate = _selectedDate;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      await _apiService.deleteTransaction(id);
      return true;
    } catch (e) {
      return false;
    }
  }
}
