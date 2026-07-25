import 'package:flutter/foundation.dart';
import 'package:natave_flutter/domain/models/account_item.dart';
import 'package:natave_flutter/domain/models/transaction_item.dart';
import 'package:natave_flutter/domain/models/transaction_filters.dart';
import 'package:natave_flutter/domain/repositories/transaction_repository.dart';
import 'package:natave_flutter/domain/repositories/account_repository.dart';
import 'package:natave_flutter/services/api_service.dart';
import 'package:natave_flutter/service_locator.dart';

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
          
          _cachedTransactions = await getIt<ITransactionRepository>(instanceName: 'local_transaction').fetchTransactions(
            TransactionFilters(
              startDate: _startDate.toIso8601String(),
              endDate: _endDate.toIso8601String(),
            )
          );
          _recomputeCategories();
          
          _isLoading = false;
          notifyListeners();
        }
      }
      await refreshDashboard();
    } catch (e) {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Refresco rápido de saldos (Útil tras añadir/borrar una transacción)
  Future<void> refreshBalances() async {
    try {
      // 1. Saldo de cuentas: lo pedimos SIEMPRE al servidor (no al caché
      // local vía IAccountRepository/CachedAccountRepository, que devuelve
      // la copia local al instante y solo reconcilia en segundo plano). El
      // saldo lo calcula y guarda el servidor, nada lo actualiza en local
      // tras borrar/crear una transacción, así que leer solo de SQLite aquí
      // dejaba el Balance Summary con el valor anterior hasta la próxima
      // vez que se abriera el Dashboard.
      final remoteAccounts = await getIt<ApiService>().fetchAccounts();
      if (remoteAccounts.isNotEmpty) {
        _accounts = remoteAccounts;
        if (!kIsWeb) await _accountRepo.reconcile(remoteAccounts);
      }
    } catch (_) {}

    try {
      // 2. Refrescamos transacciones del periodo para el gráfico
      _cachedTransactions = await _transactionRepo.fetchTransactions(
        TransactionFilters(
          startDate: _startDate.toIso8601String(),
          endDate: _endDate.toIso8601String(),
        )
      );
      _recomputeCategories();
    } catch (_) {}

    notifyListeners(); // Notificamos a la UI del Dashboard
  }

  Future<void> refreshDashboard() async {
    if (_accounts.isEmpty) {
      _isLoading = true;
    } else {
      _isRefreshing = true;
    }
    notifyListeners();

    try {
      // Igual que en refreshBalances(): pedimos el saldo real al servidor en
      // vez de usar _accountRepo.fetchAccounts() (CachedAccountRepository),
      // que devuelve la copia local al instante y solo reconcilia en
      // segundo plano — mostraría el saldo anterior al recién llegar al
      // Dashboard si esa reconciliación aún no había terminado.
      final remoteAccounts = await getIt<ApiService>().fetchAccounts();
      if (remoteAccounts.isNotEmpty) {
        _accounts = remoteAccounts;
        if (!kIsWeb) await _accountRepo.reconcile(remoteAccounts);
        if (_selectedAccountIds.isEmpty) {
          _selectedAccountIds = _accounts.map((a) => a.id).toList();
        }
      }

      _cachedTransactions = await _transactionRepo.fetchTransactions(
        TransactionFilters(
          startDate: _startDate.toIso8601String(),
          endDate: _endDate.toIso8601String(),
        )
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
