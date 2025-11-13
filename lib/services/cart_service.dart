import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'storage_service.dart';
import 'package:flutter/foundation.dart';

class CartService {
  final StorageService _storage = StorageService();

  Future<List<dynamic>> getCart(int userId) async {
    final token = await _storage.getToken();
    if (token == null) throw Exception("User belum login");

    final url = ApiConfig.endpoint('cart/$userId');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Gagal memuat data keranjang');
    }
  }

  Future<Map<String, dynamic>> updateCart(int cartId, int qty) async {
    final token = await _storage.getToken();
    if (token == null) throw Exception("User belum login");

    final url = ApiConfig.endpoint('cart/$cartId');
    final response = await http.put(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      body: {'qty': qty.toString()},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Gagal update cart (${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<Map<String, dynamic>> addToCart({
    required int userId,
    required int productId,
    required int qty,
  }) async {
    final token = await _storage.getToken();
    final role = await _storage.getRole();

    if (token == null || token.isEmpty) {
      throw Exception("User belum login — token kosong/null");
    }
    if (role == 'guest') {
      throw Exception("Guest tidak bisa menambah ke keranjang");
    }

    final url = ApiConfig.endpoint('cart/add');
    debugPrint('🛒 AddToCart: POST $url');
    debugPrint('Payload: user_id=$userId, product_id=$productId, qty=$qty');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'user_id': userId,
        'product_id': productId,
        'qty': qty,
      }),
    );

    debugPrint('🛒 AddToCart RESP: ${response.statusCode}');
    debugPrint(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Gagal menambah ke keranjang (${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<Map<String, dynamic>> removeCartItem(int cartId) async {
    final token = await _storage.getToken();
    if (token == null) throw Exception("User belum login");

    final url = ApiConfig.endpoint('cart/remove/$cartId');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal menghapus item keranjang');
    }
  }
}
