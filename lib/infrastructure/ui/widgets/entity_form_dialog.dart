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
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _taxIdController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLegal = _selectedType == EntityType.LEGAL;
    final headerIcon = isLegal ? Icons.business_rounded : Icons.person_rounded;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Cabecera coloreada ──────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0077CC), AppColors.primaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            key: ValueKey(_selectedType),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(headerIcon, color: Colors.white, size: 24),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Nueva Entidad',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                          onPressed: () => Navigator.pop(context),
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Selector de tipo como segmented buttons
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        children: [
                          _typeTab('Persona Física', EntityType.PHYSICAL, Icons.person_outline),
                          _typeTab('Entidad Legal', EntityType.LEGAL, Icons.business_outlined),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Campos ─────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    children: [
                      _buildFieldCard(children: [
                        _buildField(Icons.label_outline, 'NOMBRE *', _nameController,
                            hint: isLegal ? 'Nombre de la empresa' : 'Nombre completo',
                            autofocus: true),
                        _divider(),
                        _buildField(Icons.badge_outlined, 'CIF / NIF', _taxIdController,
                            hint: 'Número de identificación fiscal'),
                      ]),
                      const SizedBox(height: 12),
                      _buildFieldCard(children: [
                        _buildField(Icons.notes_outlined, 'DESCRIPCIÓN', _descController,
                            hint: 'Opcional', maxLines: 2),
                      ]),
                    ],
                  ),
                ),
              ),

              // ── Botones ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('CANCELAR',
                            style: TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('GUARDAR',
                                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeTab(String label, EntityType type, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14,
                  color: isSelected ? AppColors.primaryBlue : Colors.white.withValues(alpha: 0.75)),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primaryBlue : Colors.white.withValues(alpha: 0.85),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade200, indent: 16, endIndent: 16);

  Widget _buildField(IconData icon, String label, TextEditingController controller,
      {String? hint, bool autofocus = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Icon(icon, size: 18, color: AppColors.secondaryText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              maxLines: maxLines,
              style: const TextStyle(
                fontFamily: 'AppFont',
                fontSize: 14,
                color: AppColors.primaryText,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(
                  fontFamily: 'AppFont',
                  fontSize: 11,
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
                hintText: hint,
                hintStyle: TextStyle(
                  fontFamily: 'AppFont',
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await _apiService.createEntity({
        'name': _nameController.text,
        'taxId': _taxIdController.text,
        'description': _descController.text,
        'type': _selectedType == EntityType.LEGAL ? 'LEGAL' : 'PHYSICAL',
      });
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
