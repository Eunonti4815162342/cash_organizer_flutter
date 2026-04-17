/// Base environment interface for configuration management
abstract class Environment {
  /// API base URL for backend communication
  String get apiBaseUrl;

  /// API timeout in seconds
  int get apiTimeout;

  /// Whether to enable request/response logging
  bool get enableLogging;

  /// Whether this is a release/production build
  bool get isProduction;

  /// Environment name for display/debugging
  String get environmentName;

  /// CORS origins allowed (for web builds)
  List<String> get allowedOrigins;

  /// Database name for SQLite (mobile only)
  String get databaseName;

  /// Whether to enable biometric authentication
  bool get enableBiometric;

  /// JWT token expiration in hours
  int get tokenExpirationHours;

  /// Whether background sync is enabled
  bool get enableBackgroundSync;

  /// Background sync interval in minutes
  int get backgroundSyncIntervalMinutes;
}
