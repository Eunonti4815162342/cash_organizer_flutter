import 'package:flutter/material.dart';
import '../../../domain/models/transaction_item.dart';
import '../../../services/api_service.dart';
import '../widgets/transaction_list_item.dart';
import 'transaction_form_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<TransactionItem>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _transactionsFuture = _apiService.fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<TransactionItem>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar las transacciones'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay transacciones registradas.'));
          }

          final transactions = snapshot.data!;
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return TransactionListItem(transaction: transaction);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const TransactionFormScreen()),
          );
        },
        backgroundColor: const Color(0xFF009FFB),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
