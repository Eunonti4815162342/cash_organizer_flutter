import 'package:flutter/material.dart';
import '../../../domain/models/account_item.dart';

class AccountDetailsScreen extends StatelessWidget {
  final AccountItem account;

  const AccountDetailsScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Cuenta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen de saldo superior
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
              color: const Color(0xFF009FFB),
              child: Column(
                children: [
                  Text(
                    account.name,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${(account.amount.value / 100).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    account.amount.currency,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Sección de detalles (Imitando activity_account_edit.xml)
            const SizedBox(height: 20),
            _buildDetailItem('NOMBRE', account.name),
            _buildDivider(),
            _buildDetailItem('TIPO', account.accountType ?? 'General'),
            _buildDivider(),
            _buildDetailItem('MONEDA', account.amount.currency),
            _buildDivider(),
            _buildDetailItem('NOTAS', account.notes ?? 'Sin notas adicionales'),
            _buildDivider(),
            
            // Sección de estados (Switches imitando el original)
            const SizedBox(height: 20),
            _buildSwitchItem('ABIERTA', true),
            _buildDivider(),
            _buildSwitchItem('INCLUIR EN BALANCE TOTAL', true),
            _buildDivider(),
            
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Las transacciones de esta cuenta se incluyen en los informes y presupuestos por defecto.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF009FFB),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF4A636F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchItem(String label, bool value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4A636F),
            ),
          ),
          Switch(
            value: value,
            onChanged: (val) {},
            activeColor: const Color(0xFF009FFB),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 16,
      color: Color(0xFFEEEEEE),
    );
  }
}
