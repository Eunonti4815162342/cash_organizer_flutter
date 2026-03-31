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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Entity'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name*')),
            TextField(controller: _taxIdController, decoration: const InputDecoration(labelText: 'Tax ID (CIF/NIF)')),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 16),
            DropdownButtonFormField<EntityType>(
              value: _selectedType,
              items: const [
                DropdownMenuItem(value: EntityType.PHYSICAL, child: Text('Physical Person')),
                DropdownMenuItem(value: EntityType.LEGAL, child: Text('Legal Entity')),
              ],
              onChanged: (v) => setState(() => _selectedType = v!),
              decoration: const InputDecoration(labelText: 'Entity Type'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        ElevatedButton(
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
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
          child: const Text('SAVE', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
