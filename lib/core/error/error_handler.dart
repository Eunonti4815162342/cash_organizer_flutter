import 'package:http/http.dart' as http;
import '../exceptions/app_exceptions.dart';
import '../logger/app_logger.dart';

/// Central error handling for the application
class ErrorHandler {
  /// Handle HTTP response and convert to appropriate exception
  static AppException handleHttpError(http.Response response) {
    AppLogger.logResponse(response.statusCode, response.request?.url.toString() ?? 'Unknown', response.body);

    switch (response.statusCode) {
      case 400:
        return BadRequestException(
          message: _extractErrorMessage(response.body) ?? 'Bad request',
          statusCode: 400,
        );
      case 401:
        return UnauthorizedException(
          message: 'SESSION_EXPIRED',
          statusCode: 401,
        );
      case 403:
        return ForbiddenException(
          message: _extractErrorMessage(response.body) ?? 'Access forbidden',
          statusCode: 403,
        );
      case 404:
        return NotFoundException(
          message: _extractErrorMessage(response.body) ?? 'Resource not found',
          statusCode: 404,
        );
      case >= 500:
        return ServerErrorException(
          message: 'Server error',
          statusCode: response.statusCode,
        );
      default:
        return ServerErrorException(
          message: 'HTTP Error ${response.statusCode}',
          statusCode: response.statusCode,
        );
    }
  }

  /// Handle generic exceptions and convert to AppException
  static AppException handleException(
    dynamic error, [
    StackTrace? stackTrace,
  ]) {
    // Already an AppException
    if (error is AppException) {
      AppLogger.logException(error);
      return error;
    }

    // HTTP exceptions
    if (error is http.Response) {
      return handleHttpError(error);
    }

    // Timeout
    if (error is http.ClientException &&
        error.toString().contains('Connection timed out')) {
      AppLogger.error('Timeout error', error, stackTrace);
      return TimeoutException(originalError: error, stackTrace: stackTrace);
    }

    // Socket exceptions
    if (error.runtimeType.toString().contains('SocketException')) {
      AppLogger.error('Socket error', error, stackTrace);
      return SocketException(originalError: error, stackTrace: stackTrace);
    }

    // Network connection errors
    if (error.toString().contains('Failed host lookup') ||
        error.toString().contains('Connection refused')) {
      AppLogger.error('Connection error', error, stackTrace);
      return ConnectionException(originalError: error, stackTrace: stackTrace);
    }

    // Default: unknown exception
    AppLogger.error('Unknown error', error, stackTrace);
    return UnknownException(
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Extract error message from response body
  static String? _extractErrorMessage(String body) {
    try {
      // Try common error response formats
      if (body.contains('"message"')) {
        return _parseJsonField(body, 'message');
      } else if (body.contains('"error"')) {
        return _parseJsonField(body, 'error');
      }
    } catch (_) {
      // If parsing fails, return null
    }
    return null;
  }

  /// Simple JSON field extraction
  static String? _parseJsonField(String json, String field) {
    final pattern = RegExp('"$field"\\s*:\\s*"([^"]*)"');
    final match = pattern.firstMatch(json);
    return match?.group(1);
  }

  /// Get user-friendly error message
  static String getUserMessage(AppException exception) {
    if (exception is SessionExpiredException) {
      return 'Your session has expired. Please login again.';
    } else if (exception is UnauthorizedException) {
      return 'Invalid credentials. Please try again.';
    } else if (exception is ValidationException) {
      return exception.message;
    } else if (exception is ConnectionException) {
      return 'No internet connection. Please check your network.';
    } else if (exception is TimeoutException) {
      return 'Request timed out. Please try again.';
    } else if (exception is NotFoundException) {
      return 'Resource not found.';
    } else if (exception is ServerErrorException) {
      return 'Server error. Please try again later.';
    } else if (exception is StorageException) {
      return 'Storage error occurred.';
    } else if (exception is DatabaseException) {
      return 'Database error occurred.';
    }
    return exception.message;
  }

  /// Show snackbar with error message
  static void showErrorSnackBar(dynamic error, dynamic scaffoldContext) {
    // Import ScaffoldMessenger from flutter/material
    // This will be used in UI to display errors
  }
}
