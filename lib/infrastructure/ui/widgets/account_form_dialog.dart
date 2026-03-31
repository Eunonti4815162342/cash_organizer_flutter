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
    final greyInputStyle = TextStyle(color: Colors.grey.shade600, fontSize: 14);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 100, vertical: 50),
      child: Container(
        width: 1000, 
        height: 600,
        decoration: BoxDecoration(
          color: AppColors.windowBackground,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
        ),
        child: Column(
          children: [
            // HEADER
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                border: Border(bottom: BorderSide(color: Colors.black12)),
              ),
              child: Row(
                children: [
                  Text(widget.account == null ? 'New Account' : 'Edit Account', style: const TextStyle(fontSize: 18, color: AppColors.primaryText)),
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
                          if (widget.account != null && val != (widget.account!.amount.value / 100)) {
                            if ((result.amount.value / 100) != val && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Note: Balance cannot be changed because this account has transactions.')),
                              );
                            }
                          }
                          if (mounted) Navigator.pop(context, true);
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Error: Could not save account')),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(l10n.save, style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.secondaryText),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Container(
                      color: AppColors.cardBackground,
                      child: Column(
                        children: [
                          Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('Property', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
                                    Container(height: 2, width: 80, color: AppColors.primaryBlue),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView(
                              children: [
                                _buildInputRow('Entity', Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButton<FinancialEntity>(
                                        value: _selectedEntity,
                                        isExpanded: true,
                                        underline: const SizedBox(),
                                        hint: const Text('Select Entity...'),
                                        items: _entities.map((e) => DropdownMenuItem(value: e, child: Text(e.name, style: greyInputStyle))).toList(),
                                        onChanged: (v) => setState(() => _selectedEntity = v),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryBlue),
                                      onPressed: _showNewEntityDialog,
                                    ),
                                  ],
                                )),
                                _buildInputRow('Name*', TextField(
                                  controller: _nameController,
                                  focusNode: _nameFocus,
                                  style: greyInputStyle,
                                  decoration: const InputDecoration(hintText: 'Account name', border: InputBorder.none),
                                )),
                                _buildInputRow('Description', TextField(
                                  controller: _descriptionController,
                                  focusNode: _descFocus,
                                  style: greyInputStyle,
                                  decoration: const InputDecoration(hintText: 'Optional description', border: InputBorder.none),
                                )),
                                _buildInputRow('Currency', DropdownButton<String>(
                                  value: _selectedCurrency,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: ['EUR', 'USD', 'GBP'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: greyInputStyle))).toList(),
                                  onChanged: (v) => setState(() => _selectedCurrency = v!),
                                )),
                                _buildInputRow('Type', DropdownButton<String>(
                                  value: _selectedType,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: [
                                    DropdownMenuItem(value: 'CASH', child: Text('Cash', style: greyInputStyle)),
                                    DropdownMenuItem(value: 'BANK', child: Text('Bank', style: greyInputStyle)),
                                    DropdownMenuItem(value: 'CARD', child: Text('Card', style: greyInputStyle)),
                                  ],
                                  onChanged: (v) => setState(() => _selectedType = v!),
                                )),
                                _buildInputRow('Initial Balance', TextField(
                                  controller: _initialBalanceController,
                                  focusNode: _balanceFocus,
                                  style: greyInputStyle,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(border: InputBorder.none),
                                )),
                                _buildInputRow('Notes', TextField(
                                  controller: _notesController,
                                  focusNode: _notesFocus,
                                  style: greyInputStyle,
                                  maxLines: 3,
                                  decoration: const InputDecoration(border: InputBorder.none),
                                )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.sidebarBackground,
                        border: Border(left: BorderSide(color: Colors.black12)),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Account Properties', style: TextStyle(fontSize: 16, color: AppColors.secondaryText)),
                          const SizedBox(height: 30),
                          _buildPropertyItem('Name', _nameController.text.isEmpty ? 'New Account' : _nameController.text, isBoldValue: true),
                          _buildPropertyItem('Currency', _selectedCurrency, isBoldValue: true),
                          _buildPropertyItem('Total Balance', '€ ${_initialBalanceController.text}', valueColor: Colors.black, isBoldValue: true),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {},
                              child: const Text('New Transaction', style: TextStyle(color: AppColors.primaryText)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow(String label, Widget input) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
      child: Row(
        children: [
          Container(
            width: 150,
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerRight,
            child: Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 14)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: const Color(0xFFF9F9F9),
              child: input,
            ),
          ),
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
          Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
          Text(value, style: TextStyle(color: valueColor ?? AppColors.primaryText, fontSize: 15, fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
