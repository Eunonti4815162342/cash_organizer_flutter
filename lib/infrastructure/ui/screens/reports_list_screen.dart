import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:printing/printing.dart';
import '../styles/app_styles.dart';
import '../widgets/donut_chart.dart';
import '../widgets/bar_chart.dart';
import '../widgets/ui_helpers.dart';
import '../../../services/api_service.dart';
import '../../../domain/models/transaction_item.dart';
import '../../../domain/models/account_item.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/financial_entity.dart';
import '../../../domain/models/beneficiary.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../../../l10n/app_localizations.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  final ApiService _apiService = GetIt.instance.get<ApiService>();
  final ITransactionRepository _transactionRepo = GetIt.instance.get<ITransactionRepository>();

  List<FinancialEntity> _entities = [];
  List<AccountItem> _allAccounts = [];
  List<Category> _allCategories = [];
  List<Beneficiary> _allBeneficiaries = [];

  final Set<FinancialEntity> _selectedEntities = {};
  final Set<AccountItem> _selectedAccounts = {};
  final Set<Category> _selectedCategories = {};
  final Set<Subcategory> _selectedSubcategories = {};
  final Set<Beneficiary> _selectedBeneficiaries = {};
  
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));

  List<TransactionItem> _allPeriodTransactions = [];
  List<TransactionItem> _filteredTransactions = [];
  Map<String, double> _chartStats = {};
  bool _isLoading = true;
  bool _isPieChart = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.fetchEntities(),
        _apiService.fetchAccounts(),
        _apiService.fetchCategories(),
        _apiService.fetchBeneficiaries(),
      ]);
      if (mounted) {
        setState(() {
          _entities = results[0] as List<FinancialEntity>;
          _allAccounts = results[1] as List<AccountItem>;
          _allCategories = results[2] as List<Category>;
          _allBeneficiaries = results[3] as List<Beneficiary>;
        });
        await _refreshDataFromApi();
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshDataFromApi() async {
    setState(() => _isLoading = true);
    try {
      final txs = await _transactionRepo.fetchTransactions(
        startDate: _startDate.toIso8601String(),
        endDate: _endDate.toIso8601String(),
      );
      if (mounted) {
        setState(() => _allPeriodTransactions = txs);
        _applyLocalFilters();
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyLocalFilters() {
    final filtered = _allPeriodTransactions.where((tx) {
      if (_selectedAccounts.isNotEmpty && !_selectedAccounts.any((a) => a.id == tx.account.id)) return false;
      if (_selectedEntities.isNotEmpty && !_selectedEntities.any((e) => e.id == tx.account.entity?.id)) return false;
      if (_selectedCategories.isNotEmpty && !_selectedCategories.any((c) => c.id == tx.category?.id)) return false;
      if (_selectedSubcategories.isNotEmpty && !_selectedSubcategories.any((s) => s.id == tx.subcategory?.id)) return false;
      if (_selectedBeneficiaries.isNotEmpty && !_selectedBeneficiaries.any((b) => b.id == tx.beneficiary?.id)) return false;
      return true;
    }).toList();

    final Map<String, double> stats = {};
    for (var tx in filtered) {
      String key = _selectedCategories.length == 1 
          ? (tx.subcategory?.name ?? 'General') 
          : (tx.category?.name ?? 'Otros');
      stats[key] = (stats[key] ?? 0) + (tx.amount.value / 100).abs();
    }

    setState(() {
      _filteredTransactions = filtered;
      _chartStats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(l10n.financialAudit, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        actions: [
          if (isMobile) 
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                tooltip: l10n.reports,
              ),
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshDataFromApi),
        ],
      ),
      endDrawer: isMobile ? Drawer(child: _buildSidebarContent(l10n)) : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebarContent(l10n, width: 280),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _buildMainDashboard(l10n, isMobile: isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent(AppLocalizations l10n, {double? width}) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white, 
        border: width != null ? Border(right: BorderSide(color: Colors.grey.shade200)) : null
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildLabel(l10n.period.toUpperCase()),
          _buildDateSelector(),
          const SizedBox(height: 24),
          _buildLabel(l10n.entity.toUpperCase() + 'S'),
          _buildMultiSelector<FinancialEntity>(selectedItems: _selectedEntities, hint: l10n.selectCompanies, items: _entities, label: (e) => e.name, onChanged: () { _selectedAccounts.clear(); _applyLocalFilters(); }),
          const SizedBox(height: 12),
          _buildLabel(l10n.accounts.toUpperCase()),
          _buildMultiSelector<AccountItem>(selectedItems: _selectedAccounts, hint: l10n.selectAccounts, items: _selectedEntities.isNotEmpty ? _allAccounts.where((a) => _selectedEntities.any((e) => e.id == a.entity?.id)).toList() : _allAccounts, label: (a) => a.name, onChanged: _applyLocalFilters),
          const SizedBox(height: 24),
          _buildLabel(l10n.categories.toUpperCase()),
          _buildMultiSelector<Category>(selectedItems: _selectedCategories, hint: l10n.selectCategories, items: _allCategories, label: (c) => c.name, onChanged: () { _selectedSubcategories.clear(); _applyLocalFilters(); }),
          const SizedBox(height: 12),
          _buildLabel(l10n.subcategoryOf.toUpperCase()),
          _buildMultiSelector<Subcategory>(selectedItems: _selectedSubcategories, hint: l10n.selectSubcategories, items: _selectedCategories.isNotEmpty ? _selectedCategories.expand((c) => c.subcategories).toList() : [], label: (s) => s.name, onChanged: _applyLocalFilters, isEnabled: _selectedCategories.isNotEmpty),
          const SizedBox(height: 24),
          _buildLabel('BENEFICIARIOS'),
          _buildMultiSelector<Beneficiary>(selectedItems: _selectedBeneficiaries, hint: l10n.selectBeneficiaries, items: _allBeneficiaries, label: (b) => b.name, onChanged: _applyLocalFilters),
          
          const SizedBox(height: 40),
          ElevatedButton.icon(onPressed: _generatePdf, icon: const Icon(Icons.picture_as_pdf, size: 16), label: Text(l10n.downloadPdf, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 12),
          TextButton(onPressed: _clearFilters, child: Text(l10n.clearFilters, style: const TextStyle(fontSize: 11, color: Colors.redAccent))),
        ],
      ),
    );
  }

  Widget _buildMainDashboard(AppLocalizations l10n, {bool isMobile = false}) {
    if (_chartStats.isEmpty) return EmptyStateWidget(icon: Icons.filter_alt_outlined, title: l10n.noData, subtitle: l10n.adjustFilters);
    
    final padding = isMobile ? const EdgeInsets.all(12) : const EdgeInsets.all(32);
    final cardPadding = isMobile ? const EdgeInsets.all(16) : const EdgeInsets.all(32);
    final chartHeight = isMobile ? 220.0 : 300.0;

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        children: [
          Container(
            padding: cardPadding,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)]),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(
                    child: Text(
                      _selectedCategories.length == 1 ? '${l10n.categoriesAnalysis}: ${_selectedCategories.first.name}' : l10n.expenseDistribution, 
                      style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildChartToggle(),
                ]),
                SizedBox(height: isMobile ? 8 : 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l10n.basedOnFilters, style: TextStyle(fontSize: isMobile ? 10 : 12, color: Colors.grey.shade500)),
                ),
                SizedBox(height: isMobile ? 24 : 40),
                SizedBox(
                  height: chartHeight, 
                  child: _isPieChart 
                    ? DonutChart(data: _chartStats, colors: AppColors.chartPalette) 
                    : CustomBarChart(data: _chartStats, colors: AppColors.chartPalette)
                ),
                SizedBox(height: isMobile ? 24 : 40),
                _buildLegend(isMobile: isMobile),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildMovementPreview(l10n, isMobile: isMobile),
        ],
      ),
    );
  }

  Widget _buildMovementPreview(AppLocalizations l10n, {bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${l10n.movementsPreview} (${_filteredTransactions.length})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          const Divider(),
          ..._filteredTransactions.take(isMobile ? 8 : 15).map((tx) => ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(tx.description, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            subtitle: Text('${tx.account.entity?.name ?? ''} > ${tx.account.name}', style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis),
            trailing: Text('€${(tx.amount.value / 100).toStringAsFixed(2)}', style: TextStyle(color: tx.amount.isNegative ? Colors.redAccent : Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
          )),
        ],
      ),
    );
  }

  Widget _buildLegend({bool isMobile = false}) {
    return Wrap(
      spacing: isMobile ? 12 : 24, 
      runSpacing: isMobile ? 8 : 12,
      children: _chartStats.entries.map((e) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8, 
            decoration: BoxDecoration(
              color: AppColors.chartPalette[_chartStats.keys.toList().indexOf(e.key) % AppColors.chartPalette.length],
              borderRadius: BorderRadius.circular(2)
            ),
          ),
          const SizedBox(width: 6),
          Text('${e.key}: €${e.value.toStringAsFixed(0)}', style: TextStyle(fontSize: isMobile ? 10 : 12)),
        ],
      )).toList(),
    );
  }

  Widget _buildChartToggle() {
    return Row(children: [
      IconButton(icon: Icon(Icons.pie_chart_outline, color: _isPieChart ? AppColors.primaryBlue : Colors.grey, size: 20), onPressed: () => setState(() => _isPieChart = true)),
      IconButton(icon: Icon(Icons.bar_chart_outlined, color: !_isPieChart ? AppColors.primaryBlue : Colors.grey, size: 20), onPressed: () => setState(() => _isPieChart = false)),
    ]);
  }

  Widget _buildMultiSelector<T>({required Set<T> selectedItems, required String hint, required List<T> items, required String Function(T) label, required VoidCallback onChanged, bool isEnabled = true}) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: !isEnabled ? null : () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => _MultiSearchModal<T>(title: hint, items: items, label: label, initialSelection: selectedItems.toList(), onDone: (res) { setState(() { selectedItems.clear(); selectedItems.addAll(res); }); onChanged(); })),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), decoration: BoxDecoration(color: !isEnabled ? Colors.grey.shade100 : Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), child: Row(children: [Expanded(child: Text(selectedItems.isEmpty ? hint : selectedItems.length == 1 ? label(selectedItems.first) : l10n.selectItems(selectedItems.length), style: TextStyle(fontSize: 12, color: selectedItems.isEmpty ? Colors.grey.shade400 : AppColors.primaryText, fontWeight: selectedItems.isEmpty ? FontWeight.normal : FontWeight.w600), overflow: TextOverflow.ellipsis)), Icon(Icons.keyboard_arrow_down, size: 16, color: !isEnabled ? Colors.grey.shade300 : AppColors.primaryBlue)])),
    );
  }

  Widget _buildLabel(String t) => Padding(padding: const EdgeInsets.only(bottom: 6, left: 4), child: Text(t, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)));

  Widget _buildDateSelector() => InkWell(
    onTap: () async {
      final picked = await showDateRangePicker(context: context, initialDateRange: DateTimeRange(start: _startDate, end: _endDate), firstDate: DateTime(2000), lastDate: DateTime(2101));
      if (picked != null) { setState(() { _startDate = picked.start; _endDate = picked.end; }); _refreshDataFromApi(); }
    },
    child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), child: Row(children: [const Icon(Icons.date_range, size: 14, color: AppColors.primaryBlue), const SizedBox(width: 8), Text('${_startDate.day}/${_startDate.month} - ${_endDate.day}/${_endDate.month}', style: const TextStyle(fontSize: 11))])),
  );

  void _clearFilters() { setState(() { _selectedEntities.clear(); _selectedAccounts.clear(); _selectedCategories.clear(); _selectedSubcategories.clear(); _selectedBeneficiaries.clear(); }); _applyLocalFilters(); }

  Future<void> _generatePdf() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final accIds = _selectedAccounts.isNotEmpty 
          ? _selectedAccounts.map((a) => a.id).toList() 
          : (_selectedEntities.isNotEmpty 
              ? _allAccounts.where((a) => _selectedEntities.any((e) => e.id == a.entity?.id)).map((a) => a.id).toList() 
              : null);
      final catIds = _selectedCategories.isNotEmpty ? _selectedCategories.map((c) => c.id).toList() : null;
      final benIds = _selectedBeneficiaries.isNotEmpty ? _selectedBeneficiaries.map((b) => b.id).toList() : null;

      final String languageCode = Localizations.localeOf(context).languageCode;

      final pdf = await _apiService.downloadPdfReport(
        title: l10n.auditReportTitle,
        chartType: _isPieChart ? 'PIE' : 'BAR',
        reportType: 'ENTITY', 
        startDate: _startDate.toIso8601String(),
        endDate: _endDate.toIso8601String(),
        accountIds: accIds,
        categoryIds: catIds,
        beneficiaryIds: benIds, 
        lang: languageCode,
      );
      if (pdf != null) await Printing.layoutPdf(onLayout: (f) async => pdf, name: 'Informe_Natave.pdf');
    } catch (e) {
      debugPrint('Error PDF: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _MultiSearchModal<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) label;
  final List<T> initialSelection;
  final Function(List<T>) onDone;

  const _MultiSearchModal({required this.title, required this.items, required this.label, required this.initialSelection, required this.onDone});

  @override
  State<_MultiSearchModal<T>> createState() => _MultiSearchModalState<T>();
}

class _MultiSearchModalState<T> extends State<_MultiSearchModal<T>> {
  late List<T> _filteredItems;
  final List<T> _tempSelection = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _tempSelection.addAll(widget.initialSelection);
  }

  void _filter(String q) {
    setState(() {
      _filteredItems = widget.items.where((i) => widget.label(i).toLowerCase().contains(q.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_tempSelection.length == widget.items.length) {
                      _tempSelection.clear();
                    } else {
                      _tempSelection.clear();
                      _tempSelection.addAll(widget.items);
                    }
                  });
                },
                child: Text(_tempSelection.length == widget.items.length ? l10n.deselectAll : l10n.selectAll, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () { widget.onDone(_tempSelection); Navigator.pop(context); },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, elevation: 0),
                child: Text(l10n.accept),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: _filter,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredItems.length,
              itemBuilder: (context, i) {
                final item = _filteredItems[i];
                final isSelected = _tempSelection.contains(item);
                return CheckboxListTile(
                  value: isSelected,
                  title: Text(widget.label(item), style: const TextStyle(fontSize: 14)),
                  activeColor: AppColors.primaryBlue,
                  onChanged: (val) {
                    setState(() {
                      val == true ? _tempSelection.add(item) : _tempSelection.remove(item);
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
