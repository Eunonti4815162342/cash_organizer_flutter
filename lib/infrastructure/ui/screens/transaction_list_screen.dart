import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:natave_flutter/domain/models/transaction_item.dart';
import 'package:natave_flutter/domain/models/transaction_filters.dart';
import 'package:natave_flutter/domain/models/financial_entity.dart';
import 'package:natave_flutter/domain/repositories/transaction_repository.dart';
import 'package:natave_flutter/domain/repositories/entity_repository.dart';
import 'package:natave_flutter/l10n/app_localizations.dart';
import 'package:natave_flutter/infrastructure/ui/styles/app_styles.dart';
import 'package:natave_flutter/infrastructure/ui/screens/transaction_form_screen.dart';
import 'package:natave_flutter/infrastructure/ui/widgets/transaction_list_item.dart';
import 'package:natave_flutter/infrastructure/ui/widgets/skeleton_widgets.dart';
import 'package:natave_flutter/infrastructure/ui/widgets/ui_helpers.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final ITransactionRepository _transactionRepo = GetIt.instance.get<ITransactionRepository>();
  final IEntityRepository _entityRepo = GetIt.instance.get<IEntityRepository>();

  late Future<List<TransactionItem>> _transactionsFuture;
  List<FinancialEntity> _entities = [];
  FinancialEntity? _selectedEntity;
  String _searchQuery = '';
  
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
    
    _loadEntities();
    _refreshTransactions();
  }

  Future<void> _loadEntities() async {
    try {
      final ents = await _entityRepo.fetchEntities();
      if (mounted) setState(() => _entities = ents);
    } catch (_) {}
  }

  void _refreshTransactions() {
    setState(() {
      _transactionsFuture = _transactionRepo.fetchTransactions(
        TransactionFilters(
          startDate: _startDate.toIso8601String(),
          endDate: _endDate.add(const Duration(days: 1)).toIso8601String(),
        )
      );
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primaryBlue, onPrimary: Colors.white, onSurface: AppColors.primaryText),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() { _startDate = picked.start; _endDate = picked.end; });
      _refreshTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.windowBackground,
      body: Column(
        children: [
          _buildHeader(l10n),
          _buildFilters(),
          Expanded(
            child: FutureBuilder<List<TransactionItem>>(
              future: _transactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const SkeletonTransactionList(itemCount: 8);
                if (snapshot.hasError) return ErrorStateWidget(message: 'Error al cargar transacciones', onRetry: _refreshTransactions);

                final allTransactions = snapshot.data ?? [];
                final filteredTransactions = allTransactions.where((tx) {
                  if (_selectedEntity != null && tx.account.entity?.id != _selectedEntity!.id) return false;
                  final query = _searchQuery.toLowerCase();
                  if (query.isEmpty) return true;
                  return tx.description.toLowerCase().contains(query) || (tx.category?.name ?? '').toLowerCase().contains(query) || (tx.beneficiary?.name ?? '').toLowerCase().contains(query) || tx.account.name.toLowerCase().contains(query);
                }).toList();

                if (filteredTransactions.isEmpty) return EmptyStateWidget(icon: Icons.receipt_long_outlined, title: l10n.noData, subtitle: 'No se encontraron resultados');

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) => TransactionListItem(transaction: filteredTransactions[index], onRefresh: _refreshTransactions),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionFormScreen()));
          if (result == true) _refreshTransactions();
        },
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: l10n.search,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true, fillColor: Colors.grey.shade100,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(icon: const Icon(Icons.refresh, color: AppColors.primaryBlue), onPressed: _refreshTransactions),
            ],
          ),
          const SizedBox(height: 8),
          _buildDateRangeButton(),
        ],
      ),
    );
  }

  Widget _buildDateRangeButton() {
    return InkWell(
      onTap: _selectDateRange,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Text('${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.primaryBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 50, width: double.infinity, color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(label: 'TODAS', isSelected: _selectedEntity == null, onSelected: (_) => setState(() => _selectedEntity = null)),
          const SizedBox(width: 8),
          ..._entities.map((entity) => Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _buildFilterChip(label: entity.name.toUpperCase(), isSelected: _selectedEntity?.id == entity.id, onSelected: (_) => setState(() => _selectedEntity = entity)),
          )),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required bool isSelected, required Function(bool) onSelected}) {
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.secondaryText)),
      selected: isSelected, onSelected: onSelected, selectedColor: AppColors.primaryBlue, checkmarkColor: Colors.white, backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppColors.primaryBlue : Colors.transparent)),
      visualDensity: VisualDensity.compact,
    );
  }
}
