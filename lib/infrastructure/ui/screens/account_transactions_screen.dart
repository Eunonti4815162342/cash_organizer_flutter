import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../../../domain/models/account_item.dart';
import '../../../domain/models/financial_entity.dart';
import '../../../domain/repositories/account_repository.dart';
import '../../../infrastructure/repositories/cached_account_repository.dart';
import '../../../services/api_service.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/account_form_dialog.dart';
import '../widgets/entity_form_dialog.dart';
import '../widgets/ui_helpers.dart';

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

    return Scaffold(
      body: isMobile ? mobileLayout : desktopLayout,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(l10n),
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddMenu(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Añadir', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
              const SizedBox(height: 16),
              _buildAddMenuOption(
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.primaryBlue,
                title: l10n.newAccount,
                subtitle: 'Cuenta bancaria, efectivo o tarjeta',
                onTap: () { Navigator.pop(context); _showEditAccountDialog(null); },
              ),
              const SizedBox(height: 12),
              _buildAddMenuOption(
                icon: Icons.business_outlined,
                color: Colors.deepPurple,
                title: l10n.newEntity,
                subtitle: 'Banco u organización financiera',
                onTap: () { Navigator.pop(context); _showNewEntityDialog(); },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel, style: const TextStyle(color: AppColors.secondaryText)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddMenuOption({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryText)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showNewEntityDialog() {
    showDialog(
      context: context,
      builder: (context) => EntityFormDialog(),
    ).then((saved) {
      if (saved == true) _refreshData();
    });
  }

  Widget _buildMainContent(AppLocalizations l10n, List<AccountItem> orphans) {
    final hasContent = _entities.isNotEmpty || orphans.isNotEmpty;
    return Container(
      color: AppColors.windowBackground,
      child: Column(
        children: [
          Expanded(
            child: hasContent
                ? ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      ..._entities.map((entity) => _buildEntitySection(entity, l10n)),
                      if (orphans.isNotEmpty) _buildSimpleSection('Individual / No ${l10n.entity}', orphans),
                    ],
                  )
                : EmptyStateWidget(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Sin cuentas',
                    subtitle: 'Añade tu primera cuenta o entidad financiera',
                    actionLabel: 'Añadir cuenta',
                    onAction: () => _showEditAccountDialog(null),
                  ),
          ),
          _buildFooter(l10n),
        ],
      ),
    );
  }

  Widget _buildEntitySection(FinancialEntity entity, AppLocalizations l10n) {
    final entityAccounts = _allAccounts.where((a) => a.entity?.id == entity.id).toList();
    final entityTotal = entityAccounts.fold(0.0, (sum, item) => sum + (item.amount.value / 100));

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(entity.type == EntityType.LEGAL ? Icons.business : Icons.person, color: AppColors.primaryBlue, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(entity.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)),
              Text('€ ${entityTotal.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: entityTotal < 0 ? AppColors.expenseRed : AppColors.primaryBlue)),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 17, color: Colors.grey.shade300),
                onPressed: () => _confirmDeleteEntity(entity, l10n),
              ),
            ],
          ),
          children: [
            Divider(height: 1, color: Colors.grey.shade100),
            ...entityAccounts.map((acc) => _buildAccountRow(acc, isIndented: true)),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleSection(String title, List<AccountItem> accounts) {
    final subtotal = accounts.fold(0.0, (sum, item) => sum + (item.amount.value / 100));
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.person_outline, color: Colors.grey.shade500, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondaryText))),
                Text('€ ${subtotal.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: subtotal < 0 ? AppColors.expenseRed : AppColors.secondaryText)),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          ...accounts.map((acc) => _buildAccountRow(acc, isIndented: true)),
        ],
      ),
    );
  }

  Widget _buildAccountRow(AccountItem account, {bool isIndented = false}) {
    final isSelected = _selectedAccount?.id == account.id;
    final balance = account.amount.value / 100;
    final isNegative = balance < 0 || account.amount.isNegative;

    return InkWell(
      onTap: () => setState(() => _selectedAccount = account),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.06) : Colors.transparent,
          border: isSelected ? Border(left: BorderSide(color: AppColors.primaryBlue, width: 3)) : null,
        ),
        padding: EdgeInsets.only(left: isIndented ? 20 : 16, right: 12, top: 12, bottom: 12),
        child: Row(
          children: [
            Icon(
              account.isUnbalanced ? Icons.warning_amber_rounded : Icons.account_balance_wallet_outlined,
              size: 17,
              color: account.isUnbalanced ? AppColors.warningOrange : (isSelected ? AppColors.primaryBlue : Colors.grey.shade400),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                account.name,
                style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 13, color: isSelected ? AppColors.primaryBlue : AppColors.primaryText),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isNegative ? AppColors.expenseRed.withValues(alpha: 0.08) : AppColors.incomeGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '€ ${balance.toStringAsFixed(2)}',
                style: TextStyle(color: isNegative ? AppColors.expenseRed : AppColors.incomeGreen, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(AppLocalizations l10n) {
    final total = _allAccounts.fold(0.0, (sum, item) => sum + (item.amount.value / 100));
    final isNegative = total < 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('${l10n.totalBalance}  ', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.secondaryText)),
          Text(
            '€ ${total.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isNegative ? AppColors.expenseRed : AppColors.primaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesPanel(AppLocalizations l10n, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 300,
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(left: isMobile ? BorderSide.none : BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.all(16),
      child: _selectedAccount != null ? _buildSelectedAccountPanel(l10n) : _buildEmptyPanel(l10n),
    );
  }

  Widget _buildEmptyPanel(AppLocalizations l10n) {
    return const EmptyStateWidget(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Selecciona una cuenta',
      subtitle: 'Elige una cuenta de la lista para ver sus detalles',
    );
  }

  Widget _buildSelectedAccountPanel(AppLocalizations l10n) {
    final acc = _selectedAccount!;
    final balance = acc.amount.value / 100;
    final isNegative = balance < 0 || acc.amount.isNegative;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(l10n.accountProperties, style: const TextStyle(fontSize: 13, color: AppColors.secondaryText, fontWeight: FontWeight.bold))),
              IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.primaryBlue, size: 18), onPressed: () => _showEditAccountDialog(acc)),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18), onPressed: () => _confirmDeleteAccount(acc, l10n)),
              IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _selectedAccount = null)),
            ],
          ),
          const SizedBox(height: 12),
          // Balance card
          Card(
            elevation: 0,
            color: isNegative ? AppColors.expenseRed.withValues(alpha: 0.07) : AppColors.incomeGreen.withValues(alpha: 0.07),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.euro, color: isNegative ? AppColors.expenseRed : AppColors.incomeGreen, size: 20),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.totalBalance, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      Text('€ ${balance.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isNegative ? AppColors.expenseRed : AppColors.incomeGreen)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Properties card
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProp(l10n.accountName, acc.name),
                  const Divider(height: 20),
                  _buildProp(l10n.entity, acc.entity?.name ?? 'None'),
                  const Divider(height: 20),
                  _buildProp(l10n.type, acc.accountType ?? 'Cash'),
                  const Divider(height: 20),
                  _buildProp('Divisa', acc.amount.currency),
                  if ((acc.description ?? '').isNotEmpty) ...[
                    const Divider(height: 20),
                    _buildProp(l10n.description, acc.description!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProp(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color ?? AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _showEditAccountDialog(AccountItem? account) {
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
