import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'services/http_client_manager.dart';
import 'services/auth_service.dart';
import 'services/account_service.dart';
import 'services/transaction_service.dart';
import 'services/category_service.dart';
import 'services/report_service.dart';
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

  // HTTP Client Manager
  getIt.registerSingleton<HttpClientManager>(HttpClientManager());

  // Domain Services
  getIt.registerSingleton<AuthService>(AuthService(getIt.get<HttpClientManager>()));
  getIt.registerSingleton<AccountService>(AccountService(getIt.get<HttpClientManager>()));
  getIt.registerSingleton<TransactionService>(TransactionService(getIt.get<HttpClientManager>()));
  getIt.registerSingleton<CategoryService>(CategoryService(getIt.get<HttpClientManager>()));
  getIt.registerSingleton<ReportService>(ReportService(getIt.get<HttpClientManager>()));

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
