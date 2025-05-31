import 'package:flutter/foundation.dart';

/// Context information for errors
class ErrorContext {
  final String? userId;
  final String? screenName;
  final String? action;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  ErrorContext({
    this.userId,
    this.screenName,
    this.action,
    Map<String, dynamic>? metadata,
  })  : metadata = metadata ?? {},
        timestamp = DateTime.now();

  /// Create context for authentication errors
  factory ErrorContext.auth({
    required String action,
    String? email,
    Map<String, dynamic>? additional,
  }) {
    return ErrorContext(
      screenName: 'Authentication',
      action: action,
      metadata: {
        'email': email,
        'type': 'auth',
        ...?additional,
      },
    );
  }

  /// Create context for chat room errors
  factory ErrorContext.chatRoom({
    required String action,
    String? roomId,
    String? roomName,
    Map<String, dynamic>? additional,
  }) {
    return ErrorContext(
      screenName: 'Chat Room',
      action: action,
      metadata: {
        'roomId': roomId,
        'roomName': roomName,
        'type': 'chat_room',
        ...?additional,
      },
    );
  }

  /// Create context for location errors
  factory ErrorContext.location({
    required String action,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? additional,
  }) {
    return ErrorContext(
      screenName: 'Location',
      action: action,
      metadata: {
        'latitude': latitude,
        'longitude': longitude,
        'type': 'location',
        ...?additional,
      },
    );
  }

  /// Create context for network errors
  factory ErrorContext.network({
    required String action,
    String? endpoint,
    int? statusCode,
    Map<String, dynamic>? additional,
  }) {
    return ErrorContext(
      screenName: 'Network',
      action: action,
      metadata: {
        'endpoint': endpoint,
        'statusCode': statusCode,
        'type': 'network',
        ...?additional,
      },
    );
  }

  /// Create context for moderation errors
  factory ErrorContext.moderation({
    required String action,
    String? contentType,
    String? reason,
    Map<String, dynamic>? additional,
  }) {
    return ErrorContext(
      screenName: 'Moderation',
      action: action,
      metadata: {
        'contentType': contentType,
        'reason': reason,
        'type': 'moderation',
        ...?additional,
      },
    );
  }

  /// Convert to map for logging/reporting
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'screenName': screenName,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Convert to JSON string
  String toJson() {
    return toMap().toString();
  }

  /// Add additional metadata
  ErrorContext copyWith({
    String? userId,
    String? screenName,
    String? action,
    Map<String, dynamic>? additionalMetadata,
  }) {
    return ErrorContext(
      userId: userId ?? this.userId,
      screenName: screenName ?? this.screenName,
      action: action ?? this.action,
      metadata: {
        ...metadata,
        ...?additionalMetadata,
      },
    );
  }

  @override
  String toString() {
    return 'ErrorContext(screenName: $screenName, action: $action, userId: $userId, metadata: $metadata)';
  }
}

/// Mixin for adding error context to widgets/services
mixin ErrorContextMixin {
  /// Create error context for this class
  ErrorContext createErrorContext({
    required String action,
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    return ErrorContext(
      userId: userId,
      screenName: runtimeType.toString(),
      action: action,
      metadata: metadata,
    );
  }

  /// Log error with context
  void logErrorWithContext(
    dynamic error, {
    required String action,
    String? userId,
    Map<String, dynamic>? metadata,
    StackTrace? stackTrace,
  }) {
    final context = createErrorContext(
      action: action,
      userId: userId,
      metadata: metadata,
    );

    if (kDebugMode) {
      print('🔥 ERROR in ${context.screenName}: $error');
      print('   Action: ${context.action}');
      print('   Context: ${context.metadata}');
      if (stackTrace != null) print('   Stack: $stackTrace');
    }
  }
}
