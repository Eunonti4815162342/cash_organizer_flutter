import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../domain/models/transaction_item.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/dashboard_provider.dart';
import '../screens/transaction_form_screen.dart';
import '../styles/app_styles.dart';

class TransactionListItem extends StatelessWidget {
  final TransactionItem transaction;
  final VoidCallback? onRefresh;

  const TransactionListItem({super.key, required this.transaction, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isNegative = transaction.amount.isNegative || transaction.type == TransactionType.EXPENSE;
    final isIncome = transaction.type == TransactionType.INCOME;
    final isTransfer = transaction.type == TransactionType.TRANSFER;

    Color indicatorColor = Colors.grey;
    if (isIncome) indicatorColor = Colors.green.withValues(alpha: 0.7);
    if (isNegative && !isTransfer) indicatorColor = Colors.red.withValues(alpha: 0.7);
    if (isTransfer) indicatorColor = AppColors.primaryBlue.withValues(alpha: 0.7);

    Color textColor = Colors.grey;
    if (isIncome) textColor = Colors.green.shade700;
    if (isNegative && !isTransfer) textColor = Colors.red.shade700;
    if (isTransfer) textColor = AppColors.primaryText;

    String mainTitle = transaction.category?.name ?? 'General';
    if (transaction.subcategory != null) mainTitle += ' > ${transaction.subcategory!.name}';
    
    List<String> subParts = [];
    if (transaction.beneficiary != null) subParts.add(transaction.beneficiary!.name);
    subParts.add(transaction.account.name);
    String subTitle = subParts.join(' · ');

    if (isTransfer) {
      mainTitle = 'Transferencia';
      subTitle = '${transaction.account.name} → ${transaction.toAccount?.name ?? '???'}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        elevation: 0,
        color: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade100)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => TransactionFormScreen(transaction: transaction)))
            .then((saved) { if (saved == true && onRefresh != null) onRefresh!(); });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Row(
              children: [
                Container(width: 4, height: 44, margin: const EdgeInsets.only(left: 8, right: 12), decoration: BoxDecoration(color: indicatorColor, borderRadius: BorderRadius.circular(4))),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mainTitle, style: AppTextStyles.listItemTitle.copyWith(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(subTitle, style: AppTextStyles.listItemSubtitle.copyWith(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${isNegative ? '-' : '+'}€${(transaction.amount.value / 100).abs().toStringAsFixed(2)}', style: AppTextStyles.amountText.copyWith(color: textColor, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(transaction.date.split('T')[0], style: AppTextStyles.dateSmall),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.grey.shade300, size: 18),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // USAMOS EL REPOSITORIO UNIFICADO (getIt)
    final repo = GetIt.instance.get<ITransactionRepository>();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTransaction),
        content: Text(l10n.confirmDeleteTransactionBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel.toUpperCase())),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // EL AWAIT AQUÍ ES CLAVE: Esperamos a que SQLite borre localmente
              await repo.deleteTransaction(transaction.id);
              // Refrescamos esta lista y el Dashboard (singleton compartido,
              // no depende de que el Dashboard esté montado en este momento)
              GetIt.instance.get<DashboardProvider>().refreshBalances();
              if (onRefresh != null) onRefresh!();
            },
            child: Text(l10n.delete.toUpperCase(), style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
