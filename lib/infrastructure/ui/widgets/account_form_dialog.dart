import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../styles/app_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/api_service.dart';
import '../../../domain/models/account_item.dart';
import '../../../domain/models/financial_entity.dart';
import '../../../domain/repositories/account_repository.dart';
import 'entity_form_dialog.dart';

class AccountFormDialog extends StatefulWidget {
  final AccountItem? account;
  const AccountFormDialog({super.key, this.account});

  @override
  State<AccountFormDialog> createState() => _AccountFormDialogState();
}

class _AccountFormDialogState extends State<AccountFormDialog> {
  final ApiService _apiService = ApiService();
  late final IAccountRepository _accountRepo = GetIt.instance<IAccountRepository>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _initialBalanceController;
  late TextEditingController _notesController;
  
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();
  final FocusNode _balanceFocus = FocusNode();
  final FocusNode _notesFocus = FocusNode();
  
  String _selectedCurrency = 'EUR';
  String _selectedType = 'CASH';
  FinancialEntity? _selectedEntity;
  List<FinancialEntity> _entities = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _descriptionController = TextEditingController(text: widget.account?.description ?? '');
    _initialBalanceController = TextEditingController(
      text: widget.account != null 
          ? (widget.account!.amount.value / 100).toStringAsFixed(2) 
          : '0.00'
    );
    _notesController = TextEditingController(text: widget.account?.notes ?? '');
    
    // Clear field on focus logic
    _nameFocus.addListener(() { if (_nameFocus.hasFocus) _nameController.clear(); });
    _descFocus.addListener(() { if (_descFocus.hasFocus) _descriptionController.clear(); });
    _notesFocus.addListener(() { if (_notesFocus.hasFocus) _notesController.clear(); });
    _balanceFocus.addListener(() {
      if (_balanceFocus.hasFocus && (_initialBalanceController.text == '0.00' || widget.account != null)) {
        _initialBalanceController.clear();
      }
    });

