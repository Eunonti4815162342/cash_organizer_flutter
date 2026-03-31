import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/models/category.dart';
import '../../../services/api_service.dart';

class CategoryFormDialog extends StatefulWidget {
  final Category? category;
  final Subcategory? subcategory;
  final int? parentCategoryId;

  const CategoryFormDialog({
    super.key, 
    this.category, 
    this.subcategory, 
    this.parentCategoryId
  });

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final ApiService _apiService = ApiService();
  late TextEditingController _nameController;
  CategoryType _selectedType = CategoryType.expense;
  int? _selectedParentId;
  List<Category> _parentCategories = [];
  bool _isLoading = false;

  final FocusNode _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.category?.name ?? widget.subcategory?.name ?? ''
    );
    
    if (widget.category != null) {
      _selectedType = widget.category!.type;
    } else if (widget.parentCategoryId != null || widget.subcategory != null) {
      _selectedParentId = widget.parentCategoryId;
    }

    _nameFocus.addListener(() {
      if (_nameFocus.hasFocus) _nameController.clear();
    });

    _loadParents();
  }

  Future<void> _loadParents() async {
    final cats = await _apiService.fetchCategories();
    setState(() {
      _parentCategories = cats;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

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
          TextField(
            controller: _nameController,
            focusNode: _nameFocus,
            style: TextStyle(color: Colors.grey.shade600),
            decoration: InputDecoration(
              labelText: l10n.categoryName,
              hintText: 'Enter name',
            ),
          ),
          if (!isSubcategory) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<CategoryType>(
              value: _selectedType,
              decoration: InputDecoration(labelText: l10n.type),
              items: [
                DropdownMenuItem(value: CategoryType.expense, child: Text(l10n.expense)),
                DropdownMenuItem(value: CategoryType.income, child: Text(l10n.income)),
              ],
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _save(l10n),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
          child: Text(l10n.save, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isLoading = true);
    dynamic result;

    try {
      if (widget.subcategory != null) {
        // Edit existing subcategory
        result = await _apiService.updateSubcategory(
          widget.subcategory!.id, 
          Subcategory(id: widget.subcategory!.id, name: _nameController.text)
        );
      } else if (_selectedParentId != null) {
        // New subcategory
        result = await _apiService.createSubcategory(
          _selectedParentId!, 
          Subcategory(id: 0, name: _nameController.text)
        );
      } else if (widget.category != null) {
        // Edit existing category
        result = await _apiService.updateCategory(
          widget.category!.id, 
          Category(id: widget.category!.id, name: _nameController.text, type: _selectedType)
        );
      } else {
        // New category
        result = await _apiService.createCategory(
          Category(id: 0, name: _nameController.text, type: _selectedType)
        );
      }

      if (result != null) {
        if (mounted) Navigator.pop(context, true);
      } else {
        throw Exception("Failed to save");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Name already exists or connection issue.')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
