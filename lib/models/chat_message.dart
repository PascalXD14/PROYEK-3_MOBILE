class ChatMessage {
  final int id;
  final int senderId;
  final int receiverId;
  final String body;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.body,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      senderId: json['sender_id'] as int,
      receiverId: json['receiver_id'] as int,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
