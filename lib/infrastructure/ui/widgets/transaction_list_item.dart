import 'package:flutter/material.dart';
import '../../../domain/models/transaction_item.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/api_service.dart';
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        elevation: 0,
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade100),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => TransactionFormScreen(transaction: transaction)),
            ).then((saved) { if (saved == true && onRefresh != null) onRefresh!(); });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Row(
              children: [
                // Indicador lateral redondeado
                Container(
                  width: 4,
                  height: 44,
                  margin: const EdgeInsets.only(left: 8, right: 12),
                  decoration: BoxDecoration(
                    color: indicatorColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Nombre y Categoría
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.type == TransactionType.TRANSFER
                            ? 'Transfer · ${transaction.account.name} → ${transaction.toAccount?.name ?? '???'}'
                            : '${transaction.beneficiary?.name ?? (transaction.category?.name ?? 'General')}${transaction.description.isNotEmpty ? ' · ${transaction.description}' : ''}',
                        style: AppTextStyles.listItemTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            transaction.type == TransactionType.TRANSFER ? 'Movimiento interno' : transaction.account.name,
                            style: AppTextStyles.listItemSubtitle,
                          ),
                          if (transaction.tags.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            ...transaction.tags.take(2).map((tag) => Container(
                              margin: const EdgeInsets.only(right: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: indicatorColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(tag, style: TextStyle(fontSize: 10, color: indicatorColor)),
                            )),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Valor y Fecha
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isNegative ? '-' : '+'}€${(transaction.amount.value / 100).abs().toStringAsFixed(2)}',
                      style: AppTextStyles.amountText.copyWith(color: textColor),
                    ),
                    const SizedBox(height: 3),
                    Text(transaction.date.split('T')[0], style: AppTextStyles.dateSmall),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.grey.shade300, size: 18),
                  onPressed: () => _confirmDelete(context),
                  tooltip: 'Delete',
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
    final ApiService apiService = ApiService();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTransaction),
        content: Text(l10n.confirmDeleteTransactionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel.toUpperCase()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await apiService.deleteTransaction(transaction.id);
              if (success && onRefresh != null) {
                onRefresh!();
              }
            },
            child: Text(l10n.delete.toUpperCase(), style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
