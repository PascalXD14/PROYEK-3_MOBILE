import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'storage_service.dart';

class ReviewService {
  final StorageService _storage = StorageService();

  Future<List<dynamic>> getReviews(int productId) async {
    final url = ApiConfig.endpoint('products/$productId/reviews');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Gagal memuat ulasan produk');
    }
  }

  Future<Map<String, dynamic>> addReview({
    required int productId,
    required int userId,
    required double rating,
    required String comment,
  }) async {
    final token = await _storage.getToken();
    if (token == null) throw Exception("User belum login");

    final url = ApiConfig.endpoint('reviews');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'product_id': productId,
        'user_id': userId,
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal mengirim ulasan (${response.statusCode})');
    }
  }
}
