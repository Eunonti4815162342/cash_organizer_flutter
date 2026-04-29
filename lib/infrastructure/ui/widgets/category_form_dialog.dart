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
      setState(() {
        _entities = ents;
        if (_selectedEntity != null) {
          _selectedEntity = _entities.firstWhere((e) => e.id == _selectedEntity!.id, orElse: () => _selectedEntity!);
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() { _nameController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.category != null || widget.subcategory != null;
    final isSubcategory = _selectedParentId != null || widget.subcategory != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit ${isSubcategory ? "Subcategory" : "Category"}' : 'New ${isSubcategory ? "Subcategory" : "Category"}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _nameController, decoration: InputDecoration(labelText: l10n.categoryName, hintText: 'Enter name')),
          if (!isSubcategory) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<CategoryType>(
              value: _selectedType,
              decoration: InputDecoration(labelText: l10n.type),
              items: [DropdownMenuItem(value: CategoryType.expense, child: Text(l10n.expense)), DropdownMenuItem(value: CategoryType.income, child: Text(l10n.income))],
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FinancialEntity?>(
              value: _selectedEntity,
              decoration: InputDecoration(labelText: l10n.entity, hintText: 'Personal / General', prefixIcon: const Icon(Icons.account_balance_outlined, size: 18)),
              items: [const DropdownMenuItem<FinancialEntity?>(value: null, child: Text('Personal / General')), ..._entities.map((e) => DropdownMenuItem(value: e, child: Text(e.name)))],
              onChanged: (v) => setState(() => _selectedEntity = v),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        ElevatedButton(onPressed: _isLoading ? null : () => _save(l10n), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue), child: Text(l10n.save, style: const TextStyle(color: Colors.white))),
      ],
    );
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (_nameController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      if (isSubcategory()) {
        final categoryId = _selectedParentId ?? 0;
        final sub = Subcategory(
          id: widget.subcategory?.id ?? 0, 
          name: _nameController.text
        );
        // FIX: Guardamos la subcategoría usando el repositorio unificado
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
    } finally { setState(() => _isLoading = false); }
  }

  bool isSubcategory() => _selectedParentId != null || widget.subcategory != null;
}
