import 'package:flutter/material.dart';
import '../../../domain/models/account_item.dart';
import '../../../domain/models/transaction_item.dart';
import '../../../domain/models/category.dart';
import '../../../services/api_service.dart';

class TransactionFormScreen extends StatefulWidget {
  final TransactionItem? transaction;
  const TransactionFormScreen({super.key, this.transaction});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final ApiService _apiService = ApiService();
  
  String _selectedTypeLabel = 'EXPENSE'; 
  AccountItem? _selectedAccount;
  AccountItem? _selectedToAccount; 
  Category? _selectedCategory;
  final TextEditingController _amountController = TextEditingController(text: '0.00');
  final TextEditingController _descriptionController = TextEditingController();

  List<AccountItem> _accounts = [];
  List<Category> _allCategories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.transaction != null) {
      _selectedTypeLabel = widget.transaction!.type.name;
      _amountController.text = (widget.transaction!.amount.value / 100).abs().toStringAsFixed(2);
      _descriptionController.text = widget.transaction!.description;
    }
  }

  Future<void> _loadData() async {
    final accs = await _apiService.fetchAccounts();
    final cats = await _apiService.fetchCategories();
    setState(() {
      _accounts = accs;
      _allCategories = cats;

      if (widget.transaction != null) {
        _selectedAccount = _accounts.firstWhere((a) => a.id == widget.transaction!.account.id);
        if (widget.transaction!.toAccount != null) {
          _selectedToAccount = _accounts.firstWhere((a) => a.id == widget.transaction!.toAccount!.id);
        }
        if (widget.transaction!.category != null) {
          _selectedCategory = _allCategories.firstWhere((c) => c.id == widget.transaction!.category!.id);
        }
      } else if (_accounts.isNotEmpty) {
        _selectedAccount = _accounts.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _allCategories
        .where((c) => c.type.name.toUpperCase() == _selectedTypeLabel.toUpperCase())
        .toList();

    Color themeColor = _selectedTypeLabel == 'EXPENSE' 
        ? Colors.redAccent 
        : _selectedTypeLabel == 'INCOME' 
            ? Colors.greenAccent 
            : Colors.blueAccent;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? 'New Transaction' : 'Edit Transaction'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.transaction != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confirmDelete(),
            ),
          TextButton(
            onPressed: () async {
              if (_selectedAccount == null || (_selectedTypeLabel != 'TRANSFER' && _selectedCategory == null) || (_selectedTypeLabel == 'TRANSFER' && _selectedToAccount == null)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select account and category/destination')),
                );
                return;
              }
              
              double amount = double.tryParse(_amountController.text) ?? 0.0;
              
              final transactionData = {
                'amount': {
                  'value': (amount * 100).toInt(),
                  'currency': _selectedAccount!.amount.currency,
                  'isNegative': _selectedTypeLabel == 'EXPENSE',
                },
                'account': {'id': _selectedAccount!.id},
                'toAccount': _selectedTypeLabel == 'TRANSFER' ? {'id': _selectedToAccount!.id} : null,
                'category': _selectedTypeLabel != 'TRANSFER' ? {'id': _selectedCategory!.id} : null,
                'type': _selectedTypeLabel,
                'description': _descriptionController.text,
                'date': widget.transaction?.date ?? DateTime.now().toIso8601String(),
                'statusFlags': 0,
                'isScheduled': false,
                'isHeader': false,
              };

              final result = widget.transaction == null 
                  ? await _apiService.createTransaction(transactionData)
                  : await _apiService.updateTransaction(widget.transaction!.id, transactionData);
              
              if (result != null && mounted) {
                Navigator.of(context).pop(true);
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error saving transaction')),
                );
              }
            },
            child: const Text('SAVE', style: TextStyle(color: Color(0xFF009FFB), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Selector de tipo (Gasto / Ingreso / Transferencia)
            Container(
              color: Colors.white,
              child: Row(
                children: [
                  _buildTypeTab('EXPENSE', 'EXPENSE', Colors.redAccent),
                  _buildTypeTab('INCOME', 'INCOME', Colors.greenAccent),
                  _buildTypeTab('TRANSFER', 'TRANSFER', Colors.blueAccent),
                ],
              ),
            ),
            const Divider(height: 1),
            
            // Campo de Importe
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
              width: double.infinity,
              color: themeColor.withOpacity(0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('AMOUNT', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  TextField(
                    controller: _amountController,
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: themeColor.withOpacity(0.8),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      prefixText: '\$ ',
                      prefixStyle: TextStyle(fontSize: 24, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Selector de Cuenta (Desde)
            _buildSelectionTile(
              label: _selectedTypeLabel == 'TRANSFER' ? 'FROM ACCOUNT' : 'ACCOUNT',
              value: _selectedAccount?.name ?? 'Select...',
              icon: Icons.account_balance_wallet_outlined,
              onTap: () => _showAccountPicker(true),
            ),
            
            _buildDivider(),

            if (_selectedTypeLabel == 'TRANSFER') ...[
              // Selector de Cuenta (Hacia)
              _buildSelectionTile(
                label: 'TO ACCOUNT',
                value: _selectedToAccount?.name ?? 'Select...',
                icon: Icons.swap_horiz_outlined,
                onTap: () => _showAccountPicker(false),
              ),
              _buildDivider(),
            ] else ...[
              // Selector de Categoría
              _buildSelectionTile(
                label: 'CATEGORY',
                value: _selectedCategory?.name ?? 'Select...',
                icon: Icons.category_outlined,
                onTap: () => _showCategoryPicker(filteredCategories),
              ),
              _buildDivider(),
            ],
            
            // Campo de Descripción/Nota
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'DESCRIPTION',
                  labelStyle: TextStyle(fontSize: 12, color: Color(0xFF009FFB), fontWeight: FontWeight.bold),
                  hintText: 'Add a note...',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: InputBorder.none,
                ),
                maxLines: 2,
              ),
            ),
            
            _buildDivider(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTab(String type, String label, Color color) {
    bool isSelected = _selectedTypeLabel == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTypeLabel = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? color : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionTile({required String label, required String value, required IconData icon, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: const Color(0xFF4A636F)),
      title: Text(
        label,
        style: const TextStyle(fontSize: 10, color: Color(0xFF009FFB), fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 16, color: Color(0xFF4A636F)),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 70);

  void _showAccountPicker(bool isFrom) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: _accounts.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(_accounts[index].name),
          onTap: () {
            setState(() {
              if (isFrom) {
                _selectedAccount = _accounts[index];
              } else {
                _selectedToAccount = _accounts[index];
              }
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showCategoryPicker(List<Category> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Select Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF009FFB))),
                        onTap: () {
                          setState(() => _selectedCategory = category);
                          Navigator.pop(context);
                        },
                      ),
                      ...category.subcategories.map((sub) => ListTile(
                        contentPadding: const EdgeInsets.only(left: 32),
                        title: Text(sub.name),
                        leading: const Icon(Icons.subdirectory_arrow_right, size: 16),
                        onTap: () {
                          // Aquí podríamos manejar subcategorías específicamente si el modelo lo soporta,
                          // por ahora seleccionamos la categoría padre para simplificar.
                          setState(() => _selectedCategory = category);
                          _descriptionController.text = sub.name; // Opcional: sugerir subcategoría en descripción
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
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction? The account balance will be reverted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final success = await _apiService.deleteTransaction(widget.transaction!.id);
              if (success && mounted) {
                Navigator.of(context).pop(true); // Close form and trigger refresh
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error deleting transaction')),
                );
              }
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
