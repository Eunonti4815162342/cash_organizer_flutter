import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/api_service.dart';
import '../../../domain/models/account_item.dart';
import '../../../domain/models/financial_entity.dart';
import 'entity_form_dialog.dart';

class AccountFormDialog extends StatefulWidget {
  final AccountItem? account;
  const AccountFormDialog({super.key, this.account});

  @override
  State<AccountFormDialog> createState() => _AccountFormDialogState();
}

class _AccountFormDialogState extends State<AccountFormDialog> {
  final ApiService _apiService = ApiService();
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
      _selectedEntity = widget.account!.entity;
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
    final isMobile = MediaQuery.of(context).size.width < 800;
    final greyInputStyle = TextStyle(color: Colors.grey.shade600, fontSize: 14);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: isMobile ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 100, vertical: 50),
      child: Container(
        width: isMobile ? double.infinity : 1000, 
        height: isMobile ? double.infinity : 600,
        decoration: BoxDecoration(
          color: AppColors.windowBackground,
          borderRadius: BorderRadius.circular(isMobile ? 0 : 8),
          boxShadow: isMobile ? null : const [BoxShadow(color: Colors.black26, blurRadius: 20)],
        ),
        child: Column(
          children: [
            // HEADER
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(bottom: BorderSide(color: Colors.black12)),
              ),
              child: Row(
                children: [
                  if (isMobile) IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
                  Text(widget.account == null ? l10n.newAccount : l10n.editAccount, style: const TextStyle(fontSize: 18, color: AppColors.primaryText, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () async {
                      if (_nameController.text.isNotEmpty) {
                        double val = double.tryParse(_initialBalanceController.text) ?? 0.0;
                        final data = {
                          'name': _nameController.text,
                          'description': _descriptionController.text,
                          'amount': {
                            'value': (val * 100).toInt(),
                            'currency': _selectedCurrency,
                            'isNegative': val < 0
                          },
                          'accountType': _selectedType,
                          'notes': _notesController.text,
                          'flags': widget.account?.flags ?? 0,
                          'accountOrder': widget.account?.accountOrder ?? 0,
                          'active': true,
                          'entity': _selectedEntity != null ? {'id': _selectedEntity!.id} : null
                        };

                        final result = widget.account == null
                            ? await _apiService.createAccount(data)
                            : await _apiService.updateAccount(widget.account!.id, data);

                        if (result != null) {
                          if (mounted) Navigator.pop(context, true);
                        } else {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noData)));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                    child: Text(l10n.save, style: const TextStyle(color: Colors.white)),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 10),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ]
                ],
              ),
            ),
            
            Expanded(
              child: isMobile 
                ? _buildMobileForm(l10n, greyInputStyle) 
                : _buildDesktopForm(l10n, greyInputStyle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopForm(AppLocalizations l10n, TextStyle style) {
    return Row(
      children: [
        Expanded(flex: 6, child: _buildFormFields(l10n, style)),
        Expanded(flex: 4, child: _buildPropertiesSidebar(l10n)),
      ],
    );
  }

  Widget _buildMobileForm(AppLocalizations l10n, TextStyle style) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildFormFields(l10n, style),
          const Divider(),
          _buildPropertiesSidebar(l10n),
        ],
      ),
    );
  }

  Widget _buildFormFields(AppLocalizations l10n, TextStyle style) {
    return Container(
      color: AppColors.cardBackground,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              children: [
                _buildInputRow(l10n.entity, Row(
                  children: [
                    Expanded(
                      child: DropdownButton<FinancialEntity?>(
                        value: _selectedEntity,
                        isExpanded: true,
                        underline: const SizedBox(),
                        hint: const Text('Select Entity...'),
                        items: [
                          const DropdownMenuItem<FinancialEntity?>(
                            value: null,
                            child: Text('None / Individual', style: TextStyle(color: Colors.grey)),
                          ),
                          ..._entities.map((e) => DropdownMenuItem<FinancialEntity?>(
                            value: e,
                            child: Text(e.name, style: style),
                          )),
                        ],
                        onChanged: (v) => setState(() => _selectedEntity = v),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryBlue), onPressed: _showNewEntityDialog),
                  ],
                )),
                _buildInputRow('Name*', TextField(controller: _nameController, focusNode: _nameFocus, style: style, decoration: const InputDecoration(hintText: 'Account name', border: InputBorder.none))),
                _buildInputRow(l10n.description, TextField(controller: _descriptionController, focusNode: _descFocus, style: style, decoration: const InputDecoration(hintText: 'Optional description', border: InputBorder.none))),
                _buildInputRow('Currency', DropdownButton<String>(value: _selectedCurrency, isExpanded: true, underline: const SizedBox(), items: ['EUR', 'USD', 'GBP'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: style))).toList(), onChanged: (v) => setState(() => _selectedCurrency = v!))),
                _buildInputRow(l10n.type, DropdownButton<String>(value: _selectedType, isExpanded: true, underline: const SizedBox(), items: [
                  DropdownMenuItem(value: 'CASH', child: Text('Cash', style: style)),
                  DropdownMenuItem(value: 'BANK', child: Text('Bank', style: style)),
                  DropdownMenuItem(value: 'CARD', child: Text('Card', style: style)),
                ], onChanged: (v) => setState(() => _selectedType = v!))),
                _buildInputRow(l10n.initialBalance, TextField(controller: _initialBalanceController, focusNode: _balanceFocus, style: style, keyboardType: TextInputType.number, decoration: const InputDecoration(border: InputBorder.none))),
                _buildInputRow(l10n.notes, TextField(controller: _notesController, focusNode: _notesFocus, style: style, maxLines: 3, decoration: const InputDecoration(border: InputBorder.none))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesSidebar(AppLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.sidebarBackground),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.accountProperties, style: const TextStyle(fontSize: 16, color: AppColors.secondaryText, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildPropertyItem(l10n.accountName, _nameController.text.isEmpty ? 'New Account' : _nameController.text, isBoldValue: true),
          _buildPropertyItem('Currency', _selectedCurrency, isBoldValue: true),
          _buildPropertyItem(l10n.totalBalance, '€ ${_initialBalanceController.text}', valueColor: Colors.black, isBoldValue: true),
        ],
      ),
    );
  }

  Widget _buildInputRow(String label, Widget input) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
      child: Row(
        children: [
          Container(width: 120, padding: const EdgeInsets.all(16), alignment: Alignment.centerRight, child: Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13))),
          Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16), color: const Color(0xFFF9F9F9), child: input)),
        ],
      ),
    );
  }

  Widget _buildPropertyItem(String label, String value, {Color? valueColor, bool isBoldValue = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
          Text(value, style: TextStyle(color: valueColor ?? AppColors.primaryText, fontSize: 14, fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
