import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../../../domain/models/account_item.dart';
import '../../../services/api_service.dart';

class AccountTransactionsScreen extends StatefulWidget {
  const AccountTransactionsScreen({super.key});

  @override
  State<AccountTransactionsScreen> createState() => _AccountTransactionsScreenState();
}

class _AccountTransactionsScreenState extends State<AccountTransactionsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<AccountItem>> _accountsFuture;
  AccountItem? _selectedAccount;

  @override
  void initState() {
    super.initState();
    _accountsFuture = _apiService.fetchAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // TABLA DE CUENTAS
        Expanded(
          flex: 7,
          child: Container(
            color: AppColors.cardBackground,
            child: Column(
              children: [
                // Cabecera de tabla
                Container(
                  height: 35,
                  color: AppColors.tableHeader,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Row(
                    children: [
                      Expanded(child: Text('Nome da conta', style: AppTextStyles.tableHeader)),
                      Text('Saldo Total', style: AppTextStyles.tableHeader),
                      SizedBox(width: 40),
                    ],
                  ),
                ),
                const Divider(height: 1),
                
                // Lista de cuentas
                Expanded(
                  child: FutureBuilder<List<AccountItem>>(
                    future: _accountsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final accounts = snapshot.data ?? [];
                      if (accounts.isEmpty) {
                        return const Center(child: Text('Nenhuma conta encontrada', style: TextStyle(color: AppColors.secondaryText)));
                      }
                      return ListView.builder(
                        itemCount: accounts.length,
                        itemBuilder: (context, index) {
                          final account = accounts[index];
                          return _buildAccountRow(account);
                        },
                      );
                    },
                  ),
                ),
                
                // Footer
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.tableHeader,
                    border: const Border(top: BorderSide(color: Colors.black12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('Saldo Total: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      FutureBuilder<List<AccountItem>>(
                        future: _accountsFuture,
                        builder: (context, snapshot) {
                          final accounts = snapshot.data ?? [];
                          double total = accounts.fold(0, (sum, item) => sum + (item.amount.value / 100));
                          return Text(
                            '€ ${total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          );
                        },
                      ),
                      const Icon(Icons.arrow_drop_down, size: 16),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        
        // PANEL DE PROPIEDADES
        Expanded(
          flex: 3,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.sidebarBackground,
              border: Border(left: BorderSide(color: Colors.black12)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Propriedades da conta', style: TextStyle(fontSize: 16, color: AppColors.secondaryText)),
                    if (_selectedAccount != null)
                      const Icon(Icons.close, size: 18, color: AppColors.secondaryText),
                  ],
                ),
                const SizedBox(height: 30),
                if (_selectedAccount != null) ...[
                  _buildProp('Nome', _selectedAccount!.name, isBold: true),
                  _buildProp('Descrição', _selectedAccount!.description ?? 'N/A', isBold: true),
                  _buildProp('Moeda', _selectedAccount!.amount.currency, isBold: true),
                  _buildProp('Saldo Total', '€ ${(_selectedAccount!.amount.value / 100).toStringAsFixed(2)}', 
                    color: _selectedAccount!.amount.isNegative ? AppColors.expenseRed : AppColors.incomeGreen, isBold: true),
                  _buildProp('Tipo', _selectedAccount!.accountType ?? 'Dinheiro', isBold: true),
                  _buildProp('Situação', _selectedAccount!.isUnbalanced ? 'Desequilibrado' : 'Equilibrado', isBold: true),
                ] else
                  const Center(child: Text('Selecione uma conta para ver detalhes', style: TextStyle(color: AppColors.secondaryText, fontSize: 12))),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, elevation: 0),
                    child: const Text('Nova transação', style: TextStyle(color: Colors.black)),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountRow(AccountItem account) {
    bool isSelected = _selectedAccount?.id == account.id;
    return InkWell(
      onTap: () => setState(() => _selectedAccount = account),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    account.isUnbalanced ? Icons.warning_amber_rounded : Icons.account_balance_wallet_outlined,
                    size: 18,
                    color: account.isUnbalanced ? AppColors.warningOrange : AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 10),
                  Text(account.name, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Text(
              '€ ${(account.amount.value / 100).toStringAsFixed(2)}',
              style: TextStyle(
                color: account.amount.isNegative ? AppColors.expenseRed : AppColors.incomeGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.more_vert, size: 18, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }

  Widget _buildProp(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
          Text(value, style: TextStyle(color: color ?? AppColors.primaryText, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
        ],
      ),
    );
  }
}
