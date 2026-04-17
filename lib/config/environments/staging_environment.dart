import '../environment.dart';
import '../../services/config_service.dart';

class StagingEnvironment implements Environment {
  @override
  String get apiBaseUrl => ConfigService.apiBaseUrl;

  @override
  int get apiTimeout => ConfigService.apiTimeout;

  @override
  bool get enableLogging => ConfigService.enableLogging;

  @override
  bool get isProduction => ConfigService.isProduction;

  @override
  String get environmentName => ConfigService.environmentName;

  @override
  List<String> get allowedOrigins => [
    'https://staging.cashorganizer.com',
    'https://app-staging.cashorganizer.com',
  ];

  @override
  String get databaseName => ConfigService.databaseName;

  @override
  bool get enableBiometric => ConfigService.enableBiometric;

  @override
  int get tokenExpirationHours => ConfigService.tokenExpirationHours;

  @override
  bool get enableBackgroundSync => ConfigService.enableBackgroundSync;

  @override
  int get backgroundSyncIntervalMinutes => ConfigService.backgroundSyncIntervalMinutes;
}
