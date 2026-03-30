import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/api_service.dart';

class AccountFormDialog extends StatefulWidget {
  const AccountFormDialog({super.key});

  @override
  State<AccountFormDialog> createState() => _AccountFormDialogState();
}

class _AccountFormDialogState extends State<AccountFormDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _initialBalanceController = TextEditingController(text: '0.00');
  final TextEditingController _notesController = TextEditingController();
  
  String _selectedCurrency = 'EUR';
  String _selectedType = 'Dinheiro';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                  Text(l10n.accounts, style: const TextStyle(fontSize: 18, color: AppColors.primaryText)),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () async {
                      if (_nameController.text.isNotEmpty) {
                        double val = double.tryParse(_initialBalanceController.text) ?? 0.0;
                        await _apiService.createAccount({
                          'name': _nameController.text,
                          'description': _descriptionController.text,
                          'amount': {
                            'value': (val * 100).toInt(),
                            'currency': _selectedCurrency,
                            'isNegative': val < 0
                          },
                          'accountType': _selectedType,
                          'notes': _notesController.text,
                          'flags': 0
                        });
                        if (mounted) Navigator.pop(context, true);
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
                  // FORMULARIO
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
                                    const Text('Propriedade', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
                                    Container(height: 2, width: 80, color: AppColors.primaryBlue),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                const Text('Compartilhar', style: TextStyle(color: AppColors.secondaryText)),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView(
                              children: [
                                _buildInputRow('Nome*', TextField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(hintText: 'Nome da conta', border: InputBorder.none),
                                )),
                                _buildInputRow(l10n.description, TextField(
                                  controller: _descriptionController,
                                  decoration: const InputDecoration(hintText: 'Descrição opcional', border: InputBorder.none),
                                )),
                                _buildInputRow('Moeda', DropdownButton<String>(
                                  value: _selectedCurrency,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: ['EUR', 'USD', 'GBP'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                  onChanged: (v) => setState(() => _selectedCurrency = v!),
                                )),
                                _buildInputRow('Tipo', DropdownButton<String>(
                                  value: _selectedType,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: ['Dinheiro', 'Banco', 'Cartão'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                  onChanged: (v) => setState(() => _selectedType = v!),
                                )),
                                _buildInputRow('Saldo inicial', TextField(
                                  controller: _initialBalanceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(border: InputBorder.none),
                                )),
                                _buildInputRow('Nota', TextField(
                                  controller: _notesController,
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
                  
                  // PANEL DE PROPIEDADES
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
                          const Text('Propriedades da conta', style: TextStyle(fontSize: 16, color: AppColors.secondaryText)),
                          const SizedBox(height: 30),
                          _buildPropertyItem('Nome', _nameController.text.isEmpty ? 'Nueva conta' : _nameController.text, isBoldValue: true),
                          _buildPropertyItem('Moeda', _selectedCurrency, isBoldValue: true),
                          _buildPropertyItem('Saldo Total', '€ ${_initialBalanceController.text}', valueColor: Colors.black, isBoldValue: true),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {},
                              child: const Text('Nova transação', style: TextStyle(color: AppColors.primaryText)),
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
