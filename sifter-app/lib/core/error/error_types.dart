/// Base class for all application errors
abstract class AppError implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppError(this.message, {this.code, this.details});

  @override
  String toString() =>
      'AppError: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Authentication related errors
class AuthError extends AppError {
  const AuthError(super.message, {super.code, super.details});
}

/// Network related errors
class NetworkError extends AppError {
  const NetworkError(super.message, {super.code, super.details});
}

/// Location service errors
class LocationError extends AppError {
  const LocationError(super.message, {super.code, super.details});
}

/// Chat room related errors
class ChatRoomError extends AppError {
  const ChatRoomError(super.message, {super.code, super.details});
}

/// Validation errors
class ValidationError extends AppError {
  const ValidationError(super.message, {super.code, super.details});
}

/// Permission errors
class PermissionError extends AppError {
  const PermissionError(super.message, {super.code, super.details});
}

/// Storage errors
class StorageError extends AppError {
  const StorageError(super.message, {super.code, super.details});
}

/// Moderation errors
class ModerationError extends AppError {
  const ModerationError(super.message, {super.code, super.details});
}

/// Generic application errors
class GenericError extends AppError {
  const GenericError(super.message, {super.code, super.details});
}

/// Error severity levels
enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

/// Error categories for analytics
enum ErrorCategory {
  authentication,
  network,
  location,
  chatRoom,
  validation,
  permission,
  storage,
  moderation,
  generic,
}
