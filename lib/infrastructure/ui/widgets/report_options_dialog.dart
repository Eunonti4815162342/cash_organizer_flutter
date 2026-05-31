import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../styles/app_styles.dart';
import '../../../domain/models/account_item.dart';
import '../../../domain/models/financial_entity.dart';
import '../../../services/api_service.dart';

class ReportConfig {
  final DateTime startDate;
  final DateTime endDate;
  final List<String> accountIds;
  final String reportType;

  ReportConfig({
    required this.startDate,
    required this.endDate,
    required this.accountIds,
    required this.reportType,
  });
}

class ReportOptionsDialog extends StatefulWidget {
  final String title;
  final ReportConfig initialConfig;

  const ReportOptionsDialog({
    super.key, 
    required this.title, 
    required this.initialConfig
  });

  @override
  State<ReportOptionsDialog> createState() => _ReportOptionsDialogState();
}

class _ReportOptionsDialogState extends State<ReportOptionsDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  late List<String> _selectedAccountIds;
  
  List<FinancialEntity> _entities = [];
  List<AccountItem> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialConfig.startDate;
    _endDate = widget.initialConfig.endDate;
    _selectedAccountIds = List.from(widget.initialConfig.accountIds);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final api = GetIt.instance.get<ApiService>();
    try {
      final ents = await api.fetchEntities();
      final accs = await api.fetchAccounts();
      if (mounted) {
        setState(() {
          _entities = ents;
          _accounts = accs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune, color: AppColors.primaryBlue),
                    const SizedBox(width: 12),
                    Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: [
                      _buildSectionTitle('PERIODO'),
                      ListTile(
                        leading: const Icon(Icons.calendar_month_outlined, size: 20),
                        title: const Text('Rango de fechas'),
                        subtitle: Text('${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}'),
                        onTap: _selectDateRange,
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('FILTRAR POR EMPRESA / CUENTA'),
                      ..._entities.map((entity) => _buildEntityFilter(entity)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('CANCELAR',
                            style: TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, ReportConfig(
                            startDate: _startDate,
                            endDate: _endDate,
                            accountIds: _selectedAccountIds,
                            reportType: widget.initialConfig.reportType,
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('APLICAR FILTROS',
                            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryBlue, letterSpacing: 1.1)),
    );
  }

  Widget _buildEntityFilter(FinancialEntity entity) {
    final entityAccounts = _accounts.where((a) => a.entity?.id == entity.id).toList();
    if (entityAccounts.isEmpty) return const SizedBox.shrink();

    bool allSelected = entityAccounts.every((a) => _selectedAccountIds.contains(a.id.toString()));
    bool someSelected = entityAccounts.any((a) => _selectedAccountIds.contains(a.id.toString())) && !allSelected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          value: allSelected,
          tristate: someSelected,
          title: Text(entity.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          secondary: Icon(entity.type == EntityType.LEGAL ? Icons.business : Icons.person, color: Colors.grey, size: 20),
          activeColor: AppColors.primaryBlue,
          onChanged: (val) {
            setState(() {
              if (val == true) {
                for (var a in entityAccounts) {
                  if (!_selectedAccountIds.contains(a.id.toString())) _selectedAccountIds.add(a.id.toString());
                }
              } else {
                for (var a in entityAccounts) {
                  _selectedAccountIds.remove(a.id.toString());
                }
              }
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.only(left: 48),
          child: Column(
            children: entityAccounts.map((acc) => CheckboxListTile(
              value: _selectedAccountIds.contains(acc.id.toString()),
              title: Text(acc.name, style: const TextStyle(fontSize: 13)),
              dense: true,
              activeColor: AppColors.primaryBlue,
              onChanged: (val) {
                setState(() {
                  val == true ? _selectedAccountIds.add(acc.id.toString()) : _selectedAccountIds.remove(acc.id.toString());
                });
              },
            )).toList(),
          ),
        ),
      ],
    );
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
    }
  }
}
