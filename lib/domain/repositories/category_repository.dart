import '../models/category.dart';

abstract class ICategoryRepository {
  Future<List<Category>> fetchCategories();
  Future<void> saveCategory(Category category);
  Future<void> saveAll(List<Category> categories);
  Future<Category?> getById(int id);
}
