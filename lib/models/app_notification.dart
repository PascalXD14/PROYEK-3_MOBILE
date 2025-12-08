class AppNotification {
  final int id;
  final String title;
  final String message;
  final String? imageUrl;
  final String? productName;   
  final DateTime date;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.imageUrl,
    required this.productName, 
    required this.date,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      productName: json['product_name'], 
      imageUrl: json['image_url'],
      date: DateTime.parse(json['created_at'] ?? json['date']),
    );
  }
}
