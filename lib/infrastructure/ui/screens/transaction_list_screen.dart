import 'package:flutter/material.dart';
import '../../../domain/models/transaction_item.dart';
import '../../../services/api_service.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/transaction_list_item.dart';
import 'transaction_form_screen.dart';
import '../styles/app_styles.dart';

class TransactionListScreen extends StatefulWidget {
  final String? accountId;
  const TransactionListScreen({super.key, this.accountId});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<TransactionItem>> _transactionsFuture;
  DateTime _currentMonth = DateTime.now();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshTransactions();
  }

  @override
  void didUpdateWidget(TransactionListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountId != widget.accountId) {
      _refreshTransactions();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshTransactions() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0, 23, 59, 59);
    
    setState(() {
      _transactionsFuture = _apiService.fetchTransactions(
        startDate: firstDay.toIso8601String(),
        endDate: lastDay.toIso8601String(),
        accountId: widget.accountId,
      );
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta);
    });
    _refreshTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final monthName = _getMonthName(_currentMonth.month, l10n);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Column(
          children: [
            Container(
              height: 50, color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
                  Text('$monthName ${_currentMonth.year}'.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
                ],
              ),
            ),
            Container(
              height: 50, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: const Color(0xFFF5F5F5),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: l10n.search,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) : null,
                  filled: true, fillColor: Colors.white, contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<TransactionItem>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final allTransactions = snapshot.data ?? [];
          final filteredTransactions = allTransactions.where((tx) {
            final desc = tx.description.toLowerCase();
            final cat = (tx.category?.name ?? 'General').toLowerCase();
            return desc.contains(_searchQuery) || cat.contains(_searchQuery);
          }).toList();

          if (filteredTransactions.isEmpty) return Center(child: Text(_searchQuery.isEmpty ? l10n.noData : '${l10n.noData}: "$_searchQuery"'));

          return ListView.builder(
            itemCount: filteredTransactions.length,
            itemBuilder: (context, index) => TransactionListItem(transaction: filteredTransactions[index], onRefresh: _refreshTransactions),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TransactionFormScreen())).then((saved) { if (saved == true) _refreshTransactions(); });
        },
        backgroundColor: const Color(0xFF009FFB),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _getMonthName(int month, AppLocalizations l10n) {
    // Ideally these would be in ARB, but for now we keep it simple or use intl
    const names = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return names[month - 1];
  }
}
