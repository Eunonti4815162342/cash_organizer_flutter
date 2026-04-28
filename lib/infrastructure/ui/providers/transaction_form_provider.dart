import 'package:flutter/foundation.dart';
import '../../../domain/models/account_item.dart';
import '../../../domain/models/transaction_item.dart';
import '../../../domain/models/category.dart' as cat_model;
import '../../../domain/repositories/transaction_repository.dart';
import '../../../domain/repositories/account_repository.dart';
import '../../../domain/repositories/category_repository.dart';
import '../../../domain/repositories/entity_repository.dart';
import '../../../domain/repositories/beneficiary_repository.dart';
import '../../../services/session_service.dart';
import '../../../domain/models/financial_entity.dart';
import '../../../domain/models/beneficiary.dart';

class TransactionFormProvider extends ChangeNotifier {
  final ITransactionRepository _transactionRepo;
  final IAccountRepository _accountRepo;
  final ICategoryRepository _categoryRepo;
  final IEntityRepository _entityRepo;
  final IBeneficiaryRepository _beneficiaryRepo;
  final SessionService _sessionService;
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
    this._entityRepo,
    this._beneficiaryRepo,
    this._sessionService, {
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
      final results = await Future.wait([
        _accountRepo.fetchAccounts().catchError((_) => <AccountItem>[]),
        _categoryRepo.fetchCategories().catchError((_) => <cat_model.Category>[]),
        _beneficiaryRepo.getAllBeneficiaries().catchError((_) => <Beneficiary>[]),
        _entityRepo.fetchEntities().catchError((_) => <FinancialEntity>[]),
      ]);

      _accounts = results[0] as List<AccountItem>;
      _allCategories = results[1] as List<cat_model.Category>;
      _beneficiaries = results[2] as List<Beneficiary>;
      _entities = results[3] as List<FinancialEntity>;

      if (initialTransaction != null && _accounts.isNotEmpty) {
        _selectedTypeLabel = initialTransaction!.type.name;
        _amount = (initialTransaction!.amount.value / 100).abs().toStringAsFixed(2);
        _description = initialTransaction!.description;
        _selectedDate = DateTime.parse(initialTransaction!.date);
        _selectedAccount = _accounts.where((a) => a.id == initialTransaction!.account.id).firstOrNull ?? _accounts.first;
        _selectedBeneficiary = initialTransaction!.beneficiary;
        _selectedSubcategory = initialTransaction!.subcategory;
        if (initialTransaction!.toAccount != null) {
          _selectedToAccount = _accounts.where((a) => a.id == initialTransaction!.toAccount!.id).firstOrNull;
        }
        if (initialTransaction!.category != null && _allCategories.isNotEmpty) {
          _selectedCategory = _allCategories.where((c) => c.id == initialTransaction!.category!.id).firstOrNull;
        }
      } else {
        if (_sessionService.lastSelectedDate != null) {
          _selectedDate = _sessionService.lastSelectedDate!;
        }
        if (initialAccount != null) {
          _selectedAccount = _accounts.where((a) => a.id == initialAccount!.id).firstOrNull;
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading transaction form data: $e');
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

  void setSelectedAccount(AccountItem? account) {
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
            _selectedCategory = _allCategories.where((c) => c.id == catId).firstOrNull;
            
            if (suggestion['subcategoryId'] != null && _selectedCategory != null) {
              final subId = suggestion['subcategoryId'] as int;
              _selectedSubcategory = _selectedCategory!.subcategories.where((s) => s.id == subId).firstOrNull;
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
      final double amountValue = double.tryParse(_amount.replaceAll(',', '.')) ?? 0.0;
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
        subcategory: _selectedSubcategory,
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

      // APRENDIZAJE OFFLINE: Actualizamos la memoria del beneficiario
      if (_selectedBeneficiary != null) {
        await _beneficiaryRepo.updateBeneficiaryMemory(
          _selectedBeneficiary!.id,
          _selectedCategory?.id,
          _selectedSubcategory?.id,
          _selectedTypeLabel,
        );
      }

      _sessionService.lastSelectedDate = _selectedDate;
      return true;
    } catch (e) {
      debugPrint('Error saving transaction: $e');
      return false;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      await _transactionRepo.deleteTransaction(id);
      return true;
    } catch (e) {
      return false;
    }
  }
}
