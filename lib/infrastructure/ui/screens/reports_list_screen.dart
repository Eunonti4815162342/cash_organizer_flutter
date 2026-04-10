import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:fl_chart/fl_chart.dart';
import 'package:printing/printing.dart';
import '../styles/app_styles.dart';
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
  
  String? _selectedReportTitle;
  bool _isPieChart = true;
  
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  
  List<AccountItem> _accounts = [];
  List<int> _selectedAccountIds = [];
  
  List<Category> _categories = [];
  List<int> _selectedCategoryIds = [];
  
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
      if (mounted) {
        setState(() {
          _accounts = accs;
          _categories = cats;
          // Por defecto seleccionamos todo
          _selectedAccountIds = accs.map((a) => a.id).toList();
          _selectedCategoryIds = cats.map((c) => c.id).toList();
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
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Column(
      children: [
        Container(
          height: 45,
          color: AppColors.cardBackground,
          child: Row(
            children: [
              _buildTab('STANDARD REPORTS', true),
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
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : isMobile ? _buildMobileLayout(l10n) : _buildDesktopLayout(l10n),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(flex: 3, child: _buildReportList()),
        Expanded(flex: 6, child: _buildChartPanel(l10n)),
        Expanded(flex: 3, child: _buildCustomizationPanel(l10n)),
      ],
    );
  }

  Widget _buildMobileLayout(AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 200, child: _buildReportList()),
          if (_selectedReportTitle != null) ...[
            _buildCustomizationPanel(l10n),
            SizedBox(height: 300, child: _buildChartPanel(l10n)),
          ],
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
          _buildReportItem('Transaction History', 'Detailed list of movements', Icons.list_alt),
          _buildReportItem('Category Analysis', 'Spending distribution by category', Icons.category),
        ],
      ),
    );
  }

  Widget _buildCustomizationPanel(AppLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(left: BorderSide(color: Colors.black12)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CUSTOMIZE REPORT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondaryText)),
          const SizedBox(height: 16),
          
          _buildLabel('Date Range'),
          _buildDateSelector(),
          
          const Divider(height: 24),
          
          _buildLabel('Accounts'),
          _buildMultiSelectTrigger(
            label: '${_selectedAccountIds.length} Selected',
            onTap: () => _showMultiSelectDialog(
              title: 'Select Accounts',
              items: _accounts.map((a) => {'id': a.id, 'name': a.name}).toList(),
              selectedIds: _selectedAccountIds,
              onChanged: (ids) => setState(() => _selectedAccountIds = ids),
            ),
          ),
          
          const Divider(height: 24),

          _buildLabel('Categories'),
          _buildMultiSelectTrigger(
            label: '${_selectedCategoryIds.length} Selected',
            onTap: () => _showMultiSelectDialog(
              title: 'Select Categories',
              items: _categories.map((c) => {'id': c.id, 'name': c.name}).toList(),
              selectedIds: _selectedCategoryIds,
              onChanged: (ids) => setState(() => _selectedCategoryIds = ids),
            ),
          ),

          const Divider(height: 24),

          _buildLabel('Chart Visual'),
          Row(
            children: [
              ChoiceChip(label: const Text('Pie', style: TextStyle(fontSize: 11)), selected: _isPieChart, onSelected: (v) => setState(() => _isPieChart = true)),
              const SizedBox(width: 8),
              ChoiceChip(label: const Text('Bars', style: TextStyle(fontSize: 11)), selected: !_isPieChart, onSelected: (v) => setState(() => _isPieChart = false)),
            ],
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _generatePdf,
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
              label: Text(l10n.exportPdf, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 10, color: AppColors.secondaryText, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMultiSelectTrigger({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }

  void _showMultiSelectDialog({
    required String title,
    required List<Map<String, dynamic>> items,
    required List<int> selectedIds,
    required Function(List<int>) onChanged,
  }) {
    List<int> tempSelected = List.from(selectedIds);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => setDialogState(() => tempSelected = items.map((e) => e['id'] as int).toList()),
                          child: const Text('Select All', style: TextStyle(fontSize: 12)),
                        ),
                        TextButton(
                          onPressed: () => setDialogState(() => tempSelected = []),
                          child: const Text('Clear All', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const Divider(),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: items.map((item) {
                          final id = item['id'] as int;
                          final isChecked = tempSelected.contains(id);
                          return CheckboxListTile(
                            title: Text(item['name'], style: const TextStyle(fontSize: 13)),
                            value: isChecked,
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (val) {
                              setDialogState(() {
                                val! ? tempSelected.add(id) : tempSelected.remove(id);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
                ElevatedButton(
                  onPressed: () {
                    onChanged(tempSelected);
                    Navigator.pop(context);
                  },
                  child: const Text('APPLY'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateSelector() {
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
            _endDate = picked.end;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(4)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_startDate.day}/${_startDate.month} - ${_endDate.day}/${_endDate.month}', style: const TextStyle(fontSize: 12)),
            const Icon(Icons.calendar_today, size: 14, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }

  Widget _buildChartPanel(AppLocalizations l10n) {
    return Container(
      color: const Color(0xFFF9F9F9),
      padding: const EdgeInsets.all(24),
      child: _selectedReportTitle == null 
        ? Center(child: Text(l10n.noData))
        : Column(
            children: [
              Text(_selectedReportTitle!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A636F))),
              const SizedBox(height: 20),
              Expanded(child: _isPieChart ? _buildPieChart() : _buildBarChart()),
            ],
          ),
    );
  }

  Widget _buildPieChart() {
    final filtered = _accounts.where((a) => _selectedAccountIds.contains(a.id)).toList();
    if (filtered.isEmpty) return const Center(child: Text('No accounts selected'));
    return PieChart(PieChartData(
      sectionsSpace: 2, 
      centerSpaceRadius: 40, 
      sections: filtered.map((acc) {
        final double value = ((acc.amount?.value ?? 0) / 100).abs().toDouble();
        return PieChartSectionData(
          color: _getPaletteColor(_accounts.indexOf(acc)), 
          value: value > 0 ? value : 0.01, // Evitar valores cero que rompen el gráfico
          title: '', 
          radius: 50
        );
      }).toList()
    ));
  }

  Widget _buildBarChart() {
    final filtered = _accounts.where((a) => _selectedAccountIds.contains(a.id)).toList();
    if (filtered.isEmpty) return const Center(child: Text('No accounts selected'));
    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround, 
      barGroups: filtered.asMap().entries.map((entry) {
        final double value = ((entry.value.amount?.value ?? 0) / 100).toDouble();
        return BarChartGroupData(
          x: entry.key, 
          barRods: [
            BarChartRodData(
              toY: value, 
              color: AppColors.primaryBlue, 
              width: 16,
              borderRadius: BorderRadius.circular(2)
            )
          ]
        );
      }).toList(), 
      titlesData: const FlTitlesData(show: false)
    ));
  }

  Color _getPaletteColor(int index) {
    List<Color> colors = [const Color(0xFF009FFB), Colors.orange, Colors.green, Colors.purple, Colors.redAccent, Colors.teal];
    return colors[index % colors.length];
  }

  Widget _buildTab(String label, bool isSelected) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 20), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isSelected ? AppColors.primaryBlue : Colors.transparent, width: 3))), alignment: Alignment.center, child: Text(label, style: TextStyle(color: isSelected ? AppColors.primaryBlue : AppColors.secondaryText, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 11)));
  }

  Widget _buildReportItem(String title, String subtitle, IconData icon) {
    bool isSelected = _selectedReportTitle == title;
    return InkWell(
      onTap: () => setState(() => _selectedReportTitle = title),
      child: Container(decoration: BoxDecoration(color: isSelected ? AppColors.primaryBlue.withOpacity(0.05) : Colors.transparent, border: const Border(bottom: BorderSide(color: Color(0xFFF0F0F0)))), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [Icon(icon, color: isSelected ? AppColors.primaryBlue : const Color(0xFF4A636F), size: 24), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: const Color(0xFF4A636F))), Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey))]))])),
    );
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
