import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import '../styles/app_styles.dart';
import '../providers/dashboard_provider.dart';
import '../../../domain/models/account_item.dart';
import '../../../l10n/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DashboardProvider _provider;

  @override
  void initState() {
    super.initState();
    final getIt = GetIt.instance;
    _provider = DashboardProvider(
      getIt.get(),
      getIt.get(),
      getIt.get(),
    );
    _provider.loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          final l10n = AppLocalizations.of(context)!;
          final isMobile = MediaQuery.of(context).size.width < 800;

          if (provider.isLoading) return const Center(child: CircularProgressIndicator());

          return Container(
            color: const Color(0xFFF5F5F5),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  isMobile
                      ? Column(
                          children: [
                            _buildFilterBox(l10n.accounts.toUpperCase(), _buildAccountDropdown(l10n, provider)),
                            const SizedBox(height: 12),
                            _buildFilterBox(l10n.period.toUpperCase(), _buildPeriodSelector(provider)),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: _buildFilterBox(l10n.accounts.toUpperCase(), _buildAccountDropdown(l10n, provider))),
                            const SizedBox(width: 16),
                            Expanded(child: _buildFilterBox(l10n.period.toUpperCase(), _buildPeriodSelector(provider))),
                          ],
                        ),
                  const SizedBox(height: 16),
                  _buildBalanceSection(l10n, provider),
                  const SizedBox(height: 16),
                  _buildCategoriesSection(l10n, isMobile, provider),
                ],
              ),
            ),
          );
        },
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

  Widget _buildAccountDropdown(AppLocalizations l10n, DashboardProvider provider) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<AccountItem?>(
        value: provider.selectedAccount,
        isDense: true,
        isExpanded: true,
        items: [
          DropdownMenuItem(value: null, child: Text(l10n.allAccounts, style: const TextStyle(fontSize: 13))),
          ...provider.accounts.map((a) => DropdownMenuItem(value: a, child: Text(a.name, style: const TextStyle(fontSize: 13)))),
        ],
        onChanged: (val) => provider.selectAccount(val),
      ),
    );
  }

  Widget _buildPeriodSelector(DashboardProvider provider) {
    return InkWell(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          initialDateRange: DateTimeRange(start: provider.startDate, end: provider.endDate),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
        if (picked != null) {
          await provider.setDateRange(picked.start, DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59));
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${provider.startDate.day}/${provider.startDate.month}/${provider.startDate.year} - ${provider.endDate.day}/${provider.endDate.month}/${provider.endDate.year}',
            style: const TextStyle(fontSize: 13),
          ),
          const Icon(Icons.calendar_today, size: 14, color: AppColors.secondaryText),
        ],
      ),
    );
  }

  Widget _buildBalanceSection(AppLocalizations l10n, DashboardProvider provider) {
    double netWorth = provider.accounts.fold(0, (sum, a) => sum + ((a.amount?.value ?? 0) / 100));
    return _buildSectionCard(
      title: l10n.balanceSummary.toUpperCase(),
      child: Column(
        children: [
          _buildBalanceRow(l10n.netWorth, netWorth, isBold: true),
          const Divider(),
          ...provider.accounts.map((a) => _buildBalanceRow(a.name, (a.amount?.value ?? 0) / 100)),
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

  Widget _buildCategoriesSection(AppLocalizations l10n, bool isMobile, DashboardProvider provider) {
    return Column(
      children: [
        _buildViewModeSelector(l10n, provider),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: l10n.categoriesAnalysis.toUpperCase(),
          child: Column(
            children: [
              isMobile
                  ? Column(
                      children: [
                        SizedBox(height: 250, child: _buildPieChartComponent(l10n, provider)),
                        const SizedBox(height: 32),
                        _buildCategoryTable(l10n, provider),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: SizedBox(height: 280, child: _buildPieChartComponent(l10n, provider))),
                        const SizedBox(width: 32),
                        Expanded(flex: 6, child: _buildCategoryTable(l10n, provider)),
                      ],
                    ),
              const Divider(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${l10n.totalBalance}: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  Text('€ ${provider.totalCategoryAmount.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: provider.categoryMode == 'EXPENSE' ? AppColors.expenseRed : AppColors.incomeGreen)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPieChartComponent(AppLocalizations l10n, DashboardProvider provider) {
    if (provider.categoryData.isEmpty) return Center(child: Text(l10n.noData));
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
              provider.setTouchedIndex(-1);
              return;
            }
            provider.setTouchedIndex(pieTouchResponse.touchedSection!.touchedSectionIndex);
          },
        ),
        sectionsSpace: 4,
        centerSpaceRadius: 50,
        sections: _buildChartSections(provider),
      ),
    );
  }

  Widget _buildViewModeSelector(AppLocalizations l10n, DashboardProvider provider) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12)),
      child: Row(
        children: [
          _buildModeTab('EXPENSE', l10n.expense.toUpperCase(), AppColors.expenseRed, provider),
          _buildModeTab('INCOME', l10n.income.toUpperCase(), AppColors.incomeGreen, provider),
        ],
      ),
    );
  }

  Widget _buildModeTab(String mode, String label, Color color, DashboardProvider provider) {
    bool isSelected = provider.categoryMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => provider.setCategoryMode(mode),
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

  Widget _buildCategoryTable(AppLocalizations l10n, DashboardProvider provider) {
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
        ...provider.categoryData.entries.toList().asMap().entries.map((entry) {
          final isTouched = entry.key == provider.touchedIndex;
          final name = entry.value.key;
          final value = entry.value.value;
          final percent = (provider.totalCategoryAmount > 0) ? (value / provider.totalCategoryAmount) * 100 : 0.0;
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

  List<PieChartSectionData> _buildChartSections(DashboardProvider provider) {
    int i = 0;
    return provider.categoryData.entries.map((e) {
      final isTouched = i == provider.touchedIndex;
      final radius = isTouched ? 70.0 : 60.0;
      final color = _getPaletteColor(i++);

      return PieChartSectionData(
        color: color,
        value: e.value,
        title: isTouched ? '${((e.value / provider.totalCategoryAmount) * 100).toStringAsFixed(0)}%' : '',
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
