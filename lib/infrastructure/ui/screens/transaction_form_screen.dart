import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:natave_flutter/infrastructure/ui/providers/transaction_form_provider.dart';
import 'package:natave_flutter/infrastructure/ui/providers/dashboard_provider.dart';
import 'package:natave_flutter/infrastructure/ui/styles/app_styles.dart';
import 'package:natave_flutter/domain/models/account_item.dart';
import 'package:natave_flutter/domain/models/transaction_item.dart';
import 'package:natave_flutter/domain/models/category.dart' as cat_model;
import 'package:natave_flutter/domain/models/financial_entity.dart';
import 'package:natave_flutter/domain/models/beneficiary.dart';
import 'package:natave_flutter/domain/repositories/transaction_repository.dart';
import 'package:natave_flutter/domain/repositories/account_repository.dart';
import 'package:natave_flutter/domain/repositories/category_repository.dart';
import 'package:natave_flutter/domain/repositories/entity_repository.dart';
import 'package:natave_flutter/domain/repositories/beneficiary_repository.dart';
import 'package:natave_flutter/l10n/app_localizations.dart';
import 'package:natave_flutter/services/session_service.dart';

class TransactionFormScreen extends StatefulWidget {
  final TransactionItem? transaction;
  final AccountItem? initialAccount;
  const TransactionFormScreen({super.key, this.transaction, this.initialAccount});
  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  late TransactionFormProvider _provider;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late FocusNode _amountFocus;
  late FocusNode _descriptionFocus;

  @override
  void initState() {
    super.initState();
    final getIt = GetIt.instance;
    _provider = TransactionFormProvider(getIt.get<ITransactionRepository>(), getIt.get<IAccountRepository>(), getIt.get<ICategoryRepository>(), getIt.get<IEntityRepository>(), getIt.get<IBeneficiaryRepository>(), getIt.get<SessionService>(), initialTransaction: widget.transaction, initialAccount: widget.initialAccount);
    _amountController = TextEditingController(text: '0.00');
    _descriptionController = TextEditingController();
    _amountFocus = FocusNode();
    _descriptionFocus = FocusNode();
    _amountFocus.addListener(() { if (_amountFocus.hasFocus && (_amountController.text == '0.00' || _amountController.text == '0')) _amountController.clear(); });
    _descriptionFocus.addListener(() { if (_descriptionFocus.hasFocus) _descriptionController.clear(); });
    _provider.loadData().then((_) {
      if (!mounted) return;
      if (widget.transaction != null) setState(() { _amountController.text = _provider.amount; _descriptionController.text = _provider.description; });
      WidgetsBinding.instance.addPostFrameCallback((_) { if (_amountFocus.canRequestFocus) _amountFocus.requestFocus(); });
    });
  }

