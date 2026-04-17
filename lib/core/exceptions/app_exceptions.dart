/// Base exception class for the application
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => message;
}

/// Network-related exceptions
abstract class NetworkException extends AppException {
  NetworkException({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

class ConnectionException extends NetworkException {
  ConnectionException({
    String message = 'Network connection failed',
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

class TimeoutException extends NetworkException {
  TimeoutException({
    String message = 'Request timeout',
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

class SocketException extends NetworkException {
  SocketException({
    String message = 'Socket error',
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// Server-related exceptions
abstract class ServerException extends AppException {
  final int? statusCode;

  ServerException({
    required String message,
    this.statusCode,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

class BadRequestException extends ServerException {
  BadRequestException({
    String message = 'Bad request',
    int? statusCode = 400,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    statusCode: statusCode,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

class UnauthorizedException extends ServerException {
  UnauthorizedException({
    String message = 'Unauthorized. Please login again',
    int? statusCode = 401,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    statusCode: statusCode,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

class ForbiddenException extends ServerException {
  ForbiddenException({
    String message = 'Access forbidden',
    int? statusCode = 403,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    statusCode: statusCode,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

class NotFoundException extends ServerException {
  NotFoundException({
    String message = 'Resource not found',
    int? statusCode = 404,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    statusCode: statusCode,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

class ServerErrorException extends ServerException {
  ServerErrorException({
    String message = 'Server error',
    int? statusCode = 500,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    statusCode: statusCode,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// Authentication exceptions
class SessionExpiredException extends AppException {
  SessionExpiredException({
    String message = 'Session expired. Please login again',
    String? code = 'SESSION_EXPIRED',
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// Local storage exceptions
class StorageException extends AppException {
  StorageException({
    String message = 'Storage operation failed',
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// Database exceptions
class DatabaseException extends AppException {
  DatabaseException({
    String message = 'Database operation failed',
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// Validation exceptions
class ValidationException extends AppException {
  final Map<String, String>? errors;

  ValidationException({
    String message = 'Validation failed',
    this.errors,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// Generic/Unknown exceptions
class UnknownException extends AppException {
  UnknownException({
    String message = 'An unknown error occurred',
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}
