import 'dart:convert';
import 'package:flutter/services.dart';

/// Service for loading runtime configuration from assets/config.json
class ConfigService {
  static late Map<String, dynamic> _config;
  static bool _initialized = false;

  /// Initialize config by loading from assets/config.json
  static Future<void> init() async {
    if (_initialized) return;

    try {
      final jsonString = await rootBundle.loadString('assets/config.json');
      _config = jsonDecode(jsonString);
      _initialized = true;
    } catch (e) {
      // Fallback to defaults if config fails to load
      _config = _getDefaults();
      _initialized = true;
      print('WARNING: Using default config due to error: $e');
    }
  }

  /// Get API base URL
  static String get apiBaseUrl => _config['apiBaseUrl'] ?? 'http://localhost:8085/api';

  /// Get API timeout in seconds
  static int get apiTimeout => _config['apiTimeout'] ?? 10;

  /// Whether logging is enabled
  static bool get enableLogging => _config['enableLogging'] ?? false;

  /// Whether this is production
  static bool get isProduction => _config['isProduction'] ?? false;

  /// Environment name
  static String get environmentName => _config['environmentName'] ?? 'Unknown';

  /// JWT token expiration in hours
  static int get tokenExpirationHours => _config['tokenExpirationHours'] ?? 24;

  /// Whether biometric auth is enabled
  static bool get enableBiometric => _config['enableBiometric'] ?? true;

  /// Whether background sync is enabled
  static bool get enableBackgroundSync => _config['enableBackgroundSync'] ?? true;

  /// Background sync interval in minutes
  static int get backgroundSyncIntervalMinutes => _config['backgroundSyncIntervalMinutes'] ?? 60;

  /// Database name for SQLite
  static String get databaseName => _config['databaseName'] ?? 'natave.db';

  /// Get all config as a map
  static Map<String, dynamic> getAll() => Map.from(_config);

  /// Default configuration when file is not available
  static Map<String, dynamic> _getDefaults() {
    return {
      'apiBaseUrl': 'http://192.168.1.192:8085/api',
      'apiTimeout': 10,
      'enableLogging': true,
      'isProduction': false,
      'environmentName': 'Development',
      'tokenExpirationHours': 24,
      'enableBiometric': true,
      'enableBackgroundSync': true,
      'backgroundSyncIntervalMinutes': 15,
      'databaseName': 'natave_dev.db',
    };
  }
}