  @override
  void dispose() { _amountFocus.dispose(); _descriptionFocus.dispose(); _amountController.dispose(); _descriptionController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<TransactionFormProvider>(builder: (context, provider, _) {
          final l10n = AppLocalizations.of(context)!;
          Color themeColor = provider.selectedTypeLabel == 'EXPENSE' ? Colors.redAccent : provider.selectedTypeLabel == 'INCOME' ? Colors.greenAccent : Colors.blueAccent;
          return Scaffold(
            appBar: AppBar(title: Text(widget.transaction == null ? l10n.newTransaction : l10n.editTransaction), actions: [if (widget.transaction != null) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _confirmDelete(l10n, provider))]),
            body: SafeArea(child: provider.isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(padding: const EdgeInsets.only(bottom: 100), child: Column(children: [
                        Container(color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Container(decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(30)), child: Row(children: [_buildTypeTab('EXPENSE', l10n.expense, Colors.redAccent, provider), _buildTypeTab('INCOME', l10n.income, Colors.greenAccent, provider), _buildTypeTab('TRANSFER', l10n.transfer, Colors.blueAccent, provider)]))),
                        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 4), child: Card(elevation: 0, color: themeColor.withValues(alpha: 0.07), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l10n.amount.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: themeColor, letterSpacing: 1.2)), TextField(controller: _amountController, focusNode: _amountFocus, textAlign: TextAlign.left, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: provider.setAmount, style: TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: themeColor), decoration: InputDecoration(border: InputBorder.none, prefixText: '€ ', prefixStyle: TextStyle(fontSize: 28, color: themeColor.withValues(alpha: 0.5), fontWeight: FontWeight.w300)))])))),
                        const SizedBox(height: 8),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Card(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)), child: Column(children: [
                                _buildSelectionTile(label: widget.initialAccount != null ? widget.initialAccount!.name.toUpperCase() : (provider.selectedTypeLabel == 'TRANSFER' ? 'FROM ACCOUNT' : 'ACCOUNT'), value: provider.selectedAccount?.name ?? 'Select...', icon: Icons.account_balance_wallet_outlined, onTap: widget.initialAccount != null ? null : () => _showAccountPicker(true, l10n, provider), onClear: (widget.initialAccount != null || provider.selectedAccount == null) ? null : () => provider.setSelectedAccount(null), isLocked: widget.initialAccount != null),
                                const Divider(height: 1, indent: 70),
                                _buildSelectionTile(label: l10n.date.toUpperCase(), value: "${provider.selectedDate.day.toString().padLeft(2, '0')}/${provider.selectedDate.month.toString().padLeft(2, '0')}/${provider.selectedDate.year}", icon: Icons.calendar_today_outlined, onTap: () => _showDatePicker(provider)),
                                const Divider(height: 1, indent: 70),
                                if (provider.selectedTypeLabel == 'TRANSFER') ...[_buildSelectionTile(label: 'TO ACCOUNT', value: provider.selectedToAccount?.name ?? 'Select...', icon: Icons.swap_horiz_outlined, onTap: () => _showAccountPicker(false, l10n, provider), onClear: provider.selectedToAccount == null ? null : () => provider.setSelectedToAccount(null)), const Divider(height: 1, indent: 70)]
                                else ...[_buildSelectionTile(label: 'BENEFICIARY', value: provider.selectedBeneficiary?.name ?? 'Select...', icon: Icons.person_outline, onTap: () => _showBeneficiaryPicker(provider.beneficiaries, l10n, provider), onClear: provider.selectedBeneficiary == null ? null : () => provider.setSelectedBeneficiary(null)), const Divider(height: 1, indent: 70),
                                  _buildSelectionTile(label: l10n.categories.toUpperCase(), value: provider.selectedSubcategory != null ? '${provider.selectedCategory?.name} > ${provider.selectedSubcategory?.name}' : (provider.selectedCategory?.name ?? 'Select...'), icon: Icons.category_outlined, onTap: () => _showCategoryPicker(provider.filteredCategories, l10n, provider), onClear: provider.selectedCategory == null ? null : () { provider.setSelectedCategory(null); provider.setSelectedSubcategory(null); }),
                                  const Divider(height: 1, indent: 70)],
                                Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0), child: TextField(controller: _descriptionController, focusNode: _descriptionFocus, onChanged: provider.setDescription, style: TextStyle(color: Colors.grey.shade700, fontSize: 15), decoration: InputDecoration(labelText: l10n.description.toUpperCase(), labelStyle: const TextStyle(fontSize: 11, color: AppColors.primaryBlue, fontWeight: FontWeight.bold, letterSpacing: 1.1), hintText: 'Add a note...', floatingLabelBehavior: FloatingLabelBehavior.always, border: InputBorder.none), maxLines: 2)),
                              ]))),
                      ]))),
            floatingActionButton: Container(margin: const EdgeInsets.all(24), child: SizedBox(width: 200, height: 50, child: ElevatedButton(onPressed: () => _save(context, l10n, provider), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, elevation: 8, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.check, size: 20), const SizedBox(width: 8), Text(l10n.save.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2))])))),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          );
        }),
    );
  }

  Widget _buildTypeTab(String type, String label, Color color, TransactionFormProvider provider) {
    bool isSelected = provider.selectedTypeLabel == type;
    return Expanded(child: GestureDetector(onTap: () => provider.setTransactionType(type), child: AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.all(4), padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: isSelected ? color : Colors.transparent, borderRadius: BorderRadius.circular(30)), child: Center(child: Text(label.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey.shade500, fontSize: 11, letterSpacing: 0.8))))));
  }

  Widget _buildSelectionTile({required String label, required String value, required IconData icon, required VoidCallback? onTap, VoidCallback? onClear, bool isLocked = false}) {
    return ListTile(onTap: onTap, leading: Icon(icon, color: isLocked ? Colors.grey : AppColors.primaryText), title: Text(label, style: TextStyle(fontSize: 10, color: isLocked ? Colors.grey : AppColors.primaryBlue, fontWeight: FontWeight.bold)), subtitle: Text(value, style: TextStyle(fontSize: 16, color: isLocked ? Colors.grey : AppColors.primaryText)), trailing: Row(mainAxisSize: MainAxisSize.min, children: [if (onClear != null) IconButton(icon: const Icon(Icons.clear, size: 18, color: Colors.grey), onPressed: onClear, padding: EdgeInsets.zero, constraints: const BoxConstraints()), if (!isLocked) ...[const SizedBox(width: 8), const Icon(Icons.chevron_right, color: Colors.grey)] else const Icon(Icons.lock_outline, size: 16, color: Colors.grey)]));
  }

  Future<void> _save(BuildContext context, AppLocalizations l10n, TransactionFormProvider provider) async {
    provider.setAmount(_amountController.text);
    provider.setDescription(_descriptionController.text);
    String? errorMessage;
    final amountValue = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    if (amountValue <= 0) errorMessage = 'El importe debe ser mayor que 0';
    else if (provider.selectedAccount == null) errorMessage = 'Debes seleccionar una cuenta de origen';
    else if (provider.selectedTypeLabel == 'TRANSFER' && provider.selectedToAccount == null) errorMessage = 'Debes seleccionar una cuenta de destino';
    else if (provider.selectedTypeLabel != 'TRANSFER' && provider.selectedCategory == null) errorMessage = 'Debes seleccionar una categoría';
    
    if (errorMessage != null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
      return;
    }

    final success = await provider.saveTransaction();
    if (success && mounted) {
      try { Provider.of<DashboardProvider>(context, listen: false).refreshBalances(); } catch (_) {}
      Navigator.of(context).pop(true);
    }
  }

  void _showAccountPicker(bool isFrom, AppLocalizations l10n, TransactionFormProvider provider) {
    String search = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setPickerState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              _buildSheetHandle(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  onChanged: (v) => setPickerState(() => search = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: l10n.search,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    ...provider.entities.map((entity) {
                      final entityAccounts = provider.accounts.where((a) => a.entity?.id == entity.id).toList();
                      final filtered = entityAccounts.where((a) => a.name.toLowerCase().contains(search)).toList();
                      if (filtered.isEmpty) return const SizedBox();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(children: [
                              Icon(entity.type == EntityType.LEGAL ? Icons.business : Icons.person, size: 16, color: AppColors.primaryBlue),
                              const SizedBox(width: 8),
                              Text(entity.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryBlue, letterSpacing: 1.1)),
                            ]),
                          ),
                          ...filtered.map((acc) => ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 32),
                            title: Text(acc.name, style: const TextStyle(fontSize: 14)),
                            subtitle: Text('€ ${(acc.amount.value / 100).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            onTap: () { isFrom ? provider.setSelectedAccount(acc) : provider.setSelectedToAccount(acc); Navigator.pop(context); },
                          )),
                          const Divider(height: 1, indent: 16),
                        ],
                      );
                    }),
                    _buildOrphanAccountsSection(provider, search, isFrom),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
    );
  }

  Widget _buildSheetSearchField({required String hint, required ValueChanged<String> onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildOrphanAccountsSection(TransactionFormProvider provider, String search, bool isFrom) {
    final orphans = provider.accounts.where((a) => a.entity == null).toList();
    final filtered = orphans.where((a) => a.name.toLowerCase().contains(search)).toList();
    if (filtered.isEmpty) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text('INDIVIDUAL / OTHERS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1))), ...filtered.map((acc) => ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 32), title: Text(acc.name, style: const TextStyle(fontSize: 14)), subtitle: Text('€ ${(acc.amount.value / 100).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.grey)), onTap: () { isFrom ? provider.setSelectedAccount(acc) : provider.setSelectedToAccount(acc); Navigator.pop(context); }))] );
  }

  void _showCategoryPicker(List<cat_model.Category> categories, AppLocalizations l10n, TransactionFormProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          String search = '';
          return StatefulBuilder(
            builder: (context, setState) {
              final filteredCategories = categories.where((c) {
                final matchesCategory = c.name.toLowerCase().contains(search.toLowerCase());
                final matchesSubcategory = c.subcategories.any((s) => s.name.toLowerCase().contains(search.toLowerCase()));
                return matchesCategory || matchesSubcategory;
              }).toList()
                ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

              return Container(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    _buildSheetHandle(),
                    _buildSheetSearchField(
                      hint: l10n.search,
                      onChanged: (v) => setState(() => search = v),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredCategories.length,
                        itemBuilder: (context, index) {
                          final category = filteredCategories[index];
                          final filteredSubs = category.subcategories
                              .where((s) => s.name.toLowerCase().contains(search.toLowerCase()))
                              .toList()
                                ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: Text(category.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                                onTap: () {
                                  provider.setSelectedCategory(category);
                                  Navigator.pop(context);
                                },
                              ),
                              ...filteredSubs.map((sub) => ListTile(
                                    contentPadding: const EdgeInsets.only(left: 32),
                                    title: Text(sub.name),
                                    leading: const Icon(Icons.subdirectory_arrow_right, size: 16),
                                    onTap: () {
                                      provider.setSelectedCategory(category);
                                      provider.setSelectedSubcategory(sub);
                                      Navigator.pop(context);
                                    },
                                  )),
                              const Divider(),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showNewBeneficiaryDialog(TransactionFormProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_add_outlined, color: AppColors.primaryBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Nuevo beneficiario',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 20, color: AppColors.secondaryText),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          style: const TextStyle(fontSize: 14, color: AppColors.primaryText, fontWeight: FontWeight.w500),
                          decoration: const InputDecoration(
                            labelText: 'NOMBRE',
                            labelStyle: TextStyle(fontSize: 11, color: AppColors.primaryBlue, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                            border: InputBorder.none,
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('CANCELAR',
                          style: TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (controller.text.isEmpty) return;
                        final newBeneficiary = Beneficiary(id: 0, name: controller.text);
                        provider.setSelectedBeneficiary(newBeneficiary);
                        if (mounted) Navigator.pop(context);
                      },
                      child: const Text('GUARDAR',
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBeneficiaryPicker(List<Beneficiary> beneficiaries, AppLocalizations l10n, TransactionFormProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          String search = '';
          return StatefulBuilder(
            builder: (context, setState) {
              final filteredBeneficiaries = beneficiaries
                  .where((b) => b.name.toLowerCase().contains(search.toLowerCase()))
                  .toList()
                    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

              return Container(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    _buildSheetHandle(),
                    _buildSheetSearchField(
                      hint: l10n.search,
                      onChanged: (v) => setState(() => search = v),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredBeneficiaries.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return ListTile(
                              leading: const Icon(Icons.add_circle_outline, color: AppColors.primaryBlue),
                              title: const Text('AÑADIR BENEFICIARIO',
                                  style: TextStyle(
                                      color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                              onTap: () {
                                Navigator.pop(context);
                                _showNewBeneficiaryDialog(provider);
                              },
                            );
                          }
                          final beneficiary = filteredBeneficiaries[index - 1];
                          return ListTile(
                            title: Text(beneficiary.name),
                            onTap: () {
                              provider.setSelectedBeneficiary(beneficiary);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showDatePicker(TransactionFormProvider provider) async { final picked = await showDatePicker(context: context, initialDate: provider.selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2101)); if (picked != null) provider.setSelectedDate(picked); }

  void _confirmDelete(AppLocalizations l10n, TransactionFormProvider provider) {
    showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(title: Text(l10n.delete), content: Text(l10n.confirmDeleteTransaction), actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
      TextButton(onPressed: () async { 
        Navigator.pop(context); 
        final success = await provider.deleteTransaction(widget.transaction!.id); 
        if (success && mounted) {
          try { Provider.of<DashboardProvider>(context, listen: false).refreshBalances(); } catch (_) {}
          Navigator.of(context).pop(true); 
        }
      }, child: Text(l10n.delete, style: const TextStyle(color: Colors.redAccent))),
    ]));
  }
}
