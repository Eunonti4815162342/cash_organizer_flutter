import '../environment.dart';

class ProductionEnvironment implements Environment {
  @override
  String get apiBaseUrl => 'https://api.cashorganizer.com/api';

  @override
  int get apiTimeout => 15; // Stricter timeout in production

  @override
  bool get enableLogging => false; // No logs in production

  @override
  bool get isProduction => true;

  @override
  String get environmentName => 'Production';

  @override
  List<String> get allowedOrigins => [
    'https://cashorganizer.com',
    'https://app.cashorganizer.com',
  ];

  @override
  String get databaseName => 'cash_organizer_prod.db';

  @override
  bool get enableBiometric => true;

  @override
  int get tokenExpirationHours => 24;

  @override
  bool get enableBackgroundSync => true;

  @override
  int get backgroundSyncIntervalMinutes => 60; // Less frequent in prod
}
