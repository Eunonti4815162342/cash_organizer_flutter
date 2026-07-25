import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import '../styles/app_styles.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/skeleton_widgets.dart';
import '../widgets/app_components.dart';
import 'account_details_screen.dart';
import '../../../domain/models/financial_entity.dart';
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
    // Shared singleton (see service_locator.dart): other screens refresh
    // this same instance after mutating transactions, so the Dashboard
    // stays current even when it isn't the active route.
    _provider = GetIt.instance.get<DashboardProvider>();
    _provider.loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          final l10n = AppLocalizations.of(context)!;
          final isMobile = MediaQuery.of(context).size.width < AppDimens.mobileBreakpoint;

          if (provider.isLoading) return const SkeletonDashboard();

          return Container(
            color: AppColors.windowBackground,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.sectionLabel),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _buildAccountDropdown(AppLocalizations l10n, DashboardProvider provider) {
    final label = provider.allAccountsSelected
        ? l10n.allAccounts
        : '${provider.selectedAccountIds.length} ${l10n.accounts.toLowerCase()}';
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showAccountPicker(l10n, provider),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
          const Icon(Icons.unfold_more, size: 16, color: AppColors.primaryBlue),
        ],
      ),
    );
  }

  void _showAccountPicker(AppLocalizations l10n, DashboardProvider provider) {
    final accounts = provider.accounts;
    final entityMap = <int, FinancialEntity>{};
    for (final a in accounts) {
      if (a.entity != null) entityMap[a.entity!.id] = a.entity!;
    }
    final entities = entityMap.values.toList();
    final orphans = accounts.where((a) => a.entity == null).toList();

    List<int> tempSelected = List.from(provider.selectedAccountIds);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setPickerState) {
          final allSelected = tempSelected.length == accounts.length;
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            builder: (context, scrollController) => Column(
              children: [
                Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                // "Seleccionar todas" toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CheckboxListTile(
                    value: allSelected,
                    tristate: true,
                    onChanged: (v) => setPickerState(() {
                      tempSelected = (v == true)
                          ? accounts.map((a) => a.id).toList()
                          : [];
                    }),
                    title: Text(l10n.allAccounts, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    activeColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const Divider(height: 1),
                // Lista agrupada por entidad
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      ...entities.map((entity) {
                        final entityAccounts = accounts.where((a) => a.entity?.id == entity.id).toList();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              child: Row(
                                children: [
                                  Icon(entity.type == EntityType.LEGAL ? Icons.business : Icons.person, size: 14, color: AppColors.primaryBlue),
                                  const SizedBox(width: 6),
                                  Text(entity.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryBlue, letterSpacing: 1.1)),
                                ],
                              ),
                            ),
                            ...entityAccounts.map((acc) => CheckboxListTile(
                              value: tempSelected.contains(acc.id),
                              onChanged: (v) => setPickerState(() {
                                v! ? tempSelected.add(acc.id) : tempSelected.remove(acc.id);
                              }),
                              title: Text(acc.name, style: const TextStyle(fontSize: 14)),
                              subtitle: Text('€ ${(acc.amount.value / 100).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              activeColor: AppColors.primaryBlue,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            )),
                            const SizedBox(height: 4),
                          ],
                        );
                      }),
                      if (orphans.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          child: Text('INDIVIDUAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
                        ),
                        ...orphans.map((acc) => CheckboxListTile(
                          value: tempSelected.contains(acc.id),
                          onChanged: (v) => setPickerState(() {
                            v! ? tempSelected.add(acc.id) : tempSelected.remove(acc.id);
                          }),
                          title: Text(acc.name, style: const TextStyle(fontSize: 14)),
                          subtitle: Text('€ ${(acc.amount.value / 100).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          activeColor: AppColors.primaryBlue,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        )),
                      ],
                    ],
                  ),
                ),
                // Botón aplicar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: AppButton(
                    label: 'Aplicar',
                    onPressed: () {
                      provider.setSelectedAccounts(tempSelected);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          );
        },
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
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const Icon(Icons.calendar_today, size: 14, color: AppColors.primaryBlue),
        ],
      ),
    );
  }

  Widget _buildBalanceSection(AppLocalizations l10n, DashboardProvider provider) {
    final selected = provider.selectedAccounts;
    final netWorth = selected.fold(0.0, (sum, a) => sum + (a.amount.value / 100));
    return AppCard(
      title: l10n.balanceSummary,
      child: Column(
        children: [
          _buildBalanceRow(l10n.netWorth, netWorth, isBold: true, onTap: null),
          const Divider(),
          ...selected.map((a) => _buildBalanceRow(a.name, a.amount.value / 100, onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => AccountDetailsScreen(account: a)));
          })),
        ],
      ),
    );
  }

  Widget _buildBalanceRow(String label, double val, {bool isBold = false, VoidCallback? onTap}) {
    final color = val < 0 ? AppColors.expenseRed : (isBold ? AppColors.primaryBlue : AppColors.incomeGreen);
    
    Widget content = Padding(
      padding: EdgeInsets.symmetric(vertical: isBold ? 14 : 7, horizontal: isBold ? 16 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? color : AppColors.primaryText)),
          Text('€ ${val.toStringAsFixed(2)}', style: TextStyle(fontSize: isBold ? 18 : 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: isBold 
        ? Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(14)),
            child: content,
          )
        : content,
    );
  }

  Widget _buildCategoriesSection(AppLocalizations l10n, bool isMobile, DashboardProvider provider) {
    return Column(
      children: [
        _buildViewModeSelector(l10n, provider),
        const SizedBox(height: 12),
        AppCard(
          title: l10n.categoriesAnalysis,
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
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildModeTab('EXPENSE', l10n.expense, AppColors.expenseRed, provider),
          _buildModeTab('INCOME', l10n.income, AppColors.incomeGreen, provider),
        ],
      ),
    );
  }

  Widget _buildModeTab(String mode, String label, Color color, DashboardProvider provider) {
    final isSelected = provider.categoryMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setCategoryMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
          ),
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade500,
                fontSize: 12,
                letterSpacing: 0.8,
              ),
            ),
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
            Expanded(flex: 4, child: Text(l10n.categoryName.toUpperCase(), style: AppTextStyles.tableHeader.copyWith(fontWeight: FontWeight.bold))),
            const Expanded(flex: 2, child: Text('%', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
            Expanded(flex: 3, child: Text(l10n.amount.toUpperCase(), textAlign: TextAlign.right, style: AppTextStyles.tableHeader.copyWith(fontWeight: FontWeight.bold))),
          ],
        ),
        const Divider(),
        ...provider.categoryData.entries.toList().asMap().entries.map<Widget>((entry) {
          final isTouched = entry.key == provider.touchedIndex;
          final name = entry.value.key;
          final value = entry.value.value;
          final percent = (provider.totalCategoryAmount > 0) ? (value / provider.totalCategoryAmount) * 100 : 0.0;
          final color = _getPaletteColor(entry.key);

          return Container(
            color: isTouched ? color.withValues(alpha: 0.05) : Colors.transparent,
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
        }),
      ],
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
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.white),
      );
    }).toList();
  }

  Color _getPaletteColor(int index) {
    return AppColors.chartPalette[index % AppColors.chartPalette.length];
  }
}
