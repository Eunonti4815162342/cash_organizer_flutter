import '../models/category.dart';

abstract class ICategoryRepository {
  Future<List<Category>> fetchCategories();
  Future<void> saveCategory(Category category);
  Future<void> saveAll(List<Category> categories);
  Future<void> reconcile(List<Category> serverCategories);
  Future<Category?> getById(int id);
  Future<void> deleteCategory(int id);
  Future<void> deleteSubcategory(int id);
  
  // Nuevo método para subcategorías
  Future<void> saveSubcategory(int categoryId, Subcategory subcategory);
}
