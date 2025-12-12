class ChatMessage {
  final int id;
  final int senderId;
  final int receiverId;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  // ===== Tambahan untuk produk =====
  final int? productId;
  final String? productName;
  final int? productPrice;
  final String? productImage;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.productId,
    this.productName,
    this.productPrice,
    this.productImage,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      body: json['body'] ?? '',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: DateTime.parse(json['created_at']),

      // Ambil jika ada
      productId: json['product_id'],
      productName: json['product_name'],
      productPrice: json['product_price'] is String
          ? int.tryParse(json['product_price']) ?? 0
          : json['product_price'],
      productImage: json['product_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'body': body,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),

      // Tambahan
      'product_id': productId,
      'product_name': productName,
      'product_price': productPrice,
      'product_image': productImage,
    };
  }
}
