import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'services/api_service.dart';
import 'infrastructure/repositories/cached_transaction_repository.dart';
import 'infrastructure/repositories/cached_account_repository.dart';
import 'infrastructure/repositories/cached_category_repository.dart';
import 'domain/repositories/transaction_repository.dart';
import 'domain/repositories/account_repository.dart';
import 'domain/repositories/category_repository.dart';
import 'services/biometric_service.dart';
import 'services/session_service.dart';
import 'infrastructure/persistence/sqlite/database_helper.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // Logger
  getIt.registerSingleton<Logger>(Logger());

  // API Service (Facade for all network operations)
  getIt.registerLazySingleton<ApiService>(() => ApiService());

  // Other Services
  getIt.registerSingleton<BiometricService>(BiometricService());
  getIt.registerSingleton<SessionService>(SessionService());
  getIt.registerSingleton<DatabaseHelper>(DatabaseHelper());

  // Repositories - Domain Interfaces
  getIt.registerSingleton<ITransactionRepository>(
    CachedTransactionRepository(),
  );
  getIt.registerSingleton<IAccountRepository>(
    CachedAccountRepository(),
  );
  getIt.registerSingleton<ICategoryRepository>(
    CachedCategoryRepository(),
  );
}
