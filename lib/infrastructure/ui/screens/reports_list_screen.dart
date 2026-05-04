import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:printing/printing.dart';
import 'package:natave_flutter/infrastructure/ui/styles/app_styles.dart';
import 'package:natave_flutter/infrastructure/ui/widgets/donut_chart.dart';
import 'package:natave_flutter/infrastructure/ui/widgets/bar_chart.dart';
import 'package:natave_flutter/infrastructure/ui/widgets/ui_helpers.dart';
import 'package:natave_flutter/domain/models/transaction_item.dart';
import 'package:natave_flutter/domain/models/transaction_filters.dart';
import 'package:natave_flutter/domain/models/account_item.dart';
import 'package:natave_flutter/domain/models/category.dart';
import 'package:natave_flutter/domain/models/financial_entity.dart';
import 'package:natave_flutter/domain/models/beneficiary.dart';
import 'package:natave_flutter/domain/repositories/transaction_repository.dart';
import 'package:natave_flutter/domain/repositories/account_repository.dart';
import 'package:natave_flutter/domain/repositories/category_repository.dart';
import 'package:natave_flutter/domain/repositories/entity_repository.dart';
import 'package:natave_flutter/domain/repositories/beneficiary_repository.dart';
import 'package:natave_flutter/domain/repositories/report_repository.dart';
import 'package:natave_flutter/l10n/app_localizations.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});
  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  final IReportRepository _reportRepo = GetIt.instance.get<IReportRepository>();
  final ITransactionRepository _transactionRepo = GetIt.instance.get<ITransactionRepository>();
  final IAccountRepository _accountRepo = GetIt.instance.get<IAccountRepository>();
  final ICategoryRepository _categoryRepo = GetIt.instance.get<ICategoryRepository>();
  final IEntityRepository _entityRepo = GetIt.instance.get<IEntityRepository>();
  final IBeneficiaryRepository _beneficiaryRepo = GetIt.instance.get<IBeneficiaryRepository>();

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
  DateTime _endDate = DateTime.now();

  List<TransactionItem> _allPeriodTransactions = [];
  List<TransactionItem> _filteredTransactions = [];
  Map<String, double> _chartStats = {};
  bool _isLoading = true;
  bool _isPieChart = true;

  @override
  void initState() {
    super.initState();
    _loadAllMetadata();
  }

  Future<void> _loadAllMetadata() async {
    _entityRepo.fetchEntities().then((res) { if (mounted) setState(() => _entities = res); });
    _accountRepo.fetchAccounts().then((res) { if (mounted) setState(() => _allAccounts = res); });
    _categoryRepo.fetchCategories().then((res) { if (mounted) setState(() => _allCategories = res); });
    _beneficiaryRepo.getAllBeneficiaries().then((res) { if (mounted) setState(() => _allBeneficiaries = res); });
    await _refreshData();
  }

  TransactionFilters _buildCurrentFilters() {
    final accIds = _selectedAccounts.isNotEmpty 
        ? _selectedAccounts.map((a) => a.id).toList() 
        : (_selectedEntities.isNotEmpty 
            ? _allAccounts.where((a) => _selectedEntities.any((e) => e.id == a.entity?.id)).map((a) => a.id).toList() 
            : null);
    
    final catIds = _selectedCategories.isNotEmpty ? _selectedCategories.map((c) => c.id).toList() : null;
    final subIds = _selectedSubcategories.isNotEmpty ? _selectedSubcategories.map((s) => s.id).toList() : null;
    final benIds = _selectedBeneficiaries.isNotEmpty ? _selectedBeneficiaries.map((b) => b.id).toList() : null;

    return TransactionFilters(
      startDate: _startDate.toIso8601String(),
      endDate: _endDate.add(const Duration(days: 1)).toIso8601String(),
      accountIds: accIds,
      categoryIds: catIds,
      subcategoryIds: subIds,
      beneficiaryIds: benIds,
      groupBySubcategory: _selectedCategories.length == 1,
    );
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final filters = _buildCurrentFilters();

      final stats = await _reportRepo.fetchCategoryStats(filters);

      if (mounted) {
        setState(() {
          _chartStats = stats;
          _isLoading = false;
        });
        _loadPreviewTransactions(filters);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPreviewTransactions(TransactionFilters filters) async {
    try {
      final txs = await _transactionRepo.fetchTransactions(filters);
      if (mounted) {
        setState(() {
          _allPeriodTransactions = txs;
          _filteredTransactions = txs; // El repositorio ya filtra todo en SQL
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(l10n.financialAudit, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData)],
      ),
      endDrawer: isMobile ? Drawer(child: _buildSidebarContent(l10n)) : null,
      floatingActionButton: isMobile ? _buildFilterFAB(l10n) : null,
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

  Widget _buildFilterFAB(AppLocalizations l10n) {
    int count = 0;
    if (_selectedEntities.isNotEmpty) count++;
    if (_selectedAccounts.isNotEmpty) count++;
    if (_selectedCategories.isNotEmpty) count++;
    if (_selectedSubcategories.isNotEmpty) count++;
    if (_selectedBeneficiaries.isNotEmpty) count++;

    return Builder(builder: (context) => FloatingActionButton.extended(
      onPressed: () => Scaffold.of(context).openEndDrawer(),
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      icon: Stack(clipBehavior: Clip.none, children: [const Icon(Icons.filter_list_rounded, size: 20), if (count > 0) Positioned(right: -8, top: -8, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle), constraints: const BoxConstraints(minWidth: 16, minHeight: 16), child: Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center)))]),
      label: Text(l10n.reports.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
    ));
  }

  Widget _buildSidebarContent(AppLocalizations l10n, {double? width}) {
    return Container(
      width: width,
      decoration: BoxDecoration(color: Colors.white, border: width != null ? Border(right: BorderSide(color: Colors.grey.shade200)) : null),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildLabel(l10n.period.toUpperCase()),
          _buildDateSelector(),
          const SizedBox(height: 24),
          _buildLabel('${l10n.entity.toUpperCase()}S'),
          _buildMultiSelector<FinancialEntity>(selectedItems: _selectedEntities, hint: l10n.selectCompanies, items: _entities, label: (e) => e.name, onChanged: () { _selectedAccounts.clear(); _refreshData(); }),
          const SizedBox(height: 12),
          _buildLabel(l10n.accounts.toUpperCase()),
          _buildMultiSelector<AccountItem>(selectedItems: _selectedAccounts, hint: l10n.selectAccounts, items: _selectedEntities.isNotEmpty ? _allAccounts.where((a) => _selectedEntities.any((e) => e.id == a.entity?.id)).toList() : _allAccounts, label: (a) => a.name, onChanged: _refreshData),
          const SizedBox(height: 24),
          _buildLabel(l10n.categories.toUpperCase()),
          _buildMultiSelector<Category>(selectedItems: _selectedCategories, hint: l10n.selectCategories, items: _allCategories, label: (c) => c.name, onChanged: () { _selectedSubcategories.clear(); _refreshData(); }),
          const SizedBox(height: 12),
          _buildLabel(l10n.subcategoryOf.toUpperCase()),
          _buildMultiSelector<Subcategory>(selectedItems: _selectedSubcategories, hint: l10n.selectSubcategories, items: _selectedCategories.isNotEmpty ? _selectedCategories.expand((c) => c.subcategories).toList() : [], label: (s) => s.name, onChanged: _refreshData, isEnabled: _selectedCategories.isNotEmpty),
          const SizedBox(height: 24),
          _buildLabel('BENEFICIARIOS'),
          _buildMultiSelector<Beneficiary>(selectedItems: _selectedBeneficiaries, hint: l10n.selectBeneficiaries, items: _allBeneficiaries, label: (b) => b.name, onChanged: _refreshData),
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
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)]),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(_selectedCategories.length == 1 ? '${l10n.categoriesAnalysis}: ${_selectedCategories.first.name}' : l10n.expenseDistribution, style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                _buildChartToggle(),
              ]),
              const SizedBox(height: 24),
              SizedBox(height: isMobile ? 220 : 300, child: _isPieChart ? DonutChart(data: _chartStats, colors: AppColors.chartPalette) : CustomBarChart(data: _chartStats, colors: AppColors.chartPalette)),
              const SizedBox(height: 24),
              _buildLegend(isMobile: isMobile),
            ]),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${l10n.movementsPreview} (${_filteredTransactions.length})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const Divider(),
        ..._filteredTransactions.take(isMobile ? 10 : 20).map((tx) => ListTile(contentPadding: EdgeInsets.zero, dense: true, title: Text(tx.description, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis), subtitle: Text('${tx.account.entity?.name ?? ''} > ${tx.account.name}', style: const TextStyle(fontSize: 10)), trailing: Text('€${(tx.amount.value / 100).toStringAsFixed(2)}', style: TextStyle(color: tx.amount.isNegative ? Colors.redAccent : Colors.green, fontWeight: FontWeight.bold, fontSize: 12)))),
      ]),
    );
  }

  Widget _buildLegend({bool isMobile = false}) {
    return Wrap(spacing: isMobile ? 12 : 24, runSpacing: 8, children: _chartStats.entries.map((e) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.chartPalette[_chartStats.keys.toList().indexOf(e.key) % AppColors.chartPalette.length], borderRadius: BorderRadius.circular(2))), const SizedBox(width: 6), Text('${e.key}: €${e.value.toStringAsFixed(0)}', style: TextStyle(fontSize: isMobile ? 10 : 12))])).toList());
  }

  Widget _buildChartToggle() => Row(children: [IconButton(icon: Icon(Icons.pie_chart_outline, color: _isPieChart ? AppColors.primaryBlue : Colors.grey, size: 20), onPressed: () => setState(() => _isPieChart = true)), IconButton(icon: Icon(Icons.bar_chart_outlined, color: !_isPieChart ? AppColors.primaryBlue : Colors.grey, size: 20), onPressed: () => setState(() => _isPieChart = false))]);

  Widget _buildMultiSelector<T>({required Set<T> selectedItems, required String hint, required List<T> items, required String Function(T) label, required VoidCallback onChanged, bool isEnabled = true}) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(onTap: !isEnabled ? null : () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => _MultiSearchModal<T>(title: hint, items: items, label: label, initialSelection: selectedItems.toList(), onDone: (res) { setState(() { selectedItems.clear(); selectedItems.addAll(res); }); onChanged(); })), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), decoration: BoxDecoration(color: !isEnabled ? Colors.grey.shade100 : Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), child: Row(children: [Expanded(child: Text(selectedItems.isEmpty ? hint : selectedItems.length == 1 ? label(selectedItems.first) : l10n.selectItems(selectedItems.length), style: TextStyle(fontSize: 12, color: selectedItems.isEmpty ? Colors.grey.shade400 : AppColors.primaryText, fontWeight: selectedItems.isEmpty ? FontWeight.normal : FontWeight.w600), overflow: TextOverflow.ellipsis)), Icon(Icons.keyboard_arrow_down, size: 16, color: !isEnabled ? Colors.grey.shade300 : AppColors.primaryBlue)])));
  }

  Widget _buildLabel(String t) => Padding(padding: const EdgeInsets.only(bottom: 6, left: 4), child: Text(t, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)));

  void _applyQuickFilter(String filter) {
    final now = DateTime.now();
    setState(() {
      switch (filter) {
        case 'THIS_MONTH':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case 'LAST_MONTH':
          _startDate = DateTime(now.year, now.month - 1, 1);
          _endDate = DateTime(now.year, now.month, 0);
          break;
        case 'LAST_3_MONTHS':
          _startDate = DateTime(now.year, now.month - 2, 1);
          _endDate = now;
          break;
        case 'LAST_6_MONTHS':
          _startDate = DateTime(now.year, now.month - 5, 1);
          _endDate = now;
          break;
        case 'THIS_YEAR':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = now;
          break;
      }
    });
    _refreshData();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _refreshData();
    }
  }

  Widget _buildDateSelector() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'CUSTOM') {
          _selectDateRange();
        } else {
          _applyQuickFilter(value);
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => [
        PopupMenuItem(value: 'THIS_MONTH', child: _buildPopupItem(Icons.calendar_view_month, 'Este mes')),
        PopupMenuItem(value: 'LAST_MONTH', child: _buildPopupItem(Icons.keyboard_arrow_left, 'Mes pasado')),
        PopupMenuItem(value: 'LAST_3_MONTHS', child: _buildPopupItem(Icons.more_time, 'Últimos 3 meses')),
        PopupMenuItem(value: 'LAST_6_MONTHS', child: _buildPopupItem(Icons.update, 'Últimos 6 meses')),
        PopupMenuItem(value: 'THIS_YEAR', child: _buildPopupItem(Icons.calendar_today, 'Este año')),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'CUSTOM', child: _buildPopupItem(Icons.calendar_month, 'Seleccionar fechas...')),
      ],
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range, size: 14, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}',
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryBlue),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _clearFilters() {
 setState(() { _selectedEntities.clear(); _selectedAccounts.clear(); _selectedCategories.clear(); _selectedSubcategories.clear(); _selectedBeneficiaries.clear(); }); _refreshData(); }

  Future<void> _generatePdf() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final filters = _buildCurrentFilters();

      final pdf = await _reportRepo.downloadPdf(
        title: l10n.auditReportTitle, 
        chartType: _isPieChart ? 'PIE' : 'BAR', 
        reportType: 'ENTITY', 
        filters: filters,
        lang: Localizations.localeOf(context).languageCode
      );
      if (pdf != null) await Printing.layoutPdf(onLayout: (f) async => pdf, name: 'Informe_Natave.pdf');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al generar PDF'), backgroundColor: Colors.redAccent));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }
}

