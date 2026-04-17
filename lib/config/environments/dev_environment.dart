import '../environment.dart';

class DevelopmentEnvironment implements Environment {
  @override
  String get apiBaseUrl => 'http://localhost:8085/api';

  @override
  int get apiTimeout => 30; // More lenient in dev

  @override
  bool get enableLogging => true;

  @override
  bool get isProduction => false;

  @override
  String get environmentName => 'Development';

  @override
  List<String> get allowedOrigins => [
    'http://localhost:8080',
    'http://localhost:8085',
    'http://localhost:3000',
    'http://127.0.0.1:8085',
    'http://127.0.0.1:3000',
  ];

  @override
  String get databaseName => 'cash_organizer_dev.db';

  @override
  bool get enableBiometric => true;

  @override
  int get tokenExpirationHours => 24;

  @override
  bool get enableBackgroundSync => true;

  @override
  int get backgroundSyncIntervalMinutes => 15;
}
