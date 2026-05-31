import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../styles/app_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/financial_entity.dart';
import '../../../domain/repositories/category_repository.dart';
import '../../../domain/repositories/entity_repository.dart';

class CategoryFormDialog extends StatefulWidget {
  final Category? category;
  final Subcategory? subcategory;
  final int? parentCategoryId;

  const CategoryFormDialog({super.key, this.category, this.subcategory, this.parentCategoryId});
  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  late final ICategoryRepository _categoryRepo;
  late final IEntityRepository _entityRepo;
  late TextEditingController _nameController;
  CategoryType _selectedType = CategoryType.expense;
  FinancialEntity? _selectedEntity;
  int? _selectedParentId;
  List<FinancialEntity> _entities = [];
  bool _isLoading = false;

  bool get _isSubcategory => _selectedParentId != null || widget.subcategory != null;
  bool get _isEditing => widget.category != null || widget.subcategory != null;

  @override
  void initState() {
    super.initState();
    _categoryRepo = GetIt.instance.get<ICategoryRepository>();
    _entityRepo = GetIt.instance.get<IEntityRepository>();
    _nameController = TextEditingController(text: widget.category?.name ?? widget.subcategory?.name ?? '');

    if (widget.category != null) {
      _selectedType = widget.category!.type;
      _selectedEntity = widget.category!.financialEntity;
    } else if (widget.parentCategoryId != null || widget.subcategory != null) {
      _selectedParentId = widget.parentCategoryId;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final ents = await _entityRepo.fetchEntities();
      if (mounted) {
        setState(() {
          _entities = ents;
          if (_selectedEntity != null) {
            _selectedEntity = _entities.firstWhere(
              (e) => e.id == _selectedEntity!.id,
              orElse: () => _selectedEntity!,
            );
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titleKey = _isEditing
        ? (_isSubcategory ? 'Editar subcategoría' : 'Editar categoría')
        : (_isSubcategory ? 'Nueva subcategoría' : 'Nueva categoría');
    final icon = _isSubcategory ? Icons.subdirectory_arrow_right : Icons.category_outlined;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primaryBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titleKey,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppColors.secondaryText),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Fields
            Card(
              elevation: 0,
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildField(
                    icon: Icons.label_outline,
                    label: '${l10n.categoryName.toUpperCase()}*',
                    child: TextField(
                      controller: _nameController,
                      autofocus: true,
                      style: const TextStyle(fontSize: 14, color: AppColors.primaryText, fontWeight: FontWeight.w500),
                      decoration: const InputDecoration(
                        hintText: 'Escribe el nombre',
                        border: InputBorder.none,
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                      ),
                    ),
                  ),
                  if (!_isSubcategory) ...[
                    Divider(height: 1, color: Colors.grey.shade200),
                    _buildField(
                      icon: Icons.swap_vert_outlined,
                      label: l10n.type.toUpperCase(),
                      child: DropdownButton<CategoryType>(
                        value: _selectedType,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: [
                          DropdownMenuItem(
                            value: CategoryType.expense,
                            child: Text(l10n.expense,
                                style: const TextStyle(fontSize: 14, color: AppColors.primaryText)),
                          ),
                          DropdownMenuItem(
                            value: CategoryType.income,
                            child: Text(l10n.income,
                                style: const TextStyle(fontSize: 14, color: AppColors.primaryText)),
                          ),
                        ],
                        onChanged: (v) => setState(() => _selectedType = v!),
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    _buildField(
                      icon: Icons.account_balance_outlined,
                      label: l10n.entity.toUpperCase(),
                      child: DropdownButton<FinancialEntity?>(
                        value: _selectedEntity,
                        isExpanded: true,
                        underline: const SizedBox(),
                        hint: Text(
                          'Personal / General',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        ),
                        items: [
                          const DropdownMenuItem<FinancialEntity?>(
                            value: null,
                            child: Text('Personal / General',
                                style: TextStyle(color: Colors.grey, fontSize: 14)),
                          ),
                          ..._entities.map((e) => DropdownMenuItem<FinancialEntity?>(
                                value: e,
                                child: Text(e.name,
                                    style: const TextStyle(fontSize: 14, color: AppColors.primaryText)),
                              )),
                        ],
                        onChanged: (v) => setState(() => _selectedEntity = v),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('CANCELAR',
                        style: TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _save(l10n),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
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
          ],
        ),
      ),
    );
  }

  Widget _buildField({required IconData icon, required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: AppColors.secondaryText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1)),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (_nameController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      if (_isSubcategory) {
        final categoryId = _selectedParentId ?? 0;
        final sub = Subcategory(id: widget.subcategory?.id ?? 0, name: _nameController.text);
        await _categoryRepo.saveSubcategory(categoryId, sub);
        if (mounted) Navigator.pop(context, true);
      } else {
        final category = Category(
          id: widget.category?.id ?? 0,
          name: _nameController.text,
          type: _selectedType,
          financialEntity: _selectedEntity,
        );
        await _categoryRepo.saveCategory(category);
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
