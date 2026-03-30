import 'package:flutter/material.dart';
import '../../../domain/models/transaction_item.dart';

class TransactionListItem extends StatelessWidget {
  final TransactionItem transaction;

  const TransactionListItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isNegative = transaction.amount.isNegative;
    
    return Container(
      height: 66,
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Indicador lateral (viewCleared en original)
                Container(
                  width: 6,
                  height: double.infinity,
                  color: isNegative ? Colors.red.withOpacity(0.7) : Colors.green.withOpacity(0.7),
                ),
                const SizedBox(width: 10),
                // Nombre y Categoría/Etiquetas
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4A636F),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Text(
                            'General', // Por ahora genérico hasta migrar categorías
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 4),
                          ...transaction.tags.take(2).map((tag) => Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A636F).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(fontSize: 10, color: Color(0xFF4A636F)),
                            ),
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
                // Valor y Fecha
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isNegative ? '-' : ''}\$${(transaction.amount.value / 100).abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isNegative ? Colors.red.shade700 : Colors.green.shade700,
                        ),
                      ),
                      Text(
                        transaction.date,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                const SizedBox(width: 4),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }
}
