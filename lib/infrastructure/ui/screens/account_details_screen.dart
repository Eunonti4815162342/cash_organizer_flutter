import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../domain/models/account_item.dart';
import '../../../domain/models/transaction_item.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../styles/app_styles.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/skeleton_widgets.dart';
import '../widgets/ui_helpers.dart';

class AccountDetailsScreen extends StatefulWidget {
  final AccountItem account;

  const AccountDetailsScreen({super.key, required this.account});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  late Future<List<TransactionItem>> _transactionsFuture;
  final ITransactionRepository _transactionRepo = GetIt.instance.get<ITransactionRepository>();

  @override
  void initState() {
    super.initState();
    _refreshTransactions();
  }

  void _refreshTransactions() {
    setState(() {
      _transactionsFuture = _transactionRepo.fetchTransactions(
        accountId: widget.account.id.toString(),
        // Traemos los últimos 3 meses por defecto para esta vista de detalle
        startDate: DateTime.now().subtract(const Duration(days: 90)).toIso8601String(),
        endDate: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.account.amount.value / 100;
    final isNegative = balance < 0 || widget.account.amount.isNegative;

    return Scaffold(
      backgroundColor: AppColors.windowBackground,
      appBar: AppBar(
        title: Text(widget.account.name),
        elevation: 0,
        backgroundColor: isNegative ? AppColors.expenseRed : AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header con saldo (NATAVE Style)
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
                  widget.account.accountType?.toUpperCase() ?? 'GENERAL ACCOUNT',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                Text(
                  '€ ${balance.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold),
                ),
                if (widget.account.entity != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(widget.account.entity!.name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                ],
              ],
            ),
          ),

          // Título sección
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('MOVIMIENTOS RECIENTES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
                IconButton(icon: const Icon(Icons.refresh, size: 18, color: Colors.grey), onPressed: _refreshTransactions),
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
                final txs = snapshot.data ?? [];
                if (txs.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.receipt_long_outlined,
                    title: 'Sin movimientos',
                    subtitle: 'No hay transacciones registradas en esta cuenta en los últimos 90 días',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: txs.length,
                  itemBuilder: (context, index) => TransactionListItem(
                    transaction: txs[index],
                    onRefresh: _refreshTransactions,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
