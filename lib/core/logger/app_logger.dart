import 'package:logger/logger.dart';
import '../exceptions/app_exceptions.dart';
import '../../config/environment_factory.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
    ),
  );

  /// Log debug message
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_shouldLog(LogLevel.debug)) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log info message
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_shouldLog(LogLevel.info)) {
      _logger.i(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log warning message
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_shouldLog(LogLevel.warning)) {
      _logger.w(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log error with full context
  static void error(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log app exception with context
  static void logException(AppException exception) {
    _logger.e(
      'Exception: ${exception.runtimeType}',
      error: exception.message,
      stackTrace: exception.stackTrace,
    );
  }

  /// Log network request (only in debug mode)
  static void logRequest(String method, String url, Map<String, String> headers) {
    if (_shouldLog(LogLevel.debug)) {
      _logger.d('HTTP $method: $url');
      _logger.d('Headers: $headers');
    }
  }

  /// Log network response (only in debug mode)
  static void logResponse(int statusCode, String url, dynamic body) {
    if (_shouldLog(LogLevel.debug)) {
      _logger.d('HTTP Response: $statusCode from $url');
      if (body != null) {
        _logger.d('Body: $body');
      }
    }
  }

  /// Check if message should be logged based on environment
  static bool _shouldLog(LogLevel level) {
    if (!EnvironmentFactory.current.enableLogging) {
      return level == LogLevel.error || level == LogLevel.warning;
    }
    return true;
  }
}

enum LogLevel {
  debug,
  info,
  warning,
  error,
}
