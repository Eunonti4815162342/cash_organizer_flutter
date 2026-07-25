import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:natave_flutter/services/api_service.dart';
import 'package:natave_flutter/infrastructure/repositories/cached_transaction_repository.dart';
import 'package:natave_flutter/infrastructure/repositories/cached_account_repository.dart';
import 'package:natave_flutter/infrastructure/repositories/cached_category_repository.dart';
import 'package:natave_flutter/infrastructure/repositories/cached_entity_repository.dart';
import 'package:natave_flutter/infrastructure/repositories/cached_beneficiary_repository.dart';
import 'package:natave_flutter/infrastructure/repositories/api_report_repository.dart';
import 'package:natave_flutter/infrastructure/repositories/sqlite/sqlite_transaction_repository.dart';
import 'package:natave_flutter/infrastructure/repositories/sqlite/sqlite_account_repository.dart';
import 'package:natave_flutter/infrastructure/repositories/sqlite/sqlite_category_repository.dart';
import 'package:natave_flutter/infrastructure/repositories/sqlite/sqlite_entity_repository.dart';
import 'package:natave_flutter/infrastructure/repositories/sqlite/sqlite_beneficiary_repository.dart';
import 'package:natave_flutter/infrastructure/repositories/sqlite/sqlite_report_repository.dart';
import 'package:natave_flutter/domain/repositories/transaction_repository.dart';
import 'package:natave_flutter/domain/repositories/account_repository.dart';
import 'package:natave_flutter/domain/repositories/category_repository.dart';
import 'package:natave_flutter/domain/repositories/entity_repository.dart';
import 'package:natave_flutter/domain/repositories/beneficiary_repository.dart';
import 'package:natave_flutter/domain/repositories/report_repository.dart';
import 'package:natave_flutter/services/biometric_service.dart';
import 'package:natave_flutter/services/session_service.dart';
import 'package:natave_flutter/infrastructure/persistence/sqlite/database_helper.dart';
import 'package:natave_flutter/infrastructure/ui/providers/dashboard_provider.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // Logger
  getIt.registerSingleton<Logger>(Logger());

  // API Service
  getIt.registerLazySingleton<ApiService>(() => ApiService());

  // Other Services
  getIt.registerSingleton<BiometricService>(BiometricService());
  getIt.registerSingleton<SessionService>(SessionService());
  
  if (!kIsWeb) {
    getIt.registerSingleton<DatabaseHelper>(DatabaseHelper());
    getIt.registerSingleton<IAccountRepository>(
      SqliteAccountRepository(), 
      instanceName: 'local_account'
    );
    getIt.registerSingleton<ITransactionRepository>(
      SqliteTransactionRepository(), 
      instanceName: 'local_transaction'
    );
    getIt.registerSingleton<ICategoryRepository>(
      SqliteCategoryRepository(), 
      instanceName: 'local_category'
    );
    getIt.registerSingleton<IEntityRepository>(
      SqliteEntityRepository(), 
      instanceName: 'local_entity'
    );
    getIt.registerSingleton<SqliteBeneficiaryRepository>(
      SqliteBeneficiaryRepository(), 
      instanceName: 'local_beneficiary'
    );
    getIt.registerSingleton<IReportRepository>(
      SqliteReportRepository(),
    );
  } else {
    getIt.registerLazySingleton<IReportRepository>(
      () => ApiReportRepository(getIt<ApiService>().apiClient),
    );
  }

  // Repositories
  getIt.registerSingleton<ITransactionRepository>(CachedTransactionRepository());
  getIt.registerSingleton<IAccountRepository>(CachedAccountRepository());
  getIt.registerSingleton<ICategoryRepository>(CachedCategoryRepository());
  getIt.registerSingleton<IEntityRepository>(CachedEntityRepository());
  getIt.registerSingleton<IBeneficiaryRepository>(CachedBeneficiaryRepository());

  // Shared across screens so a transaction mutation on any screen is
  // reflected on the Dashboard without needing to leave and re-enter it.
  getIt.registerLazySingleton<DashboardProvider>(
    () => DashboardProvider(getIt.get(), getIt.get()),
  );
}
