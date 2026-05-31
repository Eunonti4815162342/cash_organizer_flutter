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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _descriptionController = TextEditingController(text: widget.account?.description ?? '');
    _initialBalanceController = TextEditingController(
      text: widget.account != null
          ? (widget.account!.amount.value / 100).toStringAsFixed(2)
          : '0.00',
    );
    _notesController = TextEditingController(text: widget.account?.notes ?? '');

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
      if (!['CASH', 'BANK', 'CARD'].contains(_selectedType)) _selectedType = 'CASH';
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
          } catch (_) {
            _selectedEntity = null;
          }
        }
      });
    }
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
    final isEditing = widget.account != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primaryBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? l10n.editAccount : l10n.newAccount,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                    ),
                  ),
                  if (isEditing)
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20, color: Colors.redAccent.withValues(alpha: 0.8)),
                      onPressed: () => _confirmDelete(l10n),
                      tooltip: 'Eliminar cuenta',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.secondaryText),
                    onPressed: () => Navigator.pop(context),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Fields
              Flexible(
                child: SingleChildScrollView(
                  child: Card(
                    elevation: 0,
                    color: Colors.grey.shade50,
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
                            style: _inputStyle,
                            decoration: const InputDecoration(hintText: 'Nombre de la cuenta', border: InputBorder.none),
                          ),
                        ),
                        _divider(),
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
                                  hint: Text('Sin entidad', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                                  items: [
                                    const DropdownMenuItem<FinancialEntity?>(
                                      value: null,
                                      child: Text('Sin entidad', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                    ),
                                    ..._entities.map((e) => DropdownMenuItem<FinancialEntity?>(
                                          value: e,
                                          child: Text(e.name, style: _inputStyle),
                                        )),
                                  ],
                                  onChanged: (v) => setState(() => _selectedEntity = v),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryBlue, size: 18),
                                onPressed: _showNewEntityDialog,
                                tooltip: 'Nueva entidad',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              ),
                            ],
                          ),
                        ),
                        _divider(),
                        _buildFieldTile(
                          icon: Icons.category_outlined,
                          label: l10n.type.toUpperCase(),
                          child: DropdownButton<String>(
                            value: _selectedType,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: [
                              DropdownMenuItem(value: 'CASH', child: Text('Efectivo', style: _inputStyle)),
                              DropdownMenuItem(value: 'BANK', child: Text('Banco', style: _inputStyle)),
                              DropdownMenuItem(value: 'CARD', child: Text('Tarjeta', style: _inputStyle)),
                            ],
                            onChanged: (v) => setState(() => _selectedType = v!),
                          ),
                        ),
                        _divider(),
                        _buildFieldTile(
                          icon: Icons.euro_outlined,
                          label: 'SALDO INICIAL',
                          child: TextField(
                            controller: _initialBalanceController,
                            focusNode: _balanceFocus,
                            style: _inputStyle,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(border: InputBorder.none),
                          ),
                        ),
                        _divider(),
                        _buildFieldTile(
                          icon: Icons.currency_exchange_outlined,
                          label: 'DIVISA',
                          child: DropdownButton<String>(
                            value: _selectedCurrency,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: ['EUR', 'USD', 'GBP']
                                .map((e) => DropdownMenuItem(value: e, child: Text(e, style: _inputStyle)))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedCurrency = v!),
                          ),
                        ),
                        _divider(),
                        _buildFieldTile(
                          icon: Icons.notes_outlined,
                          label: l10n.description.toUpperCase(),
                          child: TextField(
                            controller: _descriptionController,
                            focusNode: _descFocus,
                            style: _inputStyle,
                            decoration: const InputDecoration(hintText: 'Descripción opcional', border: InputBorder.none),
                          ),
                        ),
                        _divider(),
                        _buildFieldTile(
                          icon: Icons.sticky_note_2_outlined,
                          label: l10n.notes.toUpperCase(),
                          child: TextField(
                            controller: _notesController,
                            focusNode: _notesFocus,
                            style: _inputStyle,
                            maxLines: 2,
                            decoration: const InputDecoration(border: InputBorder.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Footer
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
                      onPressed: _isSaving ? null : () => _save(l10n),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('GUARDAR',
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

  static const TextStyle _inputStyle = TextStyle(
    color: AppColors.primaryText,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade200);

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
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1)),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNewEntityDialog() {
    showDialog(
      context: context,
      builder: (context) => const EntityFormDialog(),
    ).then((saved) {
      if (saved == true) _loadEntities();
    });
  }

  void _confirmDelete(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeAccount),
        content: Text(l10n.confirmDeleteAccount),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _apiService.deleteAccount(widget.account!.id);
              if (success && mounted) Navigator.pop(context, 'deleted');
            },
            child: Text(l10n.closeAccount),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _apiService.deleteAccountPermanently(widget.account!.id);
              if (success && mounted) Navigator.pop(context, 'deleted');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(l10n.deleteForever),
          ),
        ],
      ),
    );
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (_nameController.text.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final double val = double.tryParse(_initialBalanceController.text) ?? 0.0;
      if (widget.account == null) {
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
      } else {
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
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
