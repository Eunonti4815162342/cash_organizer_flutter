import 'package:flutter/material.dart';
import '../widgets/report_options_dialog.dart';

class ReportsListScreen extends StatelessWidget {
  const ReportsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tabs superiores (Captura informe.png)
        Container(
          height: 40,
          color: const Color(0xFFF5F5F5),
          child: Row(
            children: [
              _buildTab('Base', true),
              _buildTab('Personal', false),
              const Spacer(),
              const Icon(Icons.settings_outlined, color: Colors.grey, size: 20),
              const SizedBox(width: 16),
            ],
          ),
        ),
        const Divider(height: 1),
        
        // Contenido principal con Sidebar de Propiedades
        Expanded(
          child: Row(
            children: [
              // Lista de informes
              Expanded(
                flex: 7,
                child: Container(
                  color: Colors.white,
                  child: ListView(
                    children: [
                      _buildReportItem(context, 'Informe de patrimonio neto', 'Patrimonio mensual basado en saldos de cuenta'),
                      _buildReportItem(context, 'Informe de saldo de cuenta', 'Resumen de Saldos de cuenta'),
                      _buildReportItem(context, 'Informe de beneficiario', 'Ingresos y Gastos, agrupados por beneficiario'),
                      _buildReportItem(context, 'Estado de pérdidas y ganancias', 'Pérdidas y ganancias mensuales'),
                      _buildReportItem(context, 'Informe de categoría', 'Resumen de ingresos y gastos basado en categorías'),
                      _buildReportItem(context, 'Informe mensual de Categoría', 'Informe mensual de ingresos y gastos basado en categorías'),
                      _buildReportItem(context, 'Informe de proyecto', 'Resumen de ingresos y gastos basado en proyectos'),
                    ],
                  ),
                ),
              ),
              
              // Panel derecho de Propiedades (Captura informe.png)
              Expanded(
                flex: 3,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFBFBFB),
                    border: Border(left: BorderSide(color: Colors.black12)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Propiedades de Informe', style: TextStyle(fontSize: 16, color: Color(0xFF4A636F))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: isSelected ? const Color(0xFF606060) : Colors.transparent,
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF4A636F),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildReportItem(BuildContext context, String title, String subtitle) {
    return InkWell(
      onTap: () => _showReportOptions(context, title),
      child: Container(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0)))),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.pie_chart, color: Colors.purple, size: 30),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4A636F))),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReportOptions(BuildContext context, String reportTitle) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReportOptionsDialog(title: reportTitle),
    );
  }
}
