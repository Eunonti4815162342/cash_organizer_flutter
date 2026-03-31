import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fl_chart/fl_chart.dart';
import 'dart:js' as js; 
import '../styles/app_styles.dart';
import '../../../services/api_service.dart';
import '../../../domain/models/account_item.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  final ApiService _apiService = ApiService();
  String? _selectedReportTitle;
  String? _selectedReportDesc;
  bool _isPieChart = true; // Toggle between Pie and Bar
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
    setState(() {
      _accounts = accs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
          child: Row(
            children: [
              // Lista de informes
              Expanded(
                flex: 4,
                child: Container(
                  color: Colors.white,
                  child: ListView(
                    children: [
                      _buildReportItem('Account Balance Report', 'Summary of all account balances', Icons.pie_chart),
                      _buildReportItem('Net Worth Report', 'Total assets distribution', Icons.account_balance),
                      _buildReportItem('Income vs Expenses', 'Comparison of monthly flow', Icons.trending_up),
                    ],
                  ),
                ),
              ),
              
              // Visualizador Central de Gráfico
              Expanded(
                flex: 5,
                child: Container(
                  color: const Color(0xFFF9F9F9),
                  padding: const EdgeInsets.all(32),
                  child: _selectedReportTitle == null 
                    ? const Center(child: Text('Select a report to visualize data', style: TextStyle(color: Colors.grey)))
                    : _isLoading 
                        ? const Center(child: CircularProgressIndicator())
                        : _buildChartContainer(),
                ),
              ),

              // Panel derecho de Propiedades y Opciones
              Expanded(
                flex: 3,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.sidebarBackground,
                    border: Border(left: BorderSide(color: Colors.black12)),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('VISUALIZATION OPTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondaryText)),
                      const SizedBox(height: 20),
                      if (_selectedReportTitle != null) ...[
                        _buildProp('Report', _selectedReportTitle!, isBold: true),
                        const SizedBox(height: 10),
                        const Text('Chart Type', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Pie'),
                              selected: _isPieChart,
                              onSelected: (val) => setState(() => _isPieChart = true),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Bars'),
                              selected: !_isPieChart,
                              onSelected: (val) => setState(() => _isPieChart = false),
                            ),
                          ],
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _generatePdf,
                            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                            label: const Text('EXPORT PDF', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                          ),
                        ),
                      ] else
                        const Center(child: Text('Options will appear here', style: TextStyle(fontSize: 12, color: Colors.grey))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartContainer() {
    return Column(
      children: [
        Text(_selectedReportTitle!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A636F))),
        const SizedBox(height: 40),
        Expanded(
          child: _isPieChart ? _buildPieChart() : _buildBarChart(),
        ),
        const SizedBox(height: 20),
        _buildLegend(),
      ],
    );
  }

  Widget _buildPieChart() {
    if (_accounts.isEmpty) return const Center(child: Text('No data'));
    
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: _accounts.map((acc) {
          final isNegative = acc.amount.isNegative;
          return PieChartSectionData(
            color: _getAccountColor(_accounts.indexOf(acc)),
            value: (acc.amount.value / 100).abs(),
            title: isNegative ? '-' : '',
            radius: 60,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBarChart() {
    if (_accounts.isEmpty) return const Center(child: Text('No data'));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _accounts.map((e) => (e.amount.value / 100).abs()).reduce((a, b) => a > b ? a : b) * 1.2,
        barGroups: _accounts.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: (entry.value.amount.value / 100).toDouble(),
                color: entry.value.amount.isNegative ? Colors.redAccent : AppColors.primaryBlue,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: _accounts.map((acc) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, color: _isPieChart ? _getAccountColor(_accounts.indexOf(acc)) : (acc.amount.isNegative ? Colors.redAccent : AppColors.primaryBlue)),
            const SizedBox(width: 4),
            Text(acc.name, style: const TextStyle(fontSize: 11)),
          ],
        );
      }).toList(),
    );
  }

  Color _getAccountColor(int index) {
    List<Color> colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.red];
    return colors[index % colors.length];
  }

  Widget _buildTab(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isSelected ? AppColors.primaryBlue : Colors.transparent, width: 3)),
      ),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(color: isSelected ? AppColors.primaryBlue : AppColors.secondaryText, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 11)),
    );
  }

  Widget _buildReportItem(String title, String subtitle, IconData icon) {
    bool isSelected = _selectedReportTitle == title;
    return InkWell(
      onTap: () => setState(() {
        _selectedReportTitle = title;
        _selectedReportDesc = subtitle;
      }),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue.withOpacity(0.05) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryBlue : const Color(0xFF4A636F), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: const Color(0xFF4A636F))),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProp(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 10, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Future<void> _generatePdf() async {
    final String chartParam = _isPieChart ? 'PIE' : 'BAR';
    final String url = '${ApiService.baseUrl}/reports/pdf?title=${Uri.encodeComponent(_selectedReportTitle!)}&chartType=$chartParam';
    if (kIsWeb) {
      js.context.callMethod('open', [url, '_blank']);
    }
  }
}
