import '../environment.dart';

class StagingEnvironment implements Environment {
  @override
  String get apiBaseUrl => 'https://staging-api.cashorganizer.com/api';

  @override
  int get apiTimeout => 20;

  @override
  bool get enableLogging => true; // Still log issues in staging

  @override
  bool get isProduction => false;

  @override
  String get environmentName => 'Staging';

  @override
  List<String> get allowedOrigins => [
    'https://staging.cashorganizer.com',
    'https://app-staging.cashorganizer.com',
  ];

  @override
  String get databaseName => 'cash_organizer_staging.db';

  @override
  bool get enableBiometric => true;

  @override
  int get tokenExpirationHours => 24;

  @override
  bool get enableBackgroundSync => true;

  @override
  int get backgroundSyncIntervalMinutes => 30;
}
