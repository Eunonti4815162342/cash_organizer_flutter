import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../../../domain/models/account_item.dart';
import '../../../domain/models/financial_entity.dart';
import '../../../domain/repositories/account_repository.dart';
import '../../../infrastructure/repositories/cached_account_repository.dart';
import '../../../services/api_service.dart';
import '../../../l10n/app_localizations.dart';
import 'transaction_form_screen.dart';
import '../widgets/account_form_dialog.dart';

class AccountTransactionsScreen extends StatefulWidget {
  const AccountTransactionsScreen({super.key});

  @override
  State<AccountTransactionsScreen> createState() => _AccountTransactionsScreenState();
}

class _AccountTransactionsScreenState extends State<AccountTransactionsScreen> {
  final IAccountRepository _accountRepo = CachedAccountRepository();
  final ApiService _apiService = ApiService();
  
  List<FinancialEntity> _entities = [];
  List<AccountItem> _allAccounts = [];
  bool _isLoading = true;
  AccountItem? _selectedAccount;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      // Entidades financieras todavía vienen de la API directamente (podríamos cachearlas luego)
      final ents = await _apiService.fetchEntities();
      final accs = await _accountRepo.fetchAccounts();
      
      if (mounted) {
        setState(() {
          _entities = ents;
          _allAccounts = accs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 800;
    
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final orphans = _allAccounts.where((a) => a.entity == null).toList();

    Widget desktopLayout = Row(
      children: [
        Expanded(flex: 7, child: _buildMainContent(l10n, orphans)),
        _buildPropertiesPanel(l10n, false),
      ],
    );

    Widget mobileLayout = SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildMainContent(l10n, orphans),
          ),
          const Divider(height: 1),
          _buildPropertiesPanel(l10n, true),
        ],
      ),
    );

    return isMobile ? mobileLayout : desktopLayout;
  }

  Widget _buildMainContent(AppLocalizations l10n, List<AccountItem> orphans) {
    return Container(
      color: AppColors.cardBackground,
      child: Column(
        children: [
          Container(
            height: 35,
            color: AppColors.tableHeader,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: Text('${l10n.entity} / ${l10n.accountName}', style: AppTextStyles.tableHeader)),
                Text(l10n.totalBalance, style: AppTextStyles.tableHeader),
                const SizedBox(width: 40),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              children: [
                ..._entities.map((entity) => _buildEntitySection(entity, l10n)),
                if (orphans.isNotEmpty) 
                  _buildSimpleSection('Individual / No ${l10n.entity}', orphans),
              ],
            ),
          ),
          _buildFooter(l10n),
        ],
      ),
    );
  }

  Widget _buildEntitySection(FinancialEntity entity, AppLocalizations l10n) {
    final entityAccounts = _allAccounts.where((a) => a.entity?.id == entity.id).toList();
    double entityTotal = entityAccounts.fold(0, (sum, item) => sum + (item.amount.value / 100));
    
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
            Expanded(child: Text(entity.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.black12),
              onPressed: () => _confirmDeleteEntity(entity, l10n),
            ),
            Text('€ ${entityTotal.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: entityTotal < 0 ? AppColors.expenseRed : AppColors.primaryBlue)),
          ],
        ),
        children: entityAccounts.map((acc) => _buildAccountRow(acc, indent: 32)).toList(),
      ),
    );
  }

  Widget _buildSimpleSection(String title, List<AccountItem> accounts) {
    double subtotal = accounts.fold(0, (sum, item) => sum + (item.amount.value / 100));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFFEEEEEE),
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              Text('€ ${subtotal.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: subtotal < 0 ? AppColors.expenseRed : Colors.grey)),
            ],
          ),
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
        decoration: BoxDecoration(color: isSelected ? const Color(0xFFE3F2FD) : Colors.transparent, border: const Border(bottom: BorderSide(color: AppColors.divider))),
        padding: EdgeInsets.only(left: indent, right: 16, top: 12, bottom: 12),
        child: Row(
          children: [
            Expanded(child: Row(children: [
              Icon(account.isUnbalanced ? Icons.warning_amber_rounded : Icons.account_balance_wallet_outlined, size: 18, color: account.isUnbalanced ? AppColors.warningOrange : AppColors.primaryBlue),
              const SizedBox(width: 10),
              Expanded(child: Text(account.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), overflow: TextOverflow.ellipsis)),
            ])),
            Text('€ ${balance.toStringAsFixed(2)}', style: TextStyle(color: (balance < 0 || account.amount.isNegative) ? AppColors.expenseRed : AppColors.incomeGreen, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(width: 10),
            const Icon(Icons.more_vert, size: 18, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(AppLocalizations l10n) {
    double total = _allAccounts.fold(0, (sum, item) => sum + (item.amount.value / 100));
    return Container(
      height: 40, padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: AppColors.tableHeader, border: const Border(top: BorderSide(color: Colors.black12))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('${l10n.totalBalance}: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          Text('€ ${total.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: total < 0 ? AppColors.expenseRed : Colors.black)),
          const Icon(Icons.arrow_drop_down, size: 16),
        ],
      ),
    );
  }

  Widget _buildPropertiesPanel(AppLocalizations l10n, bool isMobile) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.accountProperties, style: const TextStyle(fontSize: 16, color: AppColors.secondaryText, fontWeight: FontWeight.bold)),
            if (_selectedAccount != null) IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _selectedAccount = null)),
          ],
        ),
        const SizedBox(height: 20),
        if (_selectedAccount != null) ...[
          Row(children: [
            Expanded(child: _buildProp(l10n.accountName, _selectedAccount!.name, isBold: true)),
            IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.primaryBlue), onPressed: () => _showEditAccountDialog(_selectedAccount!)),
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _confirmDeleteAccount(_selectedAccount!, l10n)),
          ]),
          _buildProp(l10n.entity, _selectedAccount!.entity?.name ?? 'None', isBold: true),
          _buildProp(l10n.description, _selectedAccount!.description ?? 'N/A', isBold: true),
          _buildProp('Currency', _selectedAccount!.amount.currency, isBold: true),
          _buildProp(l10n.totalBalance, '€ ${(_selectedAccount!.amount.value / 100).toStringAsFixed(2)}', color: (_selectedAccount!.amount.value < 0 || _selectedAccount!.amount.isNegative) ? AppColors.expenseRed : AppColors.incomeGreen, isBold: true),
          _buildProp(l10n.type, _selectedAccount!.accountType ?? 'Cash', isBold: true),
        ] else Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(l10n.noData, style: const TextStyle(fontSize: 12)))),
      ],
    );

    return Container(
      width: isMobile ? double.infinity : 300,
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(left: isMobile ? BorderSide.none : const BorderSide(color: Colors.black12)),
      ),
      padding: const EdgeInsets.all(20),
      child: content,
    );
  }

  Widget _buildProp(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(padding: const EdgeInsets.only(bottom: 15.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
      Text(value, style: TextStyle(color: color ?? AppColors.primaryText, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
    ]));
  }

  void _showEditAccountDialog(AccountItem account) {
    showDialog(context: context, barrierDismissible: false, builder: (context) => AccountFormDialog(account: account)).then((saved) { if (saved == true) _refreshData(); });
  }

  void _confirmDeleteAccount(AccountItem account, AppLocalizations l10n) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text(l10n.removeAccount),
      content: Text(l10n.confirmDeleteAccount),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        TextButton(onPressed: () async { Navigator.pop(context); final success = await _apiService.deleteAccount(account.id); if (success) _refreshData(); }, child: Text(l10n.closeAccount)),
        ElevatedButton(onPressed: () async { Navigator.pop(context); final success = await _apiService.deleteAccountPermanently(account.id); if (success) _refreshData(); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: Text(l10n.deleteForever)),
      ],
    ));
  }

  void _confirmDeleteEntity(FinancialEntity entity, AppLocalizations l10n) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text('${l10n.delete} ${l10n.entity}'),
      content: Text('Are you sure you want to delete "${entity.name}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        TextButton(onPressed: () async { Navigator.pop(context); final success = await _apiService.deleteEntity(entity.id); if (success) _refreshData(); }, child: Text(l10n.delete, style: const TextStyle(color: Colors.redAccent))),
      ],
    ));
  }
}
