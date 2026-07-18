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
  final FocusNode _balanceFocus = FocusNode();

  String _selectedCurrency = 'EUR';
  String _selectedType = 'CASH';
  FinancialEntity? _selectedEntity;
  List<FinancialEntity> _entities = [];
  bool _isSaving = false;

  static const _typeConfig = {
    'CASH': (Icons.payments_rounded, 'Efectivo'),
    'BANK': (Icons.account_balance_rounded, 'Banco'),
    'CARD': (Icons.credit_card_rounded, 'Tarjeta'),
  };

  IconData get _currentIcon =>
      (_typeConfig[_selectedType]!.$1);

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
    _balanceFocus.addListener(() {
      if (_balanceFocus.hasFocus &&
          (_initialBalanceController.text == '0.00' || widget.account != null)) {
        _initialBalanceController.clear();
      }
    });

    if (widget.account != null) {
      _selectedCurrency = widget.account!.amount.currency;
      _selectedType = (widget.account!.accountType ?? 'CASH').toUpperCase();
      if (!_typeConfig.containsKey(_selectedType)) _selectedType = 'CASH';
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
            _selectedEntity =
                _entities.firstWhere((e) => e.id == widget.account!.entity!.id);
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
    _balanceFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.account != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Cabecera coloreada ──────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0077CC), AppColors.primaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título + botones acción
                    Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            key: ValueKey(_selectedType),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_currentIcon, color: Colors.white, size: 24),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            isEditing ? l10n.editAccount : l10n.newAccount,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        if (isEditing)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.white60, size: 20),
                            onPressed: () => _confirmDelete(l10n),
                            tooltip: 'Eliminar cuenta',
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                          onPressed: () => Navigator.pop(context),
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Selector de tipo como segmented buttons
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        children: _typeConfig.entries
                            .map((e) => _typeTab(e.key, e.value.$2, e.value.$1))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Cuerpo ──────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    children: [
                      // Nombre
                      _buildFieldCard(children: [
                        _buildTextField(
                          icon: Icons.label_outline,
                          label: 'NOMBRE *',
                          controller: _nameController,
                          focusNode: _nameFocus,
                          hint: 'Nombre de la cuenta',
                          autofocus: !isEditing,
                        ),
                      ]),
                      const SizedBox(height: 12),

                      // Entidad + saldo inicial + divisa
                      _buildFieldCard(children: [
                        _buildEntityRow(l10n),
                        _divider(),
                        _buildBalanceRow(),
                      ]),
                      const SizedBox(height: 12),

                      // Descripción y notas (opcionales)
                      _buildFieldCard(children: [
                        _buildTextField(
                          icon: Icons.notes_outlined,
                          label: l10n.description.toUpperCase(),
                          controller: _descriptionController,
                          hint: 'Descripción opcional',
                        ),
                        _divider(),
                        _buildTextField(
                          icon: Icons.sticky_note_2_outlined,
                          label: l10n.notes.toUpperCase(),
                          controller: _notesController,
                          hint: 'Notas adicionales',
                          maxLines: 2,
                        ),
                      ]),
                    ],
                  ),
                ),
              ),

              // ── Botones ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('CANCELAR',
                            style: TextStyle(
                                color: AppColors.secondaryText, fontWeight: FontWeight.bold)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('GUARDAR',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _typeTab(String type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18,
                  color: isSelected
                      ? AppColors.primaryBlue
                      : Colors.white.withValues(alpha: 0.75)),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? AppColors.primaryBlue
                        : Colors.white.withValues(alpha: 0.85),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() =>
      Divider(height: 1, color: Colors.grey.shade200, indent: 16, endIndent: 16);

  Widget _buildTextField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    FocusNode? focusNode,
    String? hint,
    bool autofocus = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Icon(icon, size: 18, color: AppColors.secondaryText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: autofocus,
              maxLines: maxLines,
              style: const TextStyle(
                fontFamily: 'AppFont',
                fontSize: 14,
                color: AppColors.primaryText,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(
                  fontFamily: 'AppFont',
                  fontSize: 11,
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
                hintText: hint,
                hintStyle: TextStyle(
                    fontFamily: 'AppFont', fontSize: 13, color: Colors.grey.shade400),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntityRow(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.business_outlined, size: 18, color: AppColors.secondaryText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ENTIDAD',
                    style: TextStyle(
                        fontFamily: 'AppFont',
                        fontSize: 11,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1)),
                DropdownButton<FinancialEntity?>(
                  value: _selectedEntity,
                  isExpanded: true,
                  underline: const SizedBox(),
                  hint: Text('Selecciona una entidad *',
                      style: TextStyle(
                          fontFamily: 'AppFont', color: Colors.grey.shade400, fontSize: 14)),
                  style: const TextStyle(
                      fontFamily: 'AppFont',
                      color: AppColors.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                  items: [
                    ..._entities.map((e) => DropdownMenuItem<FinancialEntity?>(
                          value: e,
                          child: Text(e.name),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedEntity = v),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: AppColors.primaryBlue, size: 18),
            onPressed: _showNewEntityDialog,
            tooltip: 'Nueva entidad',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined,
              size: 18, color: AppColors.secondaryText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SALDO INICIAL',
                    style: TextStyle(
                        fontFamily: 'AppFont',
                        fontSize: 11,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1)),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _initialBalanceController,
                        focusNode: _balanceFocus,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(
                          fontFamily: 'AppFont',
                          fontSize: 22,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          prefixText: '€ ',
                          prefixStyle: TextStyle(
                            fontFamily: 'AppFont',
                            fontSize: 16,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: DropdownButton<String>(
                        value: _selectedCurrency,
                        underline: const SizedBox(),
                        isDense: true,
                        style: const TextStyle(
                          fontFamily: 'AppFont',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                        items: ['EUR', 'USD', 'GBP']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCurrency = v!),
                      ),
                    ),
                  ],
                ),
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
    final dialogContext = context;
    showDialog(
      context: dialogContext,
      builder: (alertContext) => AlertDialog(
        title: Text(l10n.removeAccount),
        content: Text(l10n.confirmDeleteAccount),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(alertContext), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(alertContext);
              final success = await _apiService.deleteAccount(widget.account!.id);
              if (success && mounted) Navigator.pop(dialogContext, 'deleted');
            },
            child: Text(l10n.closeAccount),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(alertContext);
              final success =
                  await _apiService.deleteAccountPermanently(widget.account!.id);
              if (success && mounted) Navigator.pop(dialogContext, 'deleted');
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
    if (_selectedEntity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar una entidad financiera')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final double val =
          double.tryParse(_initialBalanceController.text.replaceAll(',', '.')) ?? 0.0;
      if (widget.account == null) {
        await _accountRepo.saveAccount(AccountItem(
          id: 0,
          name: _nameController.text,
          description: _descriptionController.text,
          amount: Amount((val * 100).toInt(), _selectedCurrency, val < 0),
          flags: 0,
          accountType: _selectedType,
          notes: _notesController.text,
          entity: _selectedEntity,
        ));
      } else {
        await _accountRepo.updateAccount(AccountItem(
          id: widget.account!.id,
          name: _nameController.text,
          description: _descriptionController.text,
          amount: Amount((val * 100).toInt(), _selectedCurrency, val < 0),
          flags: widget.account!.flags,
          accountType: _selectedType,
          notes: _notesController.text,
          entity: _selectedEntity,
        ));
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
