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
  final ScrollController _scrollController = ScrollController();

  List<TransactionItem> _transactions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isLastPage = false;
  int _currentPage = 0;
  final int _pageSize = 20;

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
    
    _scrollController.addListener(_onScroll);
    _loadEntities();
    _refreshTransactions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && !_isLastPage) {
        _loadMoreTransactions();
      }
    }
  }

  Future<void> _loadEntities() async {
    try {
      final ents = await _entityRepo.fetchEntities();
      if (mounted) setState(() => _entities = ents);
    } catch (_) {}
  }

  Future<void> _refreshTransactions() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _isLastPage = false;
      _transactions = [];
    });

    await _fetchPage(0);
  }

  Future<void> _loadMoreTransactions() async {
    setState(() => _isLoadingMore = true);
    await _fetchPage(_currentPage + 1);
  }

  Future<void> _fetchPage(int page) async {
    try {
      // Usamos formato YYYY-MM-DD para compatibilidad con el backend
      String formatDate(DateTime d) => "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

      final newTransactions = await _transactionRepo.fetchTransactions(
        TransactionFilters(
          startDate: formatDate(_startDate),
          endDate: formatDate(_endDate),
          page: page,
          size: _pageSize,
        )
      );

      if (mounted) {
        setState(() {
          _currentPage = page;
          if (newTransactions.length < _pageSize) {
            _isLastPage = true;
          }
          _transactions.addAll(newTransactions);
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al cargar movimientos')));
      }
    }
  }

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
    _refreshTransactions();
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
    
    final filteredTransactions = _transactions.where((tx) {
      if (_selectedEntity != null && tx.account.entity?.id != _selectedEntity!.id) return false;
      final query = _searchQuery.toLowerCase();
      if (query.isEmpty) return true;
      return tx.description.toLowerCase().contains(query) || (tx.category?.name ?? '').toLowerCase().contains(query) || (tx.beneficiary?.name ?? '').toLowerCase().contains(query) || tx.account.name.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.windowBackground,
      body: Column(
        children: [
          _buildHeader(l10n),
          _buildFilters(),
          Expanded(
            child: _isLoading 
              ? const SkeletonTransactionList(itemCount: 8)
              : filteredTransactions.isEmpty && !_isLoadingMore
                ? EmptyStateWidget(icon: Icons.receipt_long_outlined, title: l10n.noData, subtitle: 'No se encontraron resultados')
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: filteredTransactions.length + (_isLastPage ? 0 : 1),
                    itemBuilder: (context, index) {
                      if (index < filteredTransactions.length) {
                        return TransactionListItem(transaction: filteredTransactions[index], onRefresh: _refreshTransactions);
                      } else {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
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

  Widget _buildPopupItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryBlue),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
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
