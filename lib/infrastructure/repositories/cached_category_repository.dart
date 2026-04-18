import 'package:flutter/foundation.dart' show kIsWeb;
import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../../services/api_service.dart';
import '../../service_locator.dart';

class CachedCategoryRepository implements ICategoryRepository {
  final ApiService _apiService = getIt<ApiService>();
  
  ICategoryRepository? get _localRepo => kIsWeb ? null : getIt<ICategoryRepository>(instanceName: 'local_category');

  @override
  Future<List<Category>> fetchCategories() async {
    try {
      final remoteCategories = await _apiService.fetchCategories();
      if (remoteCategories.isNotEmpty) {
        if (!kIsWeb) {
          await _localRepo?.saveAll(remoteCategories);
        }
        return remoteCategories;
      }
    } catch (e) {
      print('[CachedCategoryRepository] Error: $e');
      if (kIsWeb) return [];
    }
    return kIsWeb ? [] : (await _localRepo?.fetchCategories() ?? []);
  }

  @override
  Future<void> saveCategory(Category category) async {
    if (!kIsWeb) {
      await _localRepo?.saveCategory(category);
    }
  }

  @override
  Future<void> saveAll(List<Category> categories) async {
    if (!kIsWeb) {
      await _localRepo?.saveAll(categories);
    }
  }

  @override
  Future<Category?> getById(int id) async {
    if (kIsWeb) return null;
    return await _localRepo?.getById(id);
  }
}
