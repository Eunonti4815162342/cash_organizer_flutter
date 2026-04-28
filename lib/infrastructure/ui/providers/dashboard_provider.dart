import 'package:flutter/foundation.dart';
import '../../../domain/models/account_item.dart';
import '../../../domain/models/transaction_item.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../../../domain/repositories/account_repository.dart';
import '../../../service_locator.dart';

class DashboardProvider extends ChangeNotifier {
  final ITransactionRepository _transactionRepo;
  final IAccountRepository _accountRepo;

  List<AccountItem> _accounts = [];
  List<TransactionItem> _cachedTransactions = [];
  List<int> _selectedAccountIds = [];
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);
  String _categoryMode = 'EXPENSE';
  Map<String, double> _categoryData = {};
  double _totalCategoryAmount = 0;
  bool _isLoading = false;
  bool _isRefreshing = false;
  int _touchedIndex = -1;

  DashboardProvider(this._transactionRepo, this._accountRepo);

  List<AccountItem> get accounts => _accounts;
  List<int> get selectedAccountIds => _selectedAccountIds;
  bool get allAccountsSelected => _selectedAccountIds.length == _accounts.length;
  List<AccountItem> get selectedAccounts => _accounts.where((a) => _selectedAccountIds.contains(a.id)).toList();
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  String get categoryMode => _categoryMode;
  Map<String, double> get categoryData => _categoryData;
  double get totalCategoryAmount => _totalCategoryAmount;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  int get touchedIndex => _touchedIndex;

  Future<void> loadInitialData() async {
    // 1. CARGA LOCAL INSTANTÁNEA (Solo mostramos loader si no hay nada en memoria)
    if (_accounts.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      if (!kIsWeb) {
        final localAccounts = await getIt<IAccountRepository>(instanceName: 'local_account').fetchAccounts();
        if (localAccounts.isNotEmpty) {
          _accounts = localAccounts;
          _selectedAccountIds = _accounts.map((a) => a.id).toList();
          
          // Carga inicial de transacciones locales para pintar el dashboard YA
          _cachedTransactions = await getIt<ITransactionRepository>(instanceName: 'local_transaction').fetchTransactions(
            startDate: _startDate.toIso8601String(),
            endDate: _endDate.toIso8601String(),
          );
          _recomputeCategories();
          
          _isLoading = false;
          notifyListeners(); // ¡La UI ya tiene datos locales!
        }
      }

      // 2. REFRESCO REMOTO (En paralelo/segundo plano)
      await refreshDashboard();
    } catch (e) {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboard() async {
    // Si ya tenemos datos, no mostramos el loader principal (evita el parpadeo blanco)
    if (_accounts.isEmpty) {
      _isLoading = true;
    } else {
      _isRefreshing = true;
    }
    notifyListeners();

    try {
      // Intentamos obtener cuentas de red
      final remoteAccounts = await _accountRepo.fetchAccounts();
      if (remoteAccounts.isNotEmpty) {
        _accounts = remoteAccounts;
        if (_selectedAccountIds.isEmpty) {
          _selectedAccountIds = _accounts.map((a) => a.id).toList();
        }
      }

      // Intentamos obtener transacciones de red (vía CachedRepository que gestiona el fallback)
      _cachedTransactions = await _transactionRepo.fetchTransactions(
        startDate: _startDate.toIso8601String(),
        endDate: _endDate.toIso8601String(),
      );
      
      _recomputeCategories();
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  void _recomputeCategories() {
    final catTotals = <String, double>{};
    double sum = 0;
    for (final tx in _cachedTransactions) {
      if (!_selectedAccountIds.contains(tx.account.id)) continue;
      if (tx.type.name == _categoryMode) {
        final catName = tx.category?.name ?? 'General';
        final val = (tx.amount.value / 100).abs();
        catTotals[catName] = (catTotals[catName] ?? 0) + val;
        sum += val;
      }
    }
    _categoryData = catTotals;
    _totalCategoryAmount = sum;
  }

  void setSelectedAccounts(List<int> ids) {
    _selectedAccountIds = ids;
    _touchedIndex = -1;
    _recomputeCategories();
    notifyListeners();
  }

  void setCategoryMode(String mode) {
    _categoryMode = mode;
    _touchedIndex = -1;
    _recomputeCategories();
    notifyListeners();
  }

  Future<void> setDateRange(DateTime start, DateTime end) async {
    _startDate = start;
    _endDate = end;
    await refreshDashboard();
  }

  void setTouchedIndex(int index) {
    _touchedIndex = index;
    notifyListeners();
  }
}
