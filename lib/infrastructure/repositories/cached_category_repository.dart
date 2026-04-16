import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../../services/api_service.dart';
import 'sqlite/sqlite_category_repository.dart';

class CachedCategoryRepository implements ICategoryRepository {
  final ApiService _apiService = ApiService();
  final SqliteCategoryRepository _localRepo = SqliteCategoryRepository();

  @override
  Future<List<Category>> fetchCategories() async {
    try {
      final remoteCategories = await _apiService.fetchCategories();
      if (remoteCategories.isNotEmpty) {
        await _localRepo.saveAll(remoteCategories);
        return remoteCategories;
      }
    } catch (e) {
      print('[CachedCategoryRepository] Error fetching remote, falling back to local: $e');
    }
    return await _localRepo.fetchCategories();
  }

  @override
  Future<void> saveCategory(Category category) async {
    await _localRepo.saveCategory(category);
    // Nota: El SyncService se encargará de subir categorías si se requiere
  }

  @override
  Future<void> saveAll(List<Category> categories) async {
    await _localRepo.saveAll(categories);
  }

  @override
  Future<Category?> getById(int id) async {
    return await _localRepo.getById(id);
  }
}
