import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../domain/models/account_item.dart';
import '../../../domain/models/transaction_item.dart';
import '../../../domain/models/financial_entity.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../styles/app_styles.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/skeleton_widgets.dart';
import '../widgets/ui_helpers.dart';
import 'transaction_form_screen.dart';

class AccountDetailsScreen extends StatefulWidget {
  final AccountItem? account;
  final FinancialEntity? entity;

  const AccountDetailsScreen({super.key, this.account, this.entity});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  late Future<List<TransactionItem>> _transactionsFuture;
  final ITransactionRepository _transactionRepo = GetIt.instance.get<ITransactionRepository>();

  // Filtro de fecha: por defecto el mes actual
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
    
    _refreshTransactions();
  }

  void _refreshTransactions() {
    setState(() {
      _transactionsFuture = _transactionRepo.fetchTransactions(
        accountId: widget.account?.id.toString(),
        startDate: _startDate.toIso8601String(),
        endDate: _endDate.add(const Duration(days: 1)).toIso8601String(),
      );
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        final isNegative = (widget.account?.amount.value ?? 0) < 0;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: isNegative ? AppColors.expenseRed : AppColors.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppColors.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _refreshTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.account?.name ?? widget.entity?.name ?? 'Details';
    final balanceValue = widget.account?.amount.value ?? 0;
    final double balanceDouble = balanceValue / 100;
    final isNegative = balanceDouble < 0;

    return Scaffold(
      backgroundColor: AppColors.windowBackground,
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        backgroundColor: isNegative ? AppColors.expenseRed : AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header con saldo o info de entidad
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
            decoration: BoxDecoration(
              color: isNegative ? AppColors.expenseRed : AppColors.primaryBlue,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Text(
                  widget.account != null ? (widget.account!.accountType?.toUpperCase() ?? 'GENERAL ACCOUNT') : 'ENTITY OVERVIEW',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                if (widget.account != null)
                  Text(
                    '€ ${balanceDouble.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold),
                  )
                else
                  Text(
                    widget.entity?.name ?? 'All Accounts',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                if (widget.account?.entity != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(widget.account!.entity!.name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                ],
              ],
            ),
          ),

          // Sección de Filtros y Título
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('MOVEMENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
                    Row(
                      children: [
                        _buildDateRangeButton(isNegative),
                        IconButton(icon: const Icon(Icons.refresh, size: 18, color: Colors.grey), onPressed: _refreshTransactions),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Listado de transacciones
          Expanded(
            child: FutureBuilder<List<TransactionItem>>(
              future: _transactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SkeletonTransactionList(itemCount: 5);
                }
                if (snapshot.hasError) {
                  return ErrorStateWidget(message: 'Error al cargar movimientos', onRetry: _refreshTransactions);
                }
                final allTxs = snapshot.data ?? [];
                
                List<TransactionItem> filteredTxs = allTxs;
                if (widget.entity != null && widget.account == null) {
                  filteredTxs = allTxs.where((tx) => tx.account.entity?.id == widget.entity!.id).toList();
                }

                if (filteredTxs.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.receipt_long_outlined,
                    title: 'Sin movimientos',
                    subtitle: 'No hay transacciones registradas en este periodo',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: filteredTxs.length,
                  itemBuilder: (context, index) => TransactionListItem(
                    transaction: filteredTxs[index],
                    onRefresh: _refreshTransactions,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.account != null ? FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TransactionFormScreen(initialAccount: widget.account),
            ),
          ).then((value) {
            if (value == true) _refreshTransactions();
          });
        },
        backgroundColor: isNegative ? AppColors.expenseRed : AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildDateRangeButton(bool isNegative) {
    final activeColor = isNegative ? AppColors.expenseRed : AppColors.primaryBlue;
    return InkWell(
      onTap: _selectDateRange,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: activeColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 12, color: activeColor),
            const SizedBox(width: 6),
            Text(
              '${_startDate.day}/${_startDate.month} - ${_endDate.day}/${_endDate.month}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: activeColor),
            ),
          ],
        ),
      ),
    );
  }
}
