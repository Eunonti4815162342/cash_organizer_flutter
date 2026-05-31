import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../styles/app_styles.dart';
import '../../../domain/models/account_item.dart';
import '../../../domain/models/financial_entity.dart';
import '../../../domain/repositories/account_repository.dart';
import '../../../domain/repositories/entity_repository.dart';
import '../../../services/api_service.dart';
import '../../../l10n/app_localizations.dart';
import 'account_details_screen.dart';
import '../widgets/account_form_dialog.dart';
import '../widgets/entity_form_dialog.dart';
import '../widgets/ui_helpers.dart';
import '../widgets/skeleton_widgets.dart';

class AccountTransactionsScreen extends StatefulWidget {
  const AccountTransactionsScreen({super.key});

  @override
  State<AccountTransactionsScreen> createState() => _AccountTransactionsScreenState();
}

class _AccountTransactionsScreenState extends State<AccountTransactionsScreen> {
  final IAccountRepository _accountRepo = GetIt.instance.get<IAccountRepository>();
  final IEntityRepository _entityRepo = GetIt.instance.get<IEntityRepository>();
  final ApiService _apiService = GetIt.instance.get<ApiService>();
  
  List<FinancialEntity> _entities = [];
  List<AccountItem> _allAccounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Usamos los repositorios que manejan caché/fallback automáticamente
      final results = await Future.wait([
        _entityRepo.fetchEntities(),
        _accountRepo.fetchAccounts(),
      ]);
      
      if (mounted) {
        setState(() {
          _entities = results[0] as List<FinancialEntity>;
          _allAccounts = results[1] as List<AccountItem>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing account data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 800;
    
    if (_isLoading) return const SkeletonTransactionList(itemCount: 6);

    final orphans = _allAccounts.where((a) => a.entity == null).toList();

    return Scaffold(
      body: _buildMainContent(l10n, orphans),
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
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryText)),
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
      builder: (context) => const EntityFormDialog(),
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
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline, size: 17, color: Colors.grey.shade300),
            onPressed: () => _confirmDeleteEntity(entity, l10n),
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
    final balance = account.amount.value / 100;
    final isNegative = balance < 0 || account.amount.isNegative;

    return InkWell(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => AccountDetailsScreen(account: account)))
          .then((_) => _refreshData()),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.only(left: isIndented ? 20 : 16, right: 4, top: 10, bottom: 10),
        child: Row(
          children: [
            Icon(
              account.isUnbalanced ? Icons.warning_amber_rounded : Icons.account_balance_wallet_outlined,
              size: 17,
              color: account.isUnbalanced ? AppColors.warningOrange : Colors.grey.shade400,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                account.name,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.primaryText),
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
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 15, color: Colors.grey.shade400),
              onPressed: () => _showEditAccountDialog(account),
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              tooltip: 'Editar',
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
      padding: const EdgeInsets.fromLTRB(12, 10, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => _showAddMenu(l10n),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Añadir'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const Spacer(),
          Text('${l10n.totalBalance}  ', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.secondaryText)),
          Text(
            '€ ${total.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isNegative ? AppColors.expenseRed : AppColors.primaryText),
          ),
        ],
      ),
    );
  }

  void _showEditAccountDialog(AccountItem? account) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AccountFormDialog(account: account),
    ).then((result) {
      if (result == true || result == 'deleted') _refreshData();
    });
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
