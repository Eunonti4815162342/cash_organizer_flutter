import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../styles/app_styles.dart';
import '../../../domain/models/category.dart';
import '../../../services/api_service.dart';

class CategoryFormDialog extends StatefulWidget {
  const CategoryFormDialog({super.key});

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  Category? _selectedParent;
  CategoryType _selectedType = CategoryType.expense;
  bool _isSubcategory = false;
  
  List<Category> _allCategories = [];
  List<Category> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadCategories() async {
    final cats = await _apiService.fetchCategories();
    setState(() {
      _allCategories = cats;
      _filteredCategories = cats;
    });
  }

  void _onSearchChanged() {
    setState(() {
      _filteredCategories = _allCategories
          .where((c) => c.name.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 900,
        height: 600,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
        ),
        child: Column(
          children: [
            // HEADER
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Text(l10n.newCategory, style: const TextStyle(fontSize: 20, color: AppColors.primaryText)),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () async {
                      if (_nameController.text.isNotEmpty) {
                        if (_isSubcategory) {
                          if (_selectedParent == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.pleaseSelectParentCategory))
                            );
                            return;
                          }
                          await _apiService.createSubcategory(
                            _selectedParent!.id,
                            Subcategory(id: 0, name: _nameController.text)
                          );
                        } else {
                          await _apiService.createCategory(
                            Category(id: 0, name: _nameController.text, type: _selectedType)
                          );
                        }
                        if (mounted) Navigator.pop(context, true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: Text(l10n.save, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  IconButton(icon: const Icon(Icons.close, color: AppColors.secondaryText), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            
            // BODY
            Expanded(
              child: Row(
                children: [
                  // LADO IZQUIERDO: FORMULARIO
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Property', style: TextStyle(fontWeight: FontWeight.bold)),
                          Container(height: 2, width: 80, color: AppColors.primaryBlue),
                          const SizedBox(height: 30),
                          _buildFormRow(l10n.description, TextField(
                            controller: _nameController,
                            decoration: InputDecoration(hintText: l10n.categoryName, border: InputBorder.none),
                          )),
                          _buildFormRow(l10n.type, Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: Text(l10n.expense, style: const TextStyle(fontSize: 12)), 
                                selected: _selectedType == CategoryType.expense && !_isSubcategory,
                                onSelected: (val) => setState(() { _selectedType = CategoryType.expense; _isSubcategory = false; }),
                              ),
                              ChoiceChip(
                                label: Text(l10n.income, style: const TextStyle(fontSize: 12)), 
                                selected: _selectedType == CategoryType.income && !_isSubcategory,
                                onSelected: (val) => setState(() { _selectedType = CategoryType.income; _isSubcategory = false; }),
                              ),
                              ChoiceChip(
                                label: Text(l10n.subcategoryOf, style: const TextStyle(fontSize: 12)), 
                                selected: _isSubcategory,
                                onSelected: (val) => setState(() => _isSubcategory = val),
                              ),
                            ],
                          )),
                          if (_isSubcategory)
                            _buildFormRow('Parent*', InkWell(
                              onTap: () {},
                              child: Text(_selectedParent?.name ?? l10n.selectParentCategory, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                            )),
                        ],
                      ),
                    ),
                  ),
                  
                  // LADO DERECHO: EXPLORADOR
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9F9F9),
                        border: Border(left: BorderSide(color: AppColors.divider)),
                      ),
                      child: Column(
                        children: [
                          // Buscador
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Container(
                              height: 35,
                              decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.black12)),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: l10n.search,
                                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.secondaryText),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.only(bottom: 12),
                                ),
                              ),
                            ),
                          ),
                          // Lista de categorías
                          Expanded(
                            child: ListView.builder(
                              itemCount: _filteredCategories.length,
                              itemBuilder: (context, index) {
                                final cat = _filteredCategories[index];
                                final isExpense = cat.type == CategoryType.expense;
                                return Container(
                                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
                                  child: ListTile(
                                    dense: true,
                                    title: Text(cat.name, style: const TextStyle(fontSize: 13, color: AppColors.primaryText)),
                                    trailing: Container(
                                      width: 4,
                                      height: 20,
                                      color: isExpense ? AppColors.expenseRed : AppColors.incomeGreen,
                                    ),
                                    onTap: () {
                                      if (_isSubcategory) setState(() => _selectedParent = cat);
                                    },
                                  ),
                                );
                              },
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

  Widget _buildFormRow(String label, Widget content) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.scaffoldBackground))),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 14), textAlign: TextAlign.right)),
          const SizedBox(width: 20),
          Expanded(child: content),
        ],
      ),
    );
  }
}
