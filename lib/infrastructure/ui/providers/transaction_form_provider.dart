import 'package:flutter/foundation.dart';
import '../../../domain/models/account_item.dart';
import '../../../domain/models/transaction_item.dart';
import '../../../domain/models/category.dart' as cat_model;
import '../../../domain/repositories/transaction_repository.dart';
import '../../../domain/repositories/account_repository.dart';
import '../../../domain/repositories/category_repository.dart';
import '../../../domain/repositories/beneficiary_repository.dart';
import '../../../services/session_service.dart';
import '../../../services/api_service.dart';
import '../../../domain/models/financial_entity.dart';
import '../../../domain/models/beneficiary.dart';

class TransactionFormProvider extends ChangeNotifier {
  final ITransactionRepository _transactionRepo;
  final IAccountRepository _accountRepo;
  final ICategoryRepository _categoryRepo;
  final IBeneficiaryRepository _beneficiaryRepo;
  final SessionService _sessionService;
  final ApiService _apiService;
  final TransactionItem? initialTransaction;
  final AccountItem? initialAccount;

  String _selectedTypeLabel = 'EXPENSE';
  AccountItem? _selectedAccount;
  AccountItem? _selectedToAccount;
  cat_model.Category? _selectedCategory;
  cat_model.Subcategory? _selectedSubcategory;
  Beneficiary? _selectedBeneficiary;
  DateTime _selectedDate = DateTime.now();
  String _amount = '0.00';
  String _description = '';

  List<AccountItem> _accounts = [];
  List<cat_model.Category> _allCategories = [];
  List<FinancialEntity> _entities = [];
  List<Beneficiary> _beneficiaries = [];
  bool _isLoading = true;

  TransactionFormProvider(
    this._transactionRepo,
    this._accountRepo,
    this._categoryRepo,
    this._beneficiaryRepo,
    this._sessionService,
    this._apiService, {
    this.initialTransaction,
    this.initialAccount,
  });

  String get selectedTypeLabel => _selectedTypeLabel;
  AccountItem? get selectedAccount => _selectedAccount;
  AccountItem? get selectedToAccount => _selectedToAccount;
  cat_model.Category? get selectedCategory => _selectedCategory;
  cat_model.Subcategory? get selectedSubcategory => _selectedSubcategory;
  Beneficiary? get selectedBeneficiary => _selectedBeneficiary;
  DateTime get selectedDate => _selectedDate;
  String get amount => _amount;
  String get description => _description;
  List<AccountItem> get accounts => _accounts;
  List<cat_model.Category> get allCategories => _allCategories;
  List<FinancialEntity> get entities => _entities;
  List<Beneficiary> get beneficiaries => _beneficiaries;
  bool get isLoading => _isLoading;

  List<cat_model.Category> get filteredCategories =>
      _allCategories.where((c) => c.type.name.toUpperCase() == _selectedTypeLabel.toUpperCase()).toList();

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _accounts = await _accountRepo.fetchAccounts();
      _allCategories = await _categoryRepo.fetchCategories();
      _beneficiaries = await _beneficiaryRepo.getAllBeneficiaries();
      try {
        _entities = await _apiService.fetchEntities();
      } catch (_) {
        _entities = [];
      }

      if (initialTransaction != null && _accounts.isNotEmpty) {
        _selectedTypeLabel = initialTransaction!.type.name;
        _amount = (initialTransaction!.amount.value / 100).abs().toStringAsFixed(2);
        _description = initialTransaction!.description;
        _selectedDate = DateTime.parse(initialTransaction!.date);
        _selectedAccount = _accounts.firstWhere(
          (a) => a.id == initialTransaction!.account.id,
          orElse: () => _accounts.first,
        );
        _selectedBeneficiary = initialTransaction!.beneficiary;
        _selectedSubcategory = initialTransaction!.subcategory;
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
        
        // CONTEXTO DE CUENTA
        if (initialAccount != null) {
          _selectedAccount = _accounts.cast<AccountItem?>().firstWhere((a) => a?.id == initialAccount!.id, orElse: () => null);
        }
        // Si no hay initialAccount, _selectedAccount se queda en null para obligar a seleccionar.
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
    _selectedSubcategory = null;
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

  void setSelectedCategory(cat_model.Category? category) {
    _selectedCategory = category;
    _selectedSubcategory = null;
    notifyListeners();
  }

  void setSelectedSubcategory(cat_model.Subcategory? sub) {
    _selectedSubcategory = sub;
    notifyListeners();
  }

  Future<void> setSelectedBeneficiary(Beneficiary? beneficiary) async {
    _selectedBeneficiary = beneficiary;
    notifyListeners();

    if (beneficiary != null) {
      try {
        final suggestion = await _beneficiaryRepo.getTransactionSuggestion(beneficiary.id);
        if (suggestion != null) {
          if (suggestion['categoryId'] != null) {
            final catId = suggestion['categoryId'] as int;
            _selectedCategory = _allCategories.firstWhere((c) => c.id == catId);
            
            // AUTORRELLENADO DE SUBCATEGORÍA
            if (suggestion['subcategoryId'] != null && _selectedCategory != null) {
              final subId = suggestion['subcategoryId'] as int;
              try {
                _selectedSubcategory = _selectedCategory!.subcategories.firstWhere((s) => s.id == subId);
              } catch (_) {
                _selectedSubcategory = null;
              }
            }
          }
          if (suggestion['transactionType'] != null) {
            _selectedTypeLabel = suggestion['transactionType'] as String;
          }
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error getting autocomplete suggestion: $e');
      }
    }
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
      final double amountValue = double.tryParse(_amount) ?? 0.0;
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
        subcategory: _selectedSubcategory, // GUARDADO DE SUBCATEGORÍA
        beneficiary: _selectedBeneficiary,
        type: TransactionType.values.firstWhere((e) => e.name == _selectedTypeLabel),
        isScheduled: false,
        isHeader: false,
        tags: [],
      );

      if (initialTransaction != null) {
        await _transactionRepo.updateTransaction(tx);
      } else {
        await _transactionRepo.saveTransaction(tx);
      }

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
