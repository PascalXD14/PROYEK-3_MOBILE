import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'storage_service.dart';

class ReviewService {
  final StorageService _storage = StorageService();

  /// NOTIFIER UNTUK REFRESH UI REVIEW
  static ValueNotifier<bool> refreshNotifier = ValueNotifier(false);

  /// Ambil daftar ulasan berdasarkan product_id
  Future<List<dynamic>> getReviews(int productId) async {
    final url = ApiConfig.endpoint('products/$productId/reviews');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal memuat ulasan produk');
    }
  }

  /// Kirim ulasan (harus login)
  Future<Map<String, dynamic>> submitReview({
    required int productId,
    required int transactionId,
    required double rating,
    required String? comment,
  }) async {
    final token = await _storage.getToken();
    if (token == null) throw Exception("User belum login");

    final url = ApiConfig.endpoint('reviews');
    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'product_id': productId,
        'transaction_id': transactionId,
        'rating': rating.round(),
        'comment': (comment?.isEmpty ?? true) ? null : comment,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // === TRIGGER REFRESH ===
      refreshNotifier.value = !refreshNotifier.value;
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal mengirim ulasan: ${response.body}');
    }
  }
}
