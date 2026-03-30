import 'package:flutter/material.dart';

class ReportOptionsDialog extends StatelessWidget {
  final String title;

  const ReportOptionsDialog({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            // HEADER (Captura opciones_informe.png)
            Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: const Color(0xFFE0E0E0),
              child: Row(
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A636F))),
                  const Spacer(),
                  _buildHeaderButton('Guardar', const Color(0xFF009FFB), true, () {}),
                  const SizedBox(width: 8),
                  _buildHeaderButton('Cerrar', Colors.grey.shade400, false, () => Navigator.pop(context)),
                ],
              ),
            ),
            
            // BODY (Split view)
            Expanded(
              child: Row(
                children: [
                  // Izquierda: Tabla de opciones
                  Expanded(
                    flex: 8,
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          // Toolbar interna
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
                          // Filas de configuración
                          Expanded(
                            child: ListView(
                              children: [
                                _buildConfigRow('Descripción', title),
                                _buildConfigRow('Accounting Method', 'Method Cash'),
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
                        color: Color(0xFFFBFBFB),
                        border: Border(left: BorderSide(color: Colors.black12)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Accounting Method', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          _buildRadioOption('Method Cash', true),
                          _buildRadioOption('Method Accrual', false),
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
          color: isPrimary ? color : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: isPrimary ? null : Border.all(color: Colors.black12),
        ),
        child: Text(
          label,
          style: TextStyle(color: isPrimary ? Colors.white : Colors.black, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildInnerTab(IconData icon, String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        border: isSelected ? const Border(bottom: BorderSide(color: Colors.white, width: 2)) : null,
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
              child: Text(value, style: const TextStyle(color: Color(0xFF4A636F), fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String label, bool isSelected) {
    return Row(
      children: [
        Radio<bool>(value: true, groupValue: isSelected, onChanged: (v) {}),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
