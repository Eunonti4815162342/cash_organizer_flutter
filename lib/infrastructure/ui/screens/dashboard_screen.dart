import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../styles/app_styles.dart';
import '../../../services/api_service.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../../../domain/repositories/account_repository.dart';
import '../../../infrastructure/repositories/cached_transaction_repository.dart';
import '../../../infrastructure/repositories/cached_account_repository.dart';
import '../../../domain/models/transaction_item.dart';
import '../../../domain/models/account_item.dart';
import '../../../domain/models/category.dart';
import '../../../l10n/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ITransactionRepository _transactionRepo = CachedTransactionRepository();
  final IAccountRepository _accountRepo = CachedAccountRepository();
  final ApiService _apiService = ApiService();
  
  List<AccountItem> _accounts = [];
  AccountItem? _selectedAccount; 
  
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);
  
  String _categoryMode = 'EXPENSE'; 
  Map<String, double> _categoryData = {};
  double _totalCategoryAmount = 0;
  
  bool _isLoading = true;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final accs = await _accountRepo.fetchAccounts();
    setState(() {
      _accounts = accs;
    });
    await _refreshDashboard();
  }

  Future<void> _refreshDashboard() async {
    setState(() => _isLoading = true);
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

    setState(() {
      _categoryData = catTotals;
      _totalCategoryAmount = sum;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 800;
    
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Container(
      color: const Color(0xFFF5F5F5),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. TOP FILTERS (Responsive Row/Column)
            isMobile 
              ? Column(
                  children: [
                    _buildFilterBox(l10n.accounts.toUpperCase(), _buildAccountDropdown(l10n)),
                    const SizedBox(height: 12),
                    _buildFilterBox(l10n.period.toUpperCase(), _buildPeriodSelector()),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildFilterBox(l10n.accounts.toUpperCase(), _buildAccountDropdown(l10n))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildFilterBox(l10n.period.toUpperCase(), _buildPeriodSelector())),
                  ],
                ),
            const SizedBox(height: 16),

            // 2. BALANCE SUMMARY (UP)
            _buildBalanceSection(l10n),
            const SizedBox(height: 16),

            // 3. CATEGORIES ANALYSIS (DOWN)
            _buildCategoriesSection(l10n, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBox(String label, Widget child) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _buildAccountDropdown(AppLocalizations l10n) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<AccountItem?>(
        value: _selectedAccount,
        isDense: true,
        isExpanded: true,
        items: [
          DropdownMenuItem(value: null, child: Text(l10n.allAccounts, style: const TextStyle(fontSize: 13))),
          ..._accounts.map((a) => DropdownMenuItem(value: a, child: Text(a.name, style: const TextStyle(fontSize: 13)))),
        ],
        onChanged: (val) {
          setState(() => _selectedAccount = val);
          _refreshDashboard();
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return InkWell(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
        if (picked != null) {
          setState(() {
            _startDate = picked.start;
            _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
          });
          _refreshDashboard();
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}',
            style: const TextStyle(fontSize: 13),
          ),
          const Icon(Icons.calendar_today, size: 14, color: AppColors.secondaryText),
        ],
      ),
    );
  }

  Widget _buildBalanceSection(AppLocalizations l10n) {
    double netWorth = _accounts.fold(0, (sum, a) => sum + ((a.amount?.value ?? 0) / 100));
    return _buildSectionCard(
      title: l10n.balanceSummary.toUpperCase(),
      child: Column(
        children: [
          _buildBalanceRow(l10n.netWorth, netWorth, isBold: true),
          const Divider(),
          ..._accounts.map((a) => _buildBalanceRow(a.name, (a.amount?.value ?? 0) / 100)),
        ],
      ),
    );
  }

  Widget _buildBalanceRow(String label, double val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            '€ ${val.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: val < 0 ? AppColors.expenseRed : (isBold ? AppColors.primaryBlue : AppColors.incomeGreen)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(AppLocalizations l10n, bool isMobile) {
    return Column(
      children: [
        _buildViewModeSelector(l10n),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: l10n.categoriesAnalysis.toUpperCase(),
          child: Column(
            children: [
              isMobile 
                ? Column(
                    children: [
                      SizedBox(height: 250, child: _buildPieChartComponent(l10n)),
                      const SizedBox(height: 32),
                      _buildCategoryTable(l10n),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: SizedBox(height: 280, child: _buildPieChartComponent(l10n))),
                      const SizedBox(width: 32),
                      Expanded(flex: 6, child: _buildCategoryTable(l10n)),
                    ],
                  ),
              const Divider(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${l10n.totalBalance}: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  Text('€ ${_totalCategoryAmount.toStringAsFixed(2)}', 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _categoryMode == 'EXPENSE' ? AppColors.expenseRed : AppColors.incomeGreen)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPieChartComponent(AppLocalizations l10n) {
    if (_categoryData.isEmpty) return Center(child: Text(l10n.noData));
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                _touchedIndex = -1;
                return;
              }
              _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        sectionsSpace: 4,
        centerSpaceRadius: 50,
        sections: _buildChartSections(),
      ),
    );
  }

  Widget _buildViewModeSelector(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12)),
      child: Row(
        children: [
          _buildModeTab('EXPENSE', l10n.expense.toUpperCase(), AppColors.expenseRed),
          _buildModeTab('INCOME', l10n.income.toUpperCase(), AppColors.incomeGreen),
        ],
      ),
    );
  }

  Widget _buildModeTab(String mode, String label, Color color) {
    bool isSelected = _categoryMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _categoryMode = mode);
          _refreshDashboard();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.05) : Colors.transparent,
            border: Border(bottom: BorderSide(color: isSelected ? color : Colors.transparent, width: 3)),
          ),
          child: Center(
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? color : Colors.grey, fontSize: 12)),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTable(AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 4, child: Text(l10n.categoryName.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
            const Expanded(flex: 2, child: Text('%', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
            Expanded(flex: 3, child: Text(l10n.amount.toUpperCase(), textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
          ],
        ),
        const Divider(),
        ..._categoryData.entries.toList().asMap().entries.map((entry) {
          final isTouched = entry.key == _touchedIndex;
          final name = entry.value.key;
          final value = entry.value.value;
          final percent = (_totalCategoryAmount > 0) ? (value / _totalCategoryAmount) * 100 : 0.0;
          final color = _getPaletteColor(entry.key);

          return Container(
            color: isTouched ? color.withOpacity(0.05) : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(name, style: TextStyle(fontSize: 13, fontWeight: isTouched ? FontWeight.bold : FontWeight.normal))),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text('${percent.toStringAsFixed(1)}%', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('€ ${value.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
          const Divider(height: 30),
          child,
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections() {
    int i = 0;
    return _categoryData.entries.map((e) {
      final isTouched = i == _touchedIndex;
      final radius = isTouched ? 70.0 : 60.0;
      final color = _getPaletteColor(i++);

      return PieChartSectionData(
        color: color,
        value: e.value,
        title: isTouched ? '${((e.value/_totalCategoryAmount)*100).toStringAsFixed(0)}%' : '',
        radius: radius,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Color _getPaletteColor(int index) {
    List<Color> colors = [const Color(0xFF009FFB), Colors.orange, Colors.green, Colors.purple, Colors.redAccent, Colors.teal, Colors.amber, Colors.indigo];
    return colors[index % colors.length];
  }
}
