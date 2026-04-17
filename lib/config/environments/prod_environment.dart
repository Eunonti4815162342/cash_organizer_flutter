import '../environment.dart';

class ProductionEnvironment implements Environment {
  @override
  String get apiBaseUrl => 'http://192.168.1.145:8085/api'; // Local Raspberry Pi

  @override
  int get apiTimeout => 30;

  @override
  bool get enableLogging => false;

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
