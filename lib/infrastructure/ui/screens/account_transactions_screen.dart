import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../../../domain/models/account_item.dart';
import '../../../domain/models/financial_entity.dart';
import '../../../services/api_service.dart';
import 'transaction_form_screen.dart';
import '../widgets/account_form_dialog.dart';

class AccountTransactionsScreen extends StatefulWidget {
  const AccountTransactionsScreen({super.key});

  @override
  State<AccountTransactionsScreen> createState() => _AccountTransactionsScreenState();
}

class _AccountTransactionsScreenState extends State<AccountTransactionsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<FinancialEntity>> _entitiesFuture;
  late Future<List<AccountItem>> _orphanAccountsFuture; // Cuentas sin entidad
  AccountItem? _selectedAccount;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _entitiesFuture = _apiService.fetchEntities();
      _orphanAccountsFuture = _apiService.fetchAccounts().then(
        (list) => list.where((a) => a.entity == null).toList()
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // TABLA DE ENTIDADES Y CUENTAS
        Expanded(
          flex: 7,
          child: Container(
            color: AppColors.cardBackground,
            child: Column(
              children: [
                // Cabecera
                Container(
                  height: 35,
                  color: AppColors.tableHeader,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Row(
                    children: [
                      Expanded(child: Text('Entity / Account Name', style: AppTextStyles.tableHeader)),
                      Text('Total Balance', style: AppTextStyles.tableHeader),
                      SizedBox(width: 40),
                    ],
                  ),
                ),
                const Divider(height: 1),
                
                // Lista Agrupada
                Expanded(
                  child: FutureBuilder(
                    future: Future.wait([_entitiesFuture, _orphanAccountsFuture]),
                    builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final List<FinancialEntity> entities = snapshot.data?[0] ?? [];
                      final List<AccountItem> orphans = snapshot.data?[1] ?? [];

                      if (entities.isEmpty && orphans.isEmpty) {
                        return const Center(child: Text('No entities or accounts found', style: TextStyle(color: AppColors.secondaryText)));
                      }

                      return ListView(
                        children: [
                          // 1. Mostrar Entidades con sus cuentas
                          ...entities.map((entity) => _buildEntitySection(entity)),
                          
                          // 2. Mostrar cuentas sin entidad (si existen)
                          if (orphans.isNotEmpty) 
                            _buildSimpleSection('Individual / No Entity', orphans),
                        ],
                      );
                    },
                  ),
                ),
                
                // Footer
                _buildFooter(),
              ],
            ),
          ),
        ),
        
        // PANEL DE PROPIEDADES (Derecho)
        _buildPropertiesPanel(),
      ],
    );
  }

  Widget _buildEntitySection(FinancialEntity entity) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        backgroundColor: const Color(0xFFF8FBFD),
        collapsedBackgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(entity.type == EntityType.LEGAL ? Icons.business : Icons.person, color: AppColors.primaryBlue, size: 20),
            const SizedBox(width: 10),
            Text(entity.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText, fontSize: 15)),
            if (entity.taxId != null && entity.taxId!.isNotEmpty)
              Text(' (${entity.taxId})', style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
          ],
        ),
        children: (entity.id == 0) ? [] : _buildAccountRowsForEntity(entity.id),
      ),
    );
  }

  List<Widget> _buildAccountRowsForEntity(int entityId) {
    return [
      FutureBuilder<List<AccountItem>>(
        future: _apiService.fetchAccounts(),
        builder: (context, snapshot) {
          final accounts = snapshot.data?.where((a) => a.entity?.id == entityId).toList() ?? [];
          return Column(
            children: accounts.map((acc) => _buildAccountRow(acc, indent: 32)).toList(),
          );
        }
      )
    ];
  }

  Widget _buildSimpleSection(String title, List<AccountItem> accounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFFEEEEEE),
          width: double.infinity,
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        ),
        ...accounts.map((acc) => _buildAccountRow(acc)),
      ],
    );
  }

  Widget _buildAccountRow(AccountItem account, {double indent = 16}) {
    bool isSelected = _selectedAccount?.id == account.id;
    double balance = account.amount.value / 100;
    return InkWell(
      onTap: () => setState(() => _selectedAccount = account),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        padding: EdgeInsets.only(left: indent, right: 16, top: 12, bottom: 12),
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
              '€ ${balance.toStringAsFixed(2)}',
              style: TextStyle(
                color: (balance < 0 || account.amount.isNegative) ? AppColors.expenseRed : AppColors.incomeGreen,
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

  Widget _buildFooter() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.tableHeader,
        border: const Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text('Global Balance: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          FutureBuilder<List<AccountItem>>(
            future: _apiService.fetchAccounts(),
            builder: (context, snapshot) {
              final accounts = snapshot.data ?? [];
              double total = accounts.fold(0, (sum, item) => sum + (item.amount.value / 100));
              return Text(
                '€ ${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 12,
                  color: total < 0 ? AppColors.expenseRed : Colors.black,
                ),
              );
            },
          ),
          const Icon(Icons.arrow_drop_down, size: 16),
        ],
      ),
    );
  }

  Widget _buildPropertiesPanel() {
    return Expanded(
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
                const Text('Account properties', style: TextStyle(fontSize: 16, color: AppColors.secondaryText)),
                if (_selectedAccount != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: AppColors.secondaryText),
                    onPressed: () => setState(() => _selectedAccount = null),
                  ),
              ],
            ),
            const SizedBox(height: 30),
            if (_selectedAccount != null) ...[
              Row(
                children: [
                  Expanded(child: _buildProp('Name', _selectedAccount!.name, isBold: true)),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primaryBlue),
                    onPressed: () => _showEditAccountDialog(_selectedAccount!),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                    onPressed: () => _confirmDeleteAccount(_selectedAccount!),
                  ),
                ],
              ),
              _buildProp('Entity', _selectedAccount!.entity?.name ?? 'None', isBold: true),
              _buildProp('Description', _selectedAccount!.description ?? 'N/A', isBold: true),
              _buildProp('Currency', _selectedAccount!.amount.currency, isBold: true),
              _buildProp('Total Balance', '€ ${(_selectedAccount!.amount.value / 100).toStringAsFixed(2)}', 
                color: (_selectedAccount!.amount.value < 0 || _selectedAccount!.amount.isNegative) ? AppColors.expenseRed : AppColors.incomeGreen, isBold: true),
              _buildProp('Type', _selectedAccount!.accountType ?? 'Cash', isBold: true),
              _buildProp('Status', _selectedAccount!.isUnbalanced ? 'Unbalanced' : 'Balanced', isBold: true),
            ] else
              const Center(child: Text('Select an account to see details', style: TextStyle(color: AppColors.secondaryText, fontSize: 12))),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => TransactionFormScreen()),
                  ).then((saved) {
                    if (saved == true) _refreshData();
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, elevation: 0),
                child: const Text('New transaction', style: TextStyle(color: Colors.black)),
              ),
            )
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

  void _showEditAccountDialog(AccountItem account) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AccountFormDialog(account: account),
    ).then((saved) {
      if (saved == true) {
        _refreshData();
        setState(() => _selectedAccount = null);
      }
    });
  }

  void _confirmDeleteAccount(AccountItem account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete "${account.name}"? This will be recorded as a closing transaction.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _apiService.deleteAccount(account.id);
              if (success) {
                _refreshData();
                setState(() => _selectedAccount = null);
              }
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
