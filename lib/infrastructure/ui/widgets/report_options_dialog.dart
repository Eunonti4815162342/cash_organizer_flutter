import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class ReportOptionsDialog extends StatefulWidget {
  final String title;

  const ReportOptionsDialog({super.key, required this.title});

  @override
  State<ReportOptionsDialog> createState() => _ReportOptionsDialogState();
}

class _ReportOptionsDialogState extends State<ReportOptionsDialog> {
  // Valor actualmente seleccionado para el método contable
  String _selectedMethod = 'Method Cash';

  static const _accountingMethods = ['Method Cash', 'Method Accrual'];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.windowBackground,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            // HEADER
            Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: const Color(0xFFE0E0E0),
              child: Row(
                children: [
                  Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                  const Spacer(),
                  _buildHeaderButton('Guardar', AppColors.primaryBlue, true, () => Navigator.pop(context, _selectedMethod)),
                  const SizedBox(width: 8),
                  _buildHeaderButton('Cerrar', Colors.grey.shade400, false, () => Navigator.pop(context)),
                ],
              ),
            ),

            // BODY
            Expanded(
              child: Row(
                children: [
                  // Izquierda: Tabla de opciones
                  Expanded(
                    flex: 8,
                    child: Container(
                      color: AppColors.white,
                      child: Column(
                        children: [
                          Container(
                            height: 35,
                            color: const Color(0xFFF0F0F0),
                            child: Row(
                              children: [
                                _buildInnerTab(Icons.bar_chart, 'Barra', true),
                                _buildInnerTab(Icons.list, 'Lista', false),
                                _buildInnerTab(Icons.settings, 'Personalizar', false),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView(
                              children: [
                                _buildConfigRow('Descripción', widget.title),
                                _buildConfigRow('Accounting Method', _selectedMethod),
                                _buildConfigRow('Fecha', 'Mes anterior - febrero 2026'),
                                _buildConfigRow('Cuenta', 'Todas las cuentas'),
                                _buildConfigRow('Beneficiario', 'Todos los beneficiarios'),
                                _buildConfigRow('Categoría', 'Todas las categorías'),
                                _buildConfigRow('Proyecto', 'Todos los proyectos'),
                                _buildConfigRow('Tag', 'All tags'),
                                _buildConfigRow('Marca', 'Reconciliados y no reconciliados'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Derecha: Panel de personalización
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.sidebarBackground,
                        border: Border(left: BorderSide(color: AppColors.black12)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Accounting Method', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          RadioGroup<String>(
                            groupValue: _selectedMethod,
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedMethod = v);
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _accountingMethods.map((method) => _buildRadioOption(method)).toList(),
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

  Widget _buildHeaderButton(String label, Color color, bool isPrimary, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isPrimary ? color : AppColors.white,
          borderRadius: BorderRadius.circular(4),
          border: isPrimary ? null : Border.all(color: AppColors.black12),
        ),
        child: Text(
          label,
          style: TextStyle(color: isPrimary ? AppColors.white : AppColors.black, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildInnerTab(IconData icon, String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.white : Colors.transparent,
        border: isSelected ? const Border(bottom: BorderSide(color: AppColors.white, width: 2)) : null,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.purple),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0)))),
      child: Row(
        children: [
          Container(
            width: 150,
            padding: const EdgeInsets.all(12),
            alignment: Alignment.centerRight,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFF9F9F9),
              child: Text(value, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String method) {
    return Row(
      children: [
        Radio<String>(value: method),
        Text(method, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
