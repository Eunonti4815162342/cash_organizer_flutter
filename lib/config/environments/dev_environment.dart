import '../environment.dart';
import '../../services/config_service.dart';

class DevelopmentEnvironment implements Environment {
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
    'http://localhost:8080',
    'http://localhost:8085',
    'http://localhost:3000',
    'http://127.0.0.1:8085',
    'http://127.0.0.1:3000',
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
