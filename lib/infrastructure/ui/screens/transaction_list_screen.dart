import 'package:flutter/material.dart';
import '../../../domain/models/transaction_item.dart';
import '../../../domain/models/account_item.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../../../domain/repositories/account_repository.dart';
import '../../../infrastructure/repositories/cached_transaction_repository.dart';
import '../../../infrastructure/repositories/cached_account_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/ui_helpers.dart';
import '../widgets/skeleton_widgets.dart';
import 'transaction_form_screen.dart';
import '../styles/app_styles.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final ITransactionRepository _transactionRepo = CachedTransactionRepository();
  final IAccountRepository _accountRepo = CachedAccountRepository();
  
  late Future<List<TransactionItem>> _transactionsFuture;
  DateTime _currentMonth = DateTime.now();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  List<AccountItem> _accounts = [];
  List<int> _selectedAccountIds = [];
  bool _accountsLoaded = false;

  @override
  void initState() {
    super.initState();
    _transactionsFuture = Future.value([]); // Estado inicial vacío
    _initData();
  }

  Future<void> _initData() async {
    await _loadAccounts();
    _refreshTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    final accs = await _accountRepo.fetchAccounts();
    if (mounted) {
      setState(() {
        _accounts = accs;
        // CRÍTICO: Si no hay nada seleccionado (inicio), seleccionamos TODO por defecto
        if (_selectedAccountIds.isEmpty) {
          _selectedAccountIds = accs.map((a) => a.id).toList();
        }
        _accountsLoaded = true;
      });
    }
  }

  void _refreshTransactions() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0, 23, 59, 59);
    
    setState(() {
      _transactionsFuture = _transactionRepo.fetchTransactions(
        startDate: firstDay.toIso8601String(),
        endDate: lastDay.toIso8601String(),
        // Si no hay cuentas, pasamos null para que el repositorio intente traer lo que sea
        accountId: (_selectedAccountIds.isEmpty && !_accountsLoaded) 
            ? null 
            : (_selectedAccountIds.isEmpty ? "-1" : _selectedAccountIds.join(',')),
      );
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta);
    });
    _refreshTransactions();
  }

  Future<void> _selectMonth(AppLocalizations l10n) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'SELECT MONTH',
    );
    if (picked != null && picked != _currentMonth) {
      setState(() {
        _currentMonth = DateTime(picked.year, picked.month, 1);
      });
      _refreshTransactions();
    }
  }

  void _showFilterDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.filterByAccounts, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: Text(l10n.allAccounts, style: const TextStyle(fontWeight: FontWeight.bold)),
                  value: _selectedAccountIds.length == _accounts.length,
                  onChanged: (val) {
                    setDialogState(() {
                      if (val == true) {
                        _selectedAccountIds = _accounts.map((a) => a.id).toList();
                      } else {
                        _selectedAccountIds = [];
                      }
                    });
                  },
                ),
                const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _accounts.length,
                    itemBuilder: (context, index) {
                      final acc = _accounts[index];
                      return CheckboxListTile(
                        title: Text(acc.name),
                        value: _selectedAccountIds.contains(acc.id),
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              _selectedAccountIds.add(acc.id);
                            } else {
                              _selectedAccountIds.remove(acc.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel.toUpperCase())),
            ElevatedButton(
              onPressed: () {
                _refreshTransactions();
                Navigator.pop(context);
              },
              child: Text(l10n.save.toUpperCase()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final monthName = _getMonthName(_currentMonth.month, l10n);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Column(
          children: [
            Container(
              height: 50, color: Colors.white,
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(icon: const Icon(Icons.chevron_left, size: 20), onPressed: () => _changeMonth(-1)),
                        InkWell(
                          onTap: () => _selectMonth(l10n),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Text('$monthName ${_currentMonth.year}'.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryBlue)),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.primaryBlue),
                              ],
                            ),
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.chevron_right, size: 20), onPressed: () => _changeMonth(1)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.filter_list, color: _selectedAccountIds.isEmpty || _selectedAccountIds.length == _accounts.length ? Colors.grey : AppColors.primaryBlue),
                    onPressed: () => _showFilterDialog(l10n),
                    tooltip: l10n.filterByAccounts,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            Container(
              height: 50, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: const Color(0xFFF5F5F5),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: l10n.search,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) : null,
                  filled: true, fillColor: Colors.white, contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<TransactionItem>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SkeletonTransactionList();
          }
          if (snapshot.hasError) {
            return ErrorStateWidget(message: 'Comprueba tu conexión', onRetry: _refreshTransactions);
          }
          final allTransactions = snapshot.data ?? [];
          final filteredTransactions = allTransactions.where((tx) {
            final desc = tx.description.toLowerCase();
            final cat = (tx.category?.name ?? 'General').toLowerCase();
            return desc.contains(_searchQuery) || cat.contains(_searchQuery);
          }).toList();

          if (filteredTransactions.isEmpty) {
            return _searchQuery.isNotEmpty
                ? EmptyStateWidget(icon: Icons.search_off_rounded, title: 'Sin resultados', subtitle: 'No hay transacciones para "$_searchQuery"')
                : EmptyStateWidget(
                    icon: Icons.receipt_long_outlined,
                    title: l10n.noData,
                    subtitle: 'Aún no hay transacciones este mes',
                    actionLabel: 'Nueva transacción',
                    onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TransactionFormScreen())).then((saved) { if (saved == true) _refreshTransactions(); }),
                  );
          }

          return ListView.builder(
            itemCount: filteredTransactions.length,
            itemBuilder: (context, index) => TransactionListItem(transaction: filteredTransactions[index], onRefresh: _refreshTransactions),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TransactionFormScreen())).then((saved) { if (saved == true) _refreshTransactions(); });
        },
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _getMonthName(int month, AppLocalizations l10n) {
    const names = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'];
    return names[month - 1];
  }
}
