import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../domain/models/account_item.dart';
import '../../../domain/models/transaction_item.dart';
import '../../../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<AccountItem>> _accountsFuture;
  late Future<List<TransactionItem>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _accountsFuture = _apiService.fetchAccounts();
    _transactionsFuture = _apiService.fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 900;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Botón Nova transação
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text('Nova transação', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009FFB),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
              const SizedBox(height: 20),
              
              isWide 
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildBalanceWidget()),
                      const SizedBox(width: 20),
                      Expanded(child: _buildCategoryChartWidget()),
                    ],
                  )
                : Column(
                    children: [
                      _buildBalanceWidget(),
                      const SizedBox(height: 20),
                      _buildCategoryChartWidget(),
                    ],
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceWidget() {
    return FutureBuilder<List<AccountItem>>(
      future: _accountsFuture,
      builder: (context, snapshot) {
        final accounts = snapshot.data ?? [];
        double total = accounts.fold(0, (sum, item) => sum + item.amount.value);
        
        return _buildDashboardWidget(
          title: 'Saldo da conta "Todas as contas"',
          child: Column(
            children: [
              _buildBalanceRow('Total', '€ ${(total / 100).toStringAsFixed(2)}', isHeader: true, isNegative: total < 0),
              const Divider(),
              ...accounts.map((acc) => _buildBalanceRow(
                acc.name, 
                '€ ${(acc.amount.value / 100).toStringAsFixed(2)}',
                isNegative: acc.amount.isNegative
              )),
              if (accounts.isEmpty) const Center(child: Text('Carregando contas...')),
            ],
          ),
        );
      }
    );
  }

  Widget _buildCategoryChartWidget() {
    return FutureBuilder<List<TransactionItem>>(
      future: _transactionsFuture,
      builder: (context, snapshot) {
        final transactions = snapshot.data ?? [];
        
        // Lógica para agrupar gastos por tags (simplificado para categorías reales luego)
        Map<String, double> data = {};
        for (var t in transactions) {
          if (t.amount.isNegative) {
            String cat = t.tags.isNotEmpty ? t.tags.first : 'Otros';
            data[cat] = (data[cat] ?? 0) + (t.amount.value / 100).abs();
          }
        }

        List<PieChartSectionData> sections = [];
        int i = 0;
        final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
        
        data.forEach((key, value) {
          sections.add(PieChartSectionData(
            color: colors[i % colors.length],
            value: value,
            title: '',
            radius: 30,
          ));
          i++;
        });

        return _buildDashboardWidget(
          title: 'Despesa por categoria Últimos 30 dias',
          child: Column(
            children: [
              SizedBox(
                height: 180,
                child: sections.isEmpty 
                  ? const Center(child: Text('Sem despesas')) 
                  : PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 40, sections: sections)),
              ),
              const SizedBox(height: 20),
              ...data.entries.map((e) => _buildLegendItem(colors[sections.indexWhere((s) => s.value == e.value) % colors.length], e.key, '- € ${e.value.toStringAsFixed(2)}')),
            ],
          ),
        );
      }
    );
  }

  Widget _buildDashboardWidget({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A636F), fontSize: 13)),
                const Icon(Icons.close, size: 14, color: Colors.grey),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16.0), child: child),
        ],
      ),
    );
  }

  Widget _buildBalanceRow(String label, String value, {bool isHeader = false, bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              color: isNegative ? Colors.red : (isHeader ? Colors.black : Colors.grey.shade700),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(width: 10, height: 10, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
        ],
      ),
    );
  }
}
