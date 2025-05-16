import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@freezed
@JsonSerializable(explicitToJson: true)
class Message with _$Message {
  const factory Message({
    required String id,
    required String chatRoomId,
    required String senderId,
    required String content,
    required MessageType type,
    Map<String, dynamic>? metadata,
    @Default({}) Map<String, List<String>> reactions,
    String? replyToMessageId,
    @Default(MessageStatus.sending) MessageStatus status,
    required int timestamp,
    @Default(false) bool edited,
    int? editedAt,
  }) = _Message;

  // Private constructor needed by Freezed for getter implementations
  const Message._();

  // Temporary fix for freezed generation issues
  // The following getter implementations will be overridden by the generated code
  // but are needed for compile-time checks
  @override
  String get id => throw UnimplementedError();
  @override
  String get chatRoomId => throw UnimplementedError();
  @override
  String get senderId => throw UnimplementedError();
  @override
  String get content => throw UnimplementedError();
  @override
  MessageType get type => throw UnimplementedError();
  @override
  Map<String, dynamic>? get metadata => throw UnimplementedError();
  @override
  Map<String, List<String>> get reactions => throw UnimplementedError();
  @override
  String? get replyToMessageId => throw UnimplementedError();
  @override
  MessageStatus get status => throw UnimplementedError();
  @override
  int get timestamp => throw UnimplementedError();
  @override
  bool get edited => throw UnimplementedError();
  @override
  int? get editedAt => throw UnimplementedError();

  factory Message.fromJson(Map<String, dynamic> json) {
    // Normalized properties to handle roomId/chatRoomId inconsistency
    final normalizedJson = Map<String, dynamic>.from(json);
    
    // Ensure chatRoomId is set - prefer chatRoomId from JSON if it exists
    if (normalizedJson['chatRoomId'] == null && normalizedJson['roomId'] != null) {
      normalizedJson['chatRoomId'] = normalizedJson['roomId'];
    }
    
    // Handle timestamp conversion for server timestamps
    if (normalizedJson['timestamp'] is Timestamp) {
      normalizedJson['timestamp'] = 
          (normalizedJson['timestamp'] as Timestamp).toDate().millisecondsSinceEpoch;
    }
    
    // Handle text/content field normalization
    if (normalizedJson['content'] == null && normalizedJson['text'] != null) {
      normalizedJson['content'] = normalizedJson['text'];
    }
    
    // Convert replyToId to replyToMessageId
    if (normalizedJson['replyToMessageId'] == null && normalizedJson['replyToId'] != null) {
      normalizedJson['replyToMessageId'] = normalizedJson['replyToId'];
    }
    
    // If type is missing, default to text
    if (normalizedJson['type'] == null) {
      normalizedJson['type'] = MessageType.text.index;
    } else if (normalizedJson['type'] is String) {
      // Convert string type to enum index
      final typeStr = normalizedJson['type'] as String;
      normalizedJson['type'] = MessageType.values.indexWhere(
        (e) => e.toString().split('.').last.toLowerCase() == typeStr.toLowerCase()
      );
      // Default to text if not found
      if (normalizedJson['type'] < 0) {
        normalizedJson['type'] = MessageType.text.index;
      }
    }
    
    return _$MessageFromJson(normalizedJson);
  }

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return Message.fromJson(data);
  }
}

enum MessageType {
  text,
  image,
  video,
  audio,
  file,
  location,
  contact,
  gif,
  sticker,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

extension MessageTypeExtension on MessageType {
  String get displayName {
    switch (this) {
      case MessageType.text:
        return 'Text';
      case MessageType.image:
        return 'Image';
      case MessageType.video:
        return 'Video';
      case MessageType.audio:
        return 'Audio';
      case MessageType.file:
        return 'File';
      case MessageType.location:
        return 'Location';
      case MessageType.contact:
        return 'Contact';
      case MessageType.gif:
        return 'GIF';
      case MessageType.sticker:
        return 'Sticker';
    }
  }

  bool get isMedia {
    return this == MessageType.image ||
        this == MessageType.video ||
        this == MessageType.audio ||
        this == MessageType.file;
  }

  bool get isText {
    return this == MessageType.text;
  }

  bool get isLocation {
    return this == MessageType.location;
  }

  bool get isContact {
    return this == MessageType.contact;
  }

  bool get isGif {
    return this == MessageType.gif;
  }

  bool get isSticker {
    return this == MessageType.sticker;
  }
}

extension MessageStatusExtension on MessageStatus {
  String get displayName {
    switch (this) {
      case MessageStatus.sending:
        return 'Sending...';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.read:
        return 'Read';
      case MessageStatus.failed:
        return 'Failed';
    }
  }

  bool get isSending {
    return this == MessageStatus.sending;
  }

  bool get isSent {
    return this == MessageStatus.sent;
  }

  bool get isDelivered {
    return this == MessageStatus.delivered;
  }

  bool get isRead {
    return this == MessageStatus.read;
  }

  bool get isFailed {
    return this == MessageStatus.failed;
  }
}

extension MessageX on Message {
  // For backwards compatibility
  String get roomId => chatRoomId;
  String get text => content;
  String? get replyToId => replyToMessageId;
  
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json['timestamp'] = Timestamp.fromMillisecondsSinceEpoch(timestamp);
    return json;
  }

  Map<String, dynamic> toJson() {
    // Temporary implementation until freezed code is regenerated
    return {
      'id': id,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'content': content,
      'type': type.index,
      if (metadata != null) 'metadata': metadata,
      'reactions': reactions,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      'status': status.index,
      'timestamp': timestamp,
      'edited': edited,
      if (editedAt != null) 'editedAt': editedAt,
    };
  }

  bool get hasReactions => reactions.isNotEmpty;

  int get reactionCount {
    return reactions.values.fold<int>(0, (total, users) => total + users.length);
  }

  bool hasReaction(String reaction) => reactions.containsKey(reaction);

  List<String> getReactionUsers(String reaction) => reactions[reaction] ?? [];

  bool hasUserReacted(String userId, String reaction) {
    return reactions[reaction]?.contains(userId) ?? false;
  }

  Message addReaction(String userId, String reaction) {
    final updatedReactions = Map<String, List<String>>.from(reactions);
    if (!updatedReactions.containsKey(reaction)) {
      updatedReactions[reaction] = [];
    }
    if (!updatedReactions[reaction]!.contains(userId)) {
      updatedReactions[reaction]!.add(userId);
    }
    return copyWith(reactions: updatedReactions);
  }

  Message removeReaction(String userId, String reaction) {
    final updatedReactions = Map<String, List<String>>.from(reactions);
    if (updatedReactions.containsKey(reaction)) {
      updatedReactions[reaction]!.remove(userId);
      if (updatedReactions[reaction]!.isEmpty) {
        updatedReactions.remove(reaction);
      }
    }
    return copyWith(reactions: updatedReactions);
  }
  
  // Temporary copyWith implementation until freezed code is regenerated
  Message copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    String? content,
    MessageType? type,
    Map<String, dynamic>? metadata,
    Map<String, List<String>>? reactions,
    String? replyToMessageId,
    MessageStatus? status,
    int? timestamp,
    bool? edited,
    int? editedAt,
  }) {
    return Message(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      reactions: reactions ?? this.reactions,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      edited: edited ?? this.edited,
      editedAt: editedAt ?? this.editedAt,
    );
  }
} 