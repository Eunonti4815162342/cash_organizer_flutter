import 'package:flutter/material.dart';
import '../../../domain/models/account_item.dart';

class OverviewCard extends StatelessWidget {
  final String title;
  final String totalValue;
  final List<AccountItem> accounts;
  final VoidCallback? onTap;

  const OverviewCard({
    super.key,
    required this.title,
    required this.totalValue,
    required this.accounts,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: Colors.grey.shade300, width: 0.5),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header del card (basado en accounts_overview.xml)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A636F), // overview_header_color
                      ),
                    ),
                    Text(
                      totalValue,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF009FFB),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              // Lista de cuentas reducida para el overview
              ...accounts.take(3).map((account) => _buildAccountRow(account)),
              if (accounts.length > 3)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Center(
                    child: Text(
                      'Ver todas...',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountRow(AccountItem account) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              account.name,
              style: const TextStyle(color: Color(0xFF4A636F)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '\$${(account.amount.value / 100).toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF4A636F),
            ),
          ),
        ],
      ),
    );
  }
}
