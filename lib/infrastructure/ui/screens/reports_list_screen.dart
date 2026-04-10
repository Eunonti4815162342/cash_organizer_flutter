import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../styles/app_styles.dart';
import '../../../services/api_service.dart';
import '../../../domain/models/account_item.dart';
import '../../../l10n/app_localizations.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  final ApiService _apiService = ApiService();
  String? _selectedReportTitle;
  String? _selectedReportDesc;
  bool _isPieChart = true;
  List<AccountItem> _accounts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final accs = await _apiService.fetchAccounts();
    if (mounted) {
      setState(() {
        _accounts = accs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Column(
      children: [
        // Tabs superiores
        Container(
          height: 45,
          color: AppColors.cardBackground,
          child: Row(
            children: [
              _buildTab('STANDARD REPORTS', true),
              _buildTab('CUSTOM REPORTS', false),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.secondaryText, size: 20),
                onPressed: _loadData,
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
        const Divider(height: 1),
        
        Expanded(
          child: isMobile ? _buildMobileLayout(l10n) : _buildDesktopLayout(l10n),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(flex: 4, child: _buildReportList()),
        Expanded(flex: 5, child: _buildChartPanel(l10n)),
        Expanded(flex: 3, child: _buildOptionsPanel(l10n, false)),
      ],
    );
  }

  Widget _buildMobileLayout(AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 300, child: _buildReportList()),
          const Divider(height: 1),
          if (_selectedReportTitle != null) ...[
            SizedBox(height: 350, child: _buildChartPanel(l10n)),
            _buildOptionsPanel(l10n, true),
          ] else
            Padding(
              padding: const EdgeInsets.all(40),
              child: Text(l10n.noData, style: const TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  Widget _buildReportList() {
    return Container(
      color: Colors.white,
      child: ListView(
        children: [
          _buildReportItem('Account Balance Report', 'Summary of all account balances', Icons.pie_chart),
          _buildReportItem('Net Worth Report', 'Total assets distribution', Icons.account_balance),
          _buildReportItem('Income vs Expenses', 'Comparison of monthly flow', Icons.trending_up),
        ],
      ),
    );
  }

  Widget _buildChartPanel(AppLocalizations l10n) {
    return Container(
      color: const Color(0xFFF9F9F9),
      padding: const EdgeInsets.all(24),
      child: _selectedReportTitle == null 
        ? Center(child: Text(l10n.noData))
        : _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Text(_selectedReportTitle!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A636F))),
                  const SizedBox(height: 20),
                  Expanded(child: _isPieChart ? _buildPieChart() : _buildBarChart()),
                  const SizedBox(height: 10),
                  _buildLegend(),
                ],
              ),
    );
  }

  Widget _buildOptionsPanel(AppLocalizations l10n, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : null,
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(left: isMobile ? BorderSide.none : const BorderSide(color: Colors.black12)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('VISUALIZATION OPTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondaryText)),
          const SizedBox(height: 20),
          if (_selectedReportTitle != null) ...[
            _buildProp('Report', _selectedReportTitle!, isBold: true),
            const Text('Chart Type', style: TextStyle(fontSize: 10, color: AppColors.secondaryText)),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Pie', style: TextStyle(fontSize: 12)),
                  selected: _isPieChart,
                  onSelected: (val) => setState(() => _isPieChart = true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Bars', style: TextStyle(fontSize: 12)),
                  selected: !_isPieChart,
                  onSelected: (val) => setState(() => _isPieChart = false),
                ),
              ],
            ),
            if (!isMobile) const Spacer() else const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generatePdf,
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
                label: Text(l10n.exportPdf, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Gráficos (Pie y Bar) ---
  Widget _buildPieChart() {
    return PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 40, sections: _accounts.map((acc) => PieChartSectionData(color: _getAccountColor(_accounts.indexOf(acc)), value: (acc.amount.value / 100).abs(), title: '', radius: 50)).toList()));
  }

  Widget _buildBarChart() {
    if (_accounts.isEmpty) return const SizedBox();
    double maxVal = _accounts.map((e) => (e.amount.value / 100).abs()).reduce((a, b) => a > b ? a : b) * 1.2;
    return BarChart(BarChartData(alignment: BarChartAlignment.spaceAround, maxY: maxVal, barGroups: _accounts.asMap().entries.map((entry) => BarChartGroupData(x: entry.key, barRods: [BarChartRodData(toY: (entry.value.amount.value / 100).toDouble(), color: entry.value.amount.isNegative ? Colors.redAccent : AppColors.primaryBlue, width: 16, borderRadius: BorderRadius.circular(2))])).toList(), titlesData: FlTitlesData(show: false), gridData: const FlGridData(show: false), borderData: FlBorderData(show: false)));
  }

  Widget _buildLegend() {
    return Wrap(spacing: 10, runSpacing: 4, children: _accounts.map((acc) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, color: _isPieChart ? _getAccountColor(_accounts.indexOf(acc)) : (acc.amount.isNegative ? Colors.redAccent : AppColors.primaryBlue)), const SizedBox(width: 4), Text(acc.name, style: const TextStyle(fontSize: 10))])).toList());
  }

  Color _getAccountColor(int index) {
    List<Color> colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.red];
    return colors[index % colors.length];
  }

  Widget _buildTab(String label, bool isSelected) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 20), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isSelected ? AppColors.primaryBlue : Colors.transparent, width: 3))), alignment: Alignment.center, child: Text(label, style: TextStyle(color: isSelected ? AppColors.primaryBlue : AppColors.secondaryText, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 11)));
  }

  Widget _buildReportItem(String title, String subtitle, IconData icon) {
    bool isSelected = _selectedReportTitle == title;
    return InkWell(
      onTap: () => setState(() { _selectedReportTitle = title; _selectedReportDesc = subtitle; }),
      child: Container(decoration: BoxDecoration(color: isSelected ? AppColors.primaryBlue.withOpacity(0.05) : Colors.transparent, border: const Border(bottom: BorderSide(color: Color(0xFFF0F0F0)))), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [Icon(icon, color: isSelected ? AppColors.primaryBlue : const Color(0xFF4A636F), size: 24), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: const Color(0xFF4A636F))), Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey))]))])),
    );
  }

  Widget _buildProp(String label, String value, {bool isBold = false}) {
    return Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 10, fontWeight: FontWeight.bold)), Text(value, style: TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal))]));
  }

  Future<void> _generatePdf() async {
    final String chartParam = _isPieChart ? 'PIE' : 'BAR';
    final String urlString = '${ApiService.baseUrl}/reports/pdf?title=${Uri.encodeComponent(_selectedReportTitle!)}&chartType=$chartParam';
    final Uri url = Uri.parse(urlString);
    
    try {
      // Usar launchUrl con el modo externalApplication para asegurar que Android lo abra
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening PDF: $e')));
      }
    }
  }
}
