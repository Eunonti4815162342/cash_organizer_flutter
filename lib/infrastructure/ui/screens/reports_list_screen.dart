import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:printing/printing.dart';
import '../styles/app_styles.dart';
import '../widgets/donut_chart.dart';
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
  final ApiService _apiService = ApiService();
  
  String? _selectedReportTitle = 'Category Analysis';
  bool _isPieChart = true;
  
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  
  List<AccountItem> _accounts = [];
  List<int> _selectedAccountIds = [];
  
  List<Category> _categories = [];
  List<int> _selectedCategoryIds = [];
  Map<String, double> _categoryStats = {};
  bool _groupBySubcategory = false;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final accs = await _apiService.fetchAccounts();
      final cats = await _apiService.fetchCategories();
      
      if (_selectedAccountIds.isEmpty) _selectedAccountIds = accs.map((a) => a.id).toList();
      
      final stats = await _apiService.fetchCategoryStats(
        startDate: _startDate.toIso8601String(),
        endDate: _endDate.toIso8601String(),
        accountIds: _selectedAccountIds,
        groupBySubcategory: _groupBySubcategory,
      );
      
      if (mounted) {
        setState(() {
          _accounts = accs;
          _categories = cats;
          _categoryStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      body: Column(
        children: [
          _buildTopBar(l10n),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : isMobile ? _buildMobileLayout(l10n) : _buildDesktopLayout(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations l10n) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics_outlined, color: AppColors.primaryBlue),
          const SizedBox(width: 12),
          Text(l10n.reports.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.primaryText)),
          const Spacer(),
          _buildDateRangeChip(),
          const SizedBox(width: 16),
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _loadData),
        ],
      ),
    );
  }

  Widget _buildDateRangeChip() {
    return ActionChip(
      backgroundColor: Colors.white,
      side: const BorderSide(color: Colors.black12),
      avatar: const Icon(Icons.calendar_today, size: 14, color: AppColors.primaryBlue),
      label: Text('${_startDate.day}/${_startDate.month} - ${_endDate.day}/${_endDate.month}', style: const TextStyle(fontSize: 12)),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMainContent(l10n),
          const SizedBox(height: 16),
          _buildSidebar(l10n),
        ],
      ),
    );
  }

  Widget _buildSidebar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('REPORT TYPES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 16),
          _buildReportTypeCard('Category Analysis', 'Spending by category', Icons.category_outlined),
          _buildReportTypeCard('Account Balance Report', 'Total wealth view', Icons.account_balance_wallet_outlined),
          const SizedBox(height: 32),
          const Text('FILTER BY ACCOUNTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          ..._accounts.take(5).map((acc) => CheckboxListTile(
            title: Text(acc.name, style: const TextStyle(fontSize: 13)),
            value: _selectedAccountIds.contains(acc.id),
            dense: true,
            visualDensity: VisualDensity.compact,
            onChanged: (val) {
              setState(() {
                val! ? _selectedAccountIds.add(acc.id) : _selectedAccountIds.remove(acc.id);
              });
              _loadData();
            },
          )),
          const SizedBox(height: 32),
          const Text('OPTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Group by Subcategory', style: TextStyle(fontSize: 13)),
            value: _groupBySubcategory,
            activeColor: AppColors.primaryBlue,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() => _groupBySubcategory = val);
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeCard(String title, String subtitle, IconData icon) {
    bool isSelected = _selectedReportTitle == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedReportTitle = title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppColors.primaryBlue, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.primaryText)),
                Text(subtitle, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : Colors.grey)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Main Chart Card
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_selectedReportTitle!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                    _buildExportButton(l10n),
                  ],
                ),
                const SizedBox(height: 40),
                SizedBox(
                  height: 300,
                  child: _selectedReportTitle == 'Category Analysis' 
                    ? DonutChart(data: _categoryStats, thickness: 50)
                    : _buildPieChart(),
                ),
                const SizedBox(height: 40),
                _buildModernLegend(_selectedReportTitle == 'Category Analysis' ? _categoryStats : _getAccountStats()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _getAccountStats() {
    final filtered = _accounts.where((a) => _selectedAccountIds.contains(a.id)).toList();
    return {for (var a in filtered) a.name: (a.amount.value / 100).abs().toDouble()};
  }

  Widget _buildModernLegend(Map<String, double> stats) {
    if (stats.isEmpty) return const Text('No data for this selection', style: TextStyle(color: Colors.grey));
    final total = stats.values.fold(0.0, (sum, val) => sum + val);
    
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      children: stats.entries.toList().asMap().entries.map((entry) {
        final percentage = (entry.value.value / total * 100).toStringAsFixed(1);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: _getPaletteColor(entry.key), borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.value.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                Text('$percentage% • €${entry.value.value.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPieChart() {
    return DonutChart(data: _getAccountStats(), thickness: 50);
  }

  Widget _buildExportButton(AppLocalizations l10n) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _generatePdf,
      icon: const Icon(Icons.picture_as_pdf, size: 16),
      label: Text(l10n.exportPdf.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Color _getPaletteColor(int index) {
    List<Color> colors = [const Color(0xFF009FFB), const Color(0xFF27AE60), const Color(0xFFF2994A), const Color(0xFFEB5757), const Color(0xFF9B51E0), const Color(0xFF2D9CDB)];
    return colors[index % colors.length];
  }

  Future<void> _generatePdf() async {
    if (_selectedReportTitle == null) return;
    setState(() => _isLoading = true);
    try {
      final pdfBytes = await _apiService.downloadPdfReport(
        title: _selectedReportTitle!,
        chartType: _isPieChart ? 'PIE' : 'BAR',
        startDate: _startDate.toIso8601String(),
        endDate: _endDate.toIso8601String(),
        accountIds: _selectedAccountIds,
        categoryIds: _selectedCategoryIds,
      );
      if (pdfBytes != null) {
        await Printing.layoutPdf(onLayout: (format) async => pdfBytes, name: 'Report.pdf');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
