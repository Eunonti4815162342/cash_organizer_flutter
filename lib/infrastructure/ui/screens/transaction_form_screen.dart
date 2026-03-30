import 'package:flutter/material.dart';
import '../../../domain/models/account_item.dart';
import '../../../domain/models/category.dart';
import '../../../services/api_service.dart';

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final ApiService _apiService = ApiService();
  
  CategoryType _selectedType = CategoryType.expense;
  AccountItem? _selectedAccount;
  Category? _selectedCategory;
  final TextEditingController _amountController = TextEditingController(text: '0.00');
  final TextEditingController _descriptionController = TextEditingController();

  List<AccountItem> _accounts = [];
  List<Category> _allCategories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final accs = await _apiService.fetchAccounts();
    final cats = await _apiService.fetchCategories();
    setState(() {
      _accounts = accs;
      _allCategories = cats;
      if (_accounts.isNotEmpty) _selectedAccount = _accounts.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _allCategories
        .where((c) => c.type == _selectedType)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Movimiento'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Lógica para guardar la transacción
              Navigator.of(context).pop();
            },
            child: const Text('GUARDAR', style: TextStyle(color: Color(0xFF009FFB), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Selector de tipo (Gasto / Ingreso) - Estilo original
            Container(
              color: Colors.white,
              child: Row(
                children: [
                  _buildTypeTab(CategoryType.expense, 'GASTO', Colors.redAccent),
                  _buildTypeTab(CategoryType.income, 'INGRESO', Colors.greenAccent),
                ],
              ),
            ),
            const Divider(height: 1),
            
            // Campo de Importe
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
              width: double.infinity,
              color: _selectedType == CategoryType.expense ? Colors.red.shade50 : Colors.green.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('IMPORTE', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  TextField(
                    controller: _amountController,
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: _selectedType == CategoryType.expense ? Colors.red.shade700 : Colors.green.shade700,
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
            
            // Selector de Cuenta
            _buildSelectionTile(
              label: 'CUENTA',
              value: _selectedAccount?.name ?? 'Seleccionar...',
              icon: Icons.account_balance_wallet_outlined,
              onTap: () => _showAccountPicker(),
            ),
            
            _buildDivider(),
            
            // Selector de Categoría
            _buildSelectionTile(
              label: 'CATEGORÍA',
              value: _selectedCategory?.name ?? 'Seleccionar...',
              icon: Icons.category_outlined,
              onTap: () => _showCategoryPicker(filteredCategories),
            ),
            
            _buildDivider(),
            
            // Campo de Descripción/Nota
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'DESCRIPCIÓN',
                  labelStyle: TextStyle(fontSize: 12, color: Color(0xFF009FFB), fontWeight: FontWeight.bold),
                  hintText: 'Añadir una nota...',
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

  Widget _buildTypeTab(CategoryType type, String label, Color color) {
    bool isSelected = _selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
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

  void _showAccountPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: _accounts.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(_accounts[index].name),
          onTap: () {
            setState(() => _selectedAccount = _accounts[index]);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showCategoryPicker(List<Category> categories) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(categories[index].name),
          onTap: () {
            setState(() => _selectedCategory = categories[index]);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
