import 'package:flutter/material.dart';
import '../../../domain/models/account_item.dart';
import '../../../domain/models/transaction_item.dart';
import '../../../domain/models/category.dart';
import '../../../services/api_service.dart';
import '../../../l10n/app_localizations.dart';

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
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _amountController = TextEditingController(text: '0.00');
  final TextEditingController _descriptionController = TextEditingController();
  
  final FocusNode _amountFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();

  List<AccountItem> _accounts = [];
  List<Category> _allCategories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _amountFocus.addListener(() { if (_amountFocus.hasFocus && (_amountController.text == '0.00' || _amountController.text == '0')) _amountController.clear(); });
    _descriptionFocus.addListener(() { if (_descriptionFocus.hasFocus) _descriptionController.clear(); });

    if (widget.transaction != null) {
      _selectedTypeLabel = widget.transaction!.type.name;
      _amountController.text = (widget.transaction!.amount.value / 100).abs().toStringAsFixed(2);
      _descriptionController.text = widget.transaction!.description;
      _selectedDate = DateTime.parse(widget.transaction!.date);
    }
  }

  @override
  void dispose() {
    _amountFocus.dispose();
    _descriptionFocus.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final accs = await _apiService.fetchAccounts();
    final cats = await _apiService.fetchCategories();
    setState(() {
      _accounts = accs;
      _allCategories = cats;
      if (widget.transaction != null) {
        _selectedAccount = _accounts.firstWhere((a) => a.id == widget.transaction!.account.id);
        if (widget.transaction!.toAccount != null) _selectedToAccount = _accounts.firstWhere((a) => a.id == widget.transaction!.toAccount!.id);
        if (widget.transaction!.category != null) _selectedCategory = _allCategories.firstWhere((c) => c.id == widget.transaction!.category!.id);
      } else if (_accounts.isNotEmpty) {
        _selectedAccount = _accounts.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filteredCategories = _allCategories.where((c) => c.type.name.toUpperCase() == _selectedTypeLabel.toUpperCase()).toList();
    Color themeColor = _selectedTypeLabel == 'EXPENSE' ? Colors.redAccent : _selectedTypeLabel == 'INCOME' ? Colors.greenAccent : Colors.blueAccent;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? l10n.newTransaction : l10n.editTransaction),
        actions: [
          if (widget.transaction != null) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _confirmDelete(l10n)),
          TextButton(onPressed: () => _save(l10n), child: Text(l10n.save.toUpperCase(), style: const TextStyle(color: Color(0xFF009FFB), fontWeight: FontWeight.bold))),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(color: Colors.white, child: Row(children: [
              _buildTypeTab('EXPENSE', l10n.expense.toUpperCase(), Colors.redAccent),
              _buildTypeTab('INCOME', l10n.income.toUpperCase(), Colors.greenAccent),
              _buildTypeTab('TRANSFER', l10n.transfer.toUpperCase(), Colors.blueAccent),
            ])),
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16), width: double.infinity, color: themeColor.withOpacity(0.05),
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(l10n.amount.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                TextField(
                  controller: _amountController, focusNode: _amountFocus, textAlign: TextAlign.right, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: themeColor.withOpacity(0.6)),
                  decoration: const InputDecoration(border: InputBorder.none, prefixText: '€ ', prefixStyle: TextStyle(fontSize: 24, color: Colors.grey)),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            _buildSelectionTile(label: _selectedTypeLabel == 'TRANSFER' ? 'FROM ${l10n.accounts.toUpperCase()}' : l10n.accounts.toUpperCase(), value: _selectedAccount?.name ?? 'Select...', icon: Icons.account_balance_wallet_outlined, onTap: () => _showAccountPicker(true, l10n)),
            _buildDivider(),
            _buildSelectionTile(label: l10n.date.toUpperCase(), value: "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}", icon: Icons.calendar_today_outlined, onTap: () => _showDatePicker()),
            _buildDivider(),
            if (_selectedTypeLabel == 'TRANSFER') ...[
              _buildSelectionTile(label: 'TO ${l10n.accounts.toUpperCase()}', value: _selectedToAccount?.name ?? 'Select...', icon: Icons.swap_horiz_outlined, onTap: () => _showAccountPicker(false, l10n)),
              _buildDivider(),
            ] else ...[
              _buildSelectionTile(label: l10n.categories.toUpperCase(), value: _selectedCategory?.name ?? 'Select...', icon: Icons.category_outlined, onTap: () => _showCategoryPicker(filteredCategories, l10n)),
              _buildDivider(),
            ],
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child: TextField(
              controller: _descriptionController, focusNode: _descriptionFocus, style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              decoration: InputDecoration(labelText: l10n.description.toUpperCase(), labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF009FFB), fontWeight: FontWeight.bold), hintText: 'Add a note...', floatingLabelBehavior: FloatingLabelBehavior.always, border: InputBorder.none),
              maxLines: 2,
            )),
            _buildDivider(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTab(String type, String label, Color color) {
    bool isSelected = _selectedTypeLabel == type;
    return Expanded(child: InkWell(onTap: () => setState(() => _selectedTypeLabel = type), child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isSelected ? color : Colors.transparent, width: 3))),
      child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? color : Colors.grey, fontSize: 12))),
    )));
  }

  Widget _buildSelectionTile({required String label, required String value, required IconData icon, required VoidCallback onTap}) {
    return ListTile(onTap: onTap, leading: Icon(icon, color: const Color(0xFF4A636F)), title: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF009FFB), fontWeight: FontWeight.bold)), subtitle: Text(value, style: const TextStyle(fontSize: 16, color: Color(0xFF4A636F))), trailing: const Icon(Icons.chevron_right, color: Colors.grey));
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 70);

  Future<void> _save(AppLocalizations l10n) async {
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    final transactionData = {
      'amount': {'value': (amount * 100).toInt(), 'currency': _selectedAccount!.amount.currency, 'isNegative': _selectedTypeLabel == 'EXPENSE'},
      'account': {'id': _selectedAccount!.id},
      'toAccount': _selectedTypeLabel == 'TRANSFER' ? {'id': _selectedToAccount!.id} : null,
      'category': _selectedTypeLabel != 'TRANSFER' ? {'id': _selectedCategory!.id} : null,
      'type': _selectedTypeLabel, 'description': _descriptionController.text, 'date': _selectedDate.toIso8601String(), 'statusFlags': 0, 'isScheduled': false, 'isHeader': false,
    };
    final result = widget.transaction == null ? await _apiService.createTransaction(transactionData) : await _apiService.updateTransaction(widget.transaction!.id, transactionData);
    if (result != null && mounted) Navigator.of(context).pop(true);
  }

  void _showAccountPicker(bool isFrom, AppLocalizations l10n) {
    String search = '';
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => StatefulBuilder(builder: (context, setPickerState) => Container(height: MediaQuery.of(context).size.height * 0.7, child: Column(children: [
      Padding(padding: const EdgeInsets.all(16.0), child: TextField(onChanged: (v) => setPickerState(() => search = v.toLowerCase()), decoration: InputDecoration(hintText: l10n.search, prefixIcon: const Icon(Icons.search)))),
      Expanded(child: ListView.builder(itemCount: _accounts.length, itemBuilder: (context, index) {
        final acc = _accounts[index]; if (search.isNotEmpty && !acc.name.toLowerCase().contains(search)) return const SizedBox();
        return ListTile(title: Text(acc.name), onTap: () { setState(() { if (isFrom) _selectedAccount = acc; else _selectedToAccount = acc; }); Navigator.pop(context); });
      })),
    ]))));
  }

  void _showCategoryPicker(List<Category> categories, AppLocalizations l10n) {
    String search = '';
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => StatefulBuilder(builder: (context, setPickerState) => Container(height: MediaQuery.of(context).size.height * 0.7, child: Column(children: [
      Padding(padding: const EdgeInsets.all(16.0), child: TextField(onChanged: (v) => setPickerState(() => search = v.toLowerCase()), decoration: InputDecoration(hintText: l10n.search, prefixIcon: const Icon(Icons.search)))),
      Expanded(child: ListView.builder(itemCount: categories.length, itemBuilder: (context, index) {
        final category = categories[index]; final filteredSubs = category.subcategories.where((s) => s.name.toLowerCase().contains(search)).toList();
        if (search.isNotEmpty && !category.name.toLowerCase().contains(search) && filteredSubs.isEmpty) return const SizedBox();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ListTile(title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF009FFB))), onTap: () { setState(() => _selectedCategory = category); Navigator.pop(context); }),
          ...filteredSubs.map((sub) => ListTile(contentPadding: const EdgeInsets.only(left: 32), title: Text(sub.name), leading: const Icon(Icons.subdirectory_arrow_right, size: 16), onTap: () { setState(() => _selectedCategory = category); _descriptionController.text = sub.name; Navigator.pop(context); })),
          const Divider(),
        ]);
      })),
    ]))));
  }

  Future<void> _showDatePicker() async {
    final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2101));
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _confirmDelete(AppLocalizations l10n) {
    showDialog(context: context, builder: (context) => AlertDialog(title: Text(l10n.delete), content: Text(l10n.confirmDeleteTransaction), actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
      TextButton(onPressed: () async { Navigator.pop(context); final success = await _apiService.deleteTransaction(widget.transaction!.id); if (success && mounted) Navigator.of(context).pop(true); }, child: Text(l10n.delete, style: const TextStyle(color: Colors.redAccent))),
    ]));
  }
}
