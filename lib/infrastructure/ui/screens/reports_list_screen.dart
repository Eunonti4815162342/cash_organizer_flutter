import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:get_it/get_it.dart';
import '../styles/app_styles.dart';
import '../widgets/donut_chart.dart';
import '../widgets/bar_chart.dart';
import '../../../services/api_service.dart';
import '../../../domain/models/account_item.dart';
import '../../../domain/models/category.dart';
import '../../../l10n/app_localizations.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  late final ApiService _apiService;

  String? _selectedReportTitle;
  bool _isPieChart = true;

  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));

  List<AccountItem> _accounts = [];
  List<int> _selectedAccountIds = [];

  List<Category> _categories = [];
  List<int> _selectedCategoryIds = [];
  Map<String, double> _currentStats = {};
  bool _groupBySubcategory = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _apiService = GetIt.instance.get<ApiService>();
    // Carga inicial tras el primer frame para tener acceso al contexto de l10n
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final accs = await _apiService.fetchAccounts();
      final cats = await _apiService.fetchCategories();

      if (_selectedAccountIds.isEmpty) {
        _selectedAccountIds = accs.map((a) => a.id).toList();
      }

      final reportTitle = _selectedReportTitle ?? l10n.categoryAnalysis;
      Map<String, double> stats = {};

      if (reportTitle == l10n.categoryAnalysis) {
        stats = await _apiService.fetchCategoryStats(
          startDate: _startDate.toIso8601String(),
          endDate: _endDate.toIso8601String(),
          accountIds: _selectedAccountIds,
          groupBySubcategory: _groupBySubcategory,
        );
      } else if (reportTitle == 'Entity Analysis') {
        stats = await _apiService.fetchEntityStats(
          startDate: _startDate.toIso8601String(),
          endDate: _endDate.toIso8601String(),
          accountIds: _selectedAccountIds,
        );
      } else if (reportTitle == 'Beneficiary Analysis') {
        stats = await _apiService.fetchBeneficiaryStats(
          startDate: _startDate.toIso8601String(),
          endDate: _endDate.toIso8601String(),
          accountIds: _selectedAccountIds,
        );
      } else {
        // Local calculation for Account Balance
        final filtered = accs.where((a) => _selectedAccountIds.contains(a.id)).toList();
        stats = {for (var a in filtered) a.name: (a.amount.value / 100).abs().toDouble()};
      }

      if (mounted) {
        setState(() {
          _accounts = accs;
          _categories = cats;
          _currentStats = stats;
          _selectedReportTitle = reportTitle;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading report data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < AppDimens.mobileBreakpoint;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      body: Column(
        children: [
          _buildTopBar(l10n, isMobile),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : isMobile ? _buildMobileLayout(l10n) : _buildDesktopLayout(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations l10n, bool isMobile) {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.black12)),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics_outlined, color: AppColors.primaryBlue, size: isMobile ? 20 : 24),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.reports.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 14, letterSpacing: 1.2, color: AppColors.primaryText), overflow: TextOverflow.ellipsis)),
          _buildDateRangeChip(isMobile),
          IconButton(icon: Icon(Icons.refresh, size: isMobile ? 18 : 20), onPressed: _loadData),
        ],
      ),
    );
  }

  Widget _buildDateRangeChip(bool isMobile) {
    return ActionChip(
      backgroundColor: AppColors.white,
      padding: EdgeInsets.zero,
      side: const BorderSide(color: AppColors.black12),
      avatar: const Icon(Icons.calendar_today, size: 12, color: AppColors.primaryBlue),
      label: Text('${_startDate.day}/${_startDate.month} - ${_endDate.day}/${_endDate.month}', style: TextStyle(fontSize: isMobile ? 10 : 12)),
      onPressed: _selectDateRange,
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primaryBlue)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  Widget _buildDesktopLayout(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildSidebar(l10n)),
        Expanded(flex: 9, child: _buildMainContent(l10n)),
      ],
    );
  }

  Widget _buildMobileLayout(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _buildMainContent(l10n, isMobile: true),
          const SizedBox(height: 12),
          _buildSidebar(l10n, isMobile: true),
        ],
      ),
    );
  }

  Widget _buildSidebar(AppLocalizations l10n, {bool isMobile = false}) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.reportTypes, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 16),
          _buildReportTypeCard(l10n.categoryAnalysis, l10n.categoriesAnalysis, Icons.category_outlined),
          _buildReportTypeCard('Entity Analysis', 'Spending by financial entity', Icons.business_outlined),
          _buildReportTypeCard('Beneficiary Analysis', 'Spending by beneficiary', Icons.person_search_outlined),
          _buildReportTypeCard(l10n.accountBalanceReport, l10n.spendingByAccount, Icons.account_balance_wallet_outlined),
          const SizedBox(height: 24),
          Text(l10n.filterByAccounts, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          ..._accounts.take(8).map((acc) => CheckboxListTile(
            title: Text(acc.name, style: const TextStyle(fontSize: 12)),
            value: _selectedAccountIds.contains(acc.id),
            dense: true,
            visualDensity: VisualDensity.compact,
            fillColor: WidgetStateProperty.resolveWith<Color>((states) =>
              states.contains(WidgetState.selected) ? AppColors.primaryBlue : Colors.grey),
            onChanged: (val) {
              setState(() {
                val! ? _selectedAccountIds.add(acc.id) : _selectedAccountIds.remove(acc.id);
              });
              _loadData();
            },
          )),
          if (_selectedReportTitle == l10n.categoryAnalysis) ...[
            const SizedBox(height: 24),
            Text(l10n.analysisLevel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            SwitchListTile(
              title: Text(l10n.groupBySubcategory, style: const TextStyle(fontSize: 12)),
              value: _groupBySubcategory,
              activeThumbColor: AppColors.primaryBlue,
              activeTrackColor: AppColors.primaryBlue,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                setState(() => _groupBySubcategory = val);
                _loadData();
              },
            ),
          ],
          const SizedBox(height: 32),
          _buildExportButton(l10n, isMobile: isMobile),
        ],
      ),
    );
  }

  Widget _buildReportTypeCard(String title, String subtitle, IconData icon) {
    bool isSelected = _selectedReportTitle == title;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedReportTitle = title);
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppColors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.white : AppColors.primaryBlue, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? AppColors.white : AppColors.primaryText)),
                Text(subtitle, style: TextStyle(fontSize: 9, color: isSelected ? Colors.white70 : Colors.grey)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(AppLocalizations l10n, {bool isMobile = false}) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 4.0 : 24.0),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
              boxShadow: [BoxShadow(color: AppColors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(_selectedReportTitle ?? '', style: TextStyle(fontSize: isMobile ? 15 : 18, fontWeight: FontWeight.bold, color: AppColors.primaryText), overflow: TextOverflow.ellipsis)),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.pie_chart_outline, size: isMobile ? 20 : 24, color: _isPieChart ? AppColors.primaryBlue : Colors.grey),
                          onPressed: () => setState(() => _isPieChart = true),
                        ),
                        IconButton(
                          icon: Icon(Icons.bar_chart_outlined, size: isMobile ? 20 : 24, color: !_isPieChart ? AppColors.primaryBlue : Colors.grey),
                          onPressed: () => setState(() => _isPieChart = false),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: isMobile ? 220 : 300,
                  child: _isPieChart
                    ? DonutChart(
                        data: _currentStats,
                        thickness: isMobile ? 35 : 50,
                        colors: List.generate(15, (index) => _getPaletteColor(index)),
                      )
                    : CustomBarChart(
                        data: _currentStats,
                        barWidth: isMobile ? 20 : 30,
                        colors: List.generate(15, (index) => _getPaletteColor(index)),
                      ),
                ),
                const SizedBox(height: 32),
                _buildModernLegend(_currentStats, isMobile: isMobile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernLegend(Map<String, double> stats, {bool isMobile = false}) {
    if (stats.isEmpty) return const Text('No data for this selection', style: TextStyle(color: Colors.grey));
    final total = stats.values.fold(0.0, (sum, val) => sum + val);

    return Wrap(
      spacing: isMobile ? 12 : 24,
      runSpacing: isMobile ? 12 : 16,
      children: stats.entries.toList().asMap().entries.map((entry) {
        final percentage = total == 0 ? "0" : (entry.value.value / total * 100).toStringAsFixed(1);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: _getPaletteColor(entry.key), borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.value.key, style: TextStyle(fontSize: isMobile ? 11 : 12, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                Text('$percentage% • €${entry.value.value.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildExportButton(AppLocalizations l10n, {bool isMobile = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _generatePdf,
        icon: Icon(Icons.picture_as_pdf, size: isMobile ? 14 : 16),
        label: Text(l10n.exportPdf.toUpperCase(), style: TextStyle(fontSize: isMobile ? 10 : 11, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Color _getPaletteColor(int index) {
    return AppColors.chartPalette[index % AppColors.chartPalette.length];
  }

  Future<void> _generatePdf() async {
    final reportTitle = _selectedReportTitle;
    if (reportTitle == null) return;

    final localeCode = Localizations.localeOf(context).languageCode;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isLoading = true);
    try {
      String type = 'CATEGORY';
      if (reportTitle == 'Entity Analysis') {
        type = 'ENTITY';
      } else if (reportTitle == 'Beneficiary Analysis') {
        type = 'BENEFICIARY';
      } else if (reportTitle == l10n.accountBalanceReport) {
        type = 'ACCOUNT';
      }

      final pdfBytes = await _apiService.downloadPdfReport(
        title: reportTitle,
        chartType: _isPieChart ? 'PIE' : 'BAR',
        reportType: type,
        startDate: _startDate.toIso8601String(),
        endDate: _endDate.toIso8601String(),
        accountIds: _selectedAccountIds,
        categoryIds: _selectedCategoryIds,
        lang: localeCode,
      );
      if (pdfBytes != null) {
        await Printing.layoutPdf(onLayout: (format) async => pdfBytes, name: 'Report.pdf');
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('Error al exportar el informe')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
