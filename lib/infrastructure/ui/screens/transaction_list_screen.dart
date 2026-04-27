import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../domain/models/transaction_item.dart';
import '../../../domain/models/financial_entity.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../../../services/api_service.dart';
import '../../../l10n/app_localizations.dart';
import '../styles/app_styles.dart';
import 'transaction_form_screen.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/skeleton_widgets.dart';
import '../widgets/ui_helpers.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final ITransactionRepository _transactionRepo = GetIt.instance.get<ITransactionRepository>();
  final ApiService _apiService = GetIt.instance.get<ApiService>();

  late Future<List<TransactionItem>> _transactionsFuture;
  List<FinancialEntity> _entities = [];
  FinancialEntity? _selectedEntity;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadEntities();
    _refreshTransactions();
  }

  Future<void> _loadEntities() async {
    try {
      final ents = await _apiService.fetchEntities();
      if (mounted) setState(() => _entities = ents);
    } catch (_) {}
  }

  void _refreshTransactions() {
    setState(() {
      _transactionsFuture = _transactionRepo.fetchTransactions(
        // Si hay empresa seleccionada, el backend filtrará por las cuentas de esa empresa
        // Para simplificar, traemos todas y filtramos localmente o pasamos los accountIds
        startDate: DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        endDate: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      );
    });
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SkeletonTransactionList(itemCount: 8);
                }
                if (snapshot.hasError) {
                  return ErrorStateWidget(message: 'Error al cargar transacciones', onRetry: _refreshTransactions);
                }

                final allTransactions = snapshot.data ?? [];
                
                // FILTRADO COMBINADO: Empresa + Búsqueda
                final filteredTransactions = allTransactions.where((tx) {
                  // Filtro por Empresa
                  if (_selectedEntity != null) {
                    if (tx.account.entity?.id != _selectedEntity!.id) return false;
                  }

                  // Filtro por Texto
                  final query = _searchQuery.toLowerCase();
                  if (query.isEmpty) return true;

                  final desc = tx.description.toLowerCase();
                  final cat = (tx.category?.name ?? '').toLowerCase();
                  final ben = (tx.beneficiary?.name ?? '').toLowerCase();
                  final acc = tx.account.name.toLowerCase();

                  return desc.contains(query) || cat.contains(query) || ben.contains(query) || acc.contains(query);
                }).toList();

                if (filteredTransactions.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.receipt_long_outlined,
                    title: l10n.noData,
                    subtitle: _searchQuery.isEmpty && _selectedEntity == null 
                        ? 'No hay movimientos en los últimos 30 días' 
                        : 'No se encontraron resultados para los filtros aplicados',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) => TransactionListItem(
                    transaction: filteredTransactions[index],
                    onRefresh: _refreshTransactions,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TransactionFormScreen()),
          );
          if (result == true) {
            _refreshTransactions();
          }
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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: l10n.search,
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryBlue),
            onPressed: _refreshTransactions,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 50,
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Opción "TODAS"
          _buildFilterChip(
            label: 'TODAS',
            isSelected: _selectedEntity == null,
            onSelected: (_) => setState(() => _selectedEntity = null),
          ),
          const SizedBox(width: 8),
          // Lista de Empresas
          ..._entities.map((entity) => Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _buildFilterChip(
              label: entity.name.toUpperCase(),
              isSelected: _selectedEntity?.id == entity.id,
              onSelected: (_) => setState(() => _selectedEntity = entity),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required bool isSelected, required Function(bool) onSelected}) {
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.secondaryText)),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppColors.primaryBlue,
      checkmarkColor: Colors.white,
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppColors.primaryBlue : Colors.transparent)),
      visualDensity: VisualDensity.compact,
    );
  }
}
