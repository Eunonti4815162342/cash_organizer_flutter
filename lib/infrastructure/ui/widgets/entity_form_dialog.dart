import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../../../services/api_service.dart';
import '../../../domain/models/financial_entity.dart';

class EntityFormDialog extends StatefulWidget {
  const EntityFormDialog({super.key});

  @override
  State<EntityFormDialog> createState() => _EntityFormDialogState();
}

class _EntityFormDialogState extends State<EntityFormDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _taxIdController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  EntityType _selectedType = EntityType.PHYSICAL;

  @override
  void dispose() {
    _nameController.dispose();
    _taxIdController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.business_outlined, color: AppColors.primaryBlue, size: 22),
                ),
                const SizedBox(width: 12),
                const Text('Nueva Entidad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildField(Icons.label_outline, 'Nombre*', _nameController),
                  Divider(height: 1, color: Colors.grey.shade200),
                  _buildField(Icons.badge_outlined, 'CIF / NIF', _taxIdController),
                  Divider(height: 1, color: Colors.grey.shade200),
                  _buildField(Icons.notes_outlined, 'Descripción', _descController),
                  Divider(height: 1, color: Colors.grey.shade200),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.category_outlined, size: 20, color: AppColors.secondaryText),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<EntityType>(
                            initialValue: _selectedType,
                            decoration: const InputDecoration(
                              labelText: 'TIPO',
                              labelStyle: TextStyle(fontSize: 11, color: AppColors.primaryBlue, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                              border: InputBorder.none,
                            ),
                            items: const [
                              DropdownMenuItem(value: EntityType.PHYSICAL, child: Text('Persona Física')),
                              DropdownMenuItem(value: EntityType.LEGAL, child: Text('Entidad Legal')),
                            ],
                            onChanged: (v) => setState(() => _selectedType = v!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('CANCELAR', style: TextStyle(color: AppColors.secondaryText)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_nameController.text.isNotEmpty) {
                        await _apiService.createEntity({
                          'name': _nameController.text,
                          'taxId': _taxIdController.text,
                          'description': _descController.text,
                          'type': _selectedType == EntityType.LEGAL ? 'LEGAL' : 'PHYSICAL',
                        });
                        if (mounted) Navigator.pop(context, true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('GUARDAR', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(IconData icon, String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.secondaryText),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label.toUpperCase(),
                labelStyle: const TextStyle(fontSize: 11, color: AppColors.primaryBlue, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                border: InputBorder.none,
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