class _MultiSearchModal<T> extends StatefulWidget {
  final String title; final List<T> items; final String Function(T) label; final List<T> initialSelection; final Function(List<T>) onDone;
  const _MultiSearchModal({required this.title, required this.items, required this.label, required this.initialSelection, required this.onDone});
  @override State<_MultiSearchModal<T>> createState() => _MultiSearchModalState<T>();
}

class _MultiSearchModalState<T> extends State<_MultiSearchModal<T>> {
  late List<T> _filteredItems; final List<T> _tempSelection = []; final TextEditingController _searchController = TextEditingController();
  @override void initState() { super.initState(); _filteredItems = widget.items; _tempSelection.addAll(widget.initialSelection); }
  void _filter(String q) { setState(() { _filteredItems = widget.items.where((i) => widget.label(i).toLowerCase().contains(q.toLowerCase())).toList(); }); }
  @override Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(height: MediaQuery.of(context).size.height * 0.85, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))), padding: const EdgeInsets.all(24), child: Column(children: [Row(children: [Expanded(child: Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)), TextButton(onPressed: () { setState(() { if (_tempSelection.length == widget.items.length) { _tempSelection.clear(); } else { _tempSelection.clear(); _tempSelection.addAll(widget.items); } }); }, child: Text(_tempSelection.length == widget.items.length ? l10n.deselectAll : l10n.selectAll, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))), const SizedBox(width: 8), ElevatedButton(onPressed: () { widget.onDone(_tempSelection); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, elevation: 0), child: Text(l10n.accept))]), const SizedBox(height: 16), TextField(controller: _searchController, decoration: InputDecoration(hintText: l10n.searchHint, prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), onChanged: _filter), const SizedBox(height: 16), Expanded(child: ListView.builder(itemCount: _filteredItems.length, itemBuilder: (context, i) { final item = _filteredItems[i]; final isSelected = _tempSelection.contains(item); return CheckboxListTile(value: isSelected, title: Text(widget.label(item), style: const TextStyle(fontSize: 14)), activeColor: AppColors.primaryBlue, onChanged: (val) { setState(() { val == true ? _tempSelection.add(item) : _tempSelection.remove(item); }); }); }))]));
  }
}