    if (widget.account != null) {
      _selectedCurrency = widget.account!.amount.currency;
      _selectedType = (widget.account!.accountType ?? 'CASH').toUpperCase();
      if (!['CASH', 'BANK', 'CARD'].contains(_selectedType)) {
        _selectedType = 'CASH';
      }
      // _selectedEntity se asigna en _loadEntities() una vez la lista esté disponible,
      // para evitar que el DropdownButton reciba un value que no está en items todavía.
    }
    _loadEntities();
  }

  Future<void> _loadEntities() async {
    final list = await _apiService.fetchEntities();
    if (mounted) {
      setState(() {
        _entities = list;
        if (widget.account?.entity != null) {
          try {
            _selectedEntity = _entities.firstWhere((e) => e.id == widget.account!.entity!.id);
          } catch (e) {
            _selectedEntity = null;
          }
        }
      });
    }
  }

  void _showNewEntityDialog() {
    showDialog(
      context: context,
      builder: (context) => const EntityFormDialog(),
    ).then((saved) {
      if (saved == true) _loadEntities();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _initialBalanceController.dispose();
    _notesController.dispose();
    _nameFocus.dispose();
    _descFocus.dispose();
    _balanceFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < AppDimens.mobileBreakpoint;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: isMobile ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
      child: Container(
        width: isMobile ? double.infinity : 1000,
        height: isMobile ? double.infinity : 620,
        decoration: BoxDecoration(
          color: AppColors.windowBackground,
          borderRadius: BorderRadius.circular(isMobile ? 0 : 24),
          boxShadow: isMobile ? null : const [BoxShadow(color: Colors.black26, blurRadius: 30, offset: Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isMobile ? 0 : 24),
          child: Column(
            children: [
              _buildHeader(l10n, isMobile),
              Expanded(
                child: isMobile
                    ? _buildMobileForm(l10n)
                    : _buildDesktopForm(l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            widget.account == null ? l10n.newAccount : l10n.editAccount,
            style: const TextStyle(fontSize: 17, color: AppColors.primaryText, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check, size: 16),
            label: Text(l10n.save),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
          ],
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) return;
    final double val = double.tryParse(_initialBalanceController.text) ?? 0.0;

    if (widget.account == null) {
      // Crear: funciona offline — se guarda localmente y sincroniza al reconectar
      final newAccount = AccountItem(
        id: 0,
        name: _nameController.text,
        description: _descriptionController.text,
        amount: Amount((val * 100).toInt(), _selectedCurrency, val < 0),
        flags: 0,
        accountType: _selectedType,
        notes: _notesController.text,
        entity: _selectedEntity,
      );
      await _accountRepo.saveAccount(newAccount);
      if (mounted) Navigator.pop(context, true);
    } else {
      // Editar: funciona offline — guarda pendiente y sincroniza al reconectar
      final updated = AccountItem(
        id: widget.account!.id,
        name: _nameController.text,
        description: _descriptionController.text,
        amount: Amount((val * 100).toInt(), _selectedCurrency, val < 0),
        flags: widget.account!.flags,
        accountType: _selectedType,
        notes: _notesController.text,
        entity: _selectedEntity,
      );
      await _accountRepo.updateAccount(updated);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Widget _buildDesktopForm(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(flex: 6, child: _buildFormFields(l10n)),
        Expanded(flex: 4, child: _buildPropertiesSidebar(l10n)),
      ],
    );
  }

  Widget _buildMobileForm(AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildFormFields(l10n),
          _buildPropertiesSidebar(l10n),
        ],
      ),
    );
  }

  Widget _buildFormFields(AppLocalizations l10n) {
    const inputStyle = TextStyle(color: AppColors.primaryText, fontSize: 14, fontWeight: FontWeight.w500);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Entity section
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildFieldTile(
                  icon: Icons.business_outlined,
                  label: l10n.entity.toUpperCase(),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<FinancialEntity?>(
                          value: _selectedEntity,
                          isExpanded: true,
                          underline: const SizedBox(),
                          hint: Text('Seleccionar...', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                          items: [
                            const DropdownMenuItem<FinancialEntity?>(
                              value: null,
                              child: Text('None / Individual', style: TextStyle(color: Colors.grey, fontSize: 14)),
                            ),
                            ..._entities.map((e) => DropdownMenuItem<FinancialEntity?>(
                              value: e,
                              child: Text(e.name, style: inputStyle),
                            )),
                          ],
                          onChanged: (v) => setState(() => _selectedEntity = v),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryBlue, size: 20),
                        onPressed: _showNewEntityDialog,
                        tooltip: 'Nueva entidad',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Main fields
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildFieldTile(
                  icon: Icons.label_outline,
                  label: 'NOMBRE*',
                  child: TextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    style: inputStyle,
                    decoration: const InputDecoration(hintText: 'Nombre de la cuenta', border: InputBorder.none),
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade100),
                _buildFieldTile(
                  icon: Icons.notes_outlined,
                  label: l10n.description.toUpperCase(),
                  child: TextField(
                    controller: _descriptionController,
                    focusNode: _descFocus,
                    style: inputStyle,
                    decoration: const InputDecoration(hintText: 'Descripción opcional', border: InputBorder.none),
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade100),
                _buildFieldTile(
                  icon: Icons.euro_outlined,
                  label: 'SALDO INICIAL',
                  child: TextField(
                    controller: _initialBalanceController,
                    focusNode: _balanceFocus,
                    style: inputStyle,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade100),
                _buildFieldTile(
                  icon: Icons.sticky_note_2_outlined,
                  label: l10n.notes.toUpperCase(),
                  child: TextField(
                    controller: _notesController,
                    focusNode: _notesFocus,
                    style: inputStyle,
                    maxLines: 2,
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Type & currency
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildFieldTile(
                  icon: Icons.category_outlined,
                  label: l10n.type.toUpperCase(),
                  child: DropdownButton<String>(
                    value: _selectedType,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(value: 'CASH', child: Text('Efectivo', style: inputStyle)),
                      DropdownMenuItem(value: 'BANK', child: Text('Banco', style: inputStyle)),
                      DropdownMenuItem(value: 'CARD', child: Text('Tarjeta', style: inputStyle)),
                    ],
                    onChanged: (v) => setState(() => _selectedType = v!),
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade100),
                _buildFieldTile(
                  icon: Icons.currency_exchange_outlined,
                  label: 'DIVISA',
                  child: DropdownButton<String>(
                    value: _selectedCurrency,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: ['EUR', 'USD', 'GBP'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: inputStyle))).toList(),
                    onChanged: (v) => setState(() => _selectedCurrency = v!),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldTile({required IconData icon, required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: AppColors.secondaryText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.primaryBlue, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesSidebar(AppLocalizations l10n) {
    final balance = double.tryParse(_initialBalanceController.text) ?? 0.0;
    final isNegative = balance < 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        border: const Border(left: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.accountProperties,
              style: const TextStyle(fontSize: 13, color: AppColors.secondaryText, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPropertyItem(l10n.accountName, _nameController.text.isEmpty ? 'Nueva cuenta' : _nameController.text),
                  const SizedBox(height: 12),
                  _buildPropertyItem('Divisa', _selectedCurrency),
                  const SizedBox(height: 12),
                  _buildPropertyItem(
                    l10n.totalBalance,
                    '€ ${_initialBalanceController.text.isEmpty ? '0.00' : _initialBalanceController.text}',
                    valueColor: isNegative ? AppColors.expenseRed : AppColors.incomeGreen,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyItem(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 10, letterSpacing: 0.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(color: valueColor ?? AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
