/// Represents a single chat message received from REST or SignalR.
class ChatMessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isSeen;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    required this.isSeen,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String).toLocal(),
      isSeen: json['isSeen'] as bool? ?? false,
    );
  }

  /// Creates a copy with overridden fields — used to mark messages as seen.
  ChatMessageModel copyWith({bool? isSeen}) {
    return ChatMessageModel(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      timestamp: timestamp,
      isSeen: isSeen ?? this.isSeen,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ChatMessageModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
