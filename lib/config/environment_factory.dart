import 'package:flutter/foundation.dart';
import 'environment.dart';
import 'environments/dev_environment.dart';
import 'environments/staging_environment.dart';
import 'environments/prod_environment.dart';

/// Environment factory for selecting the appropriate environment
class EnvironmentFactory {
  static late Environment _currentEnvironment;

  /// Get the current environment singleton
  static Environment get current => _currentEnvironment;

  /// Initialize environment based on build type
  /// In Flutter, you typically determine this via:
  /// 1. Build configuration (flutter run -t lib/main_prod.dart)
  /// 2. Environment variable
  /// 3. Flavor (flutter run --flavor staging)
  static void init({required EnvironmentType type}) {
    _currentEnvironment = _getEnvironment(type);
  }

  /// Initialize with automatic detection
  /// In production builds (kReleaseMode), defaults to Production
  /// In development builds (kDebugMode), defaults to Development
  static void initAuto() {
    final type = kReleaseMode ? EnvironmentType.production : EnvironmentType.development;
    init(type: type);
  }

  static Environment _getEnvironment(EnvironmentType type) {
    switch (type) {
      case EnvironmentType.development:
        return DevelopmentEnvironment();
      case EnvironmentType.staging:
        return StagingEnvironment();
      case EnvironmentType.production:
        return ProductionEnvironment();
    }
  }

  /// Get environment name for display
  static String getEnvironmentName() => _currentEnvironment.environmentName;

  /// Check if running in production
  static bool isProduction() => _currentEnvironment.isProduction;

  /// Get API base URL
  static String getApiBaseUrl() => _currentEnvironment.apiBaseUrl;
}

/// Environment types
enum EnvironmentType {
  development,
  staging,
  production,
}
