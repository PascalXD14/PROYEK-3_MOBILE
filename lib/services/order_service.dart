import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';
import 'api_config.dart';
import 'product_service.dart';

class OrderService {
  final StorageService _storage = StorageService();

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async {
    final token = await _storage.getToken();
    if (token == null) throw Exception("User belum login");

    final response = await http.post(
      ApiConfig.endpoint('orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    debugPrint('CREATE ORDER STATUS: ${response.statusCode}');
    debugPrint('CREATE ORDER BODY: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(
          'Gagal membuat pesanan: ${error['message'] ?? response.body}',
        );
      } catch (_) {
        throw Exception('Gagal membuat pesanan: ${response.body}');
      }
    }
  }

  Future<List<dynamic>> getOrders() async {
    final token = await _storage.getToken();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (token == null || userId == null) {
      throw Exception("User belum login");
    }

    final response = await http.get(
      ApiConfig.endpoint('orders/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('GET ORDERS STATUS: ${response.statusCode}');
    debugPrint('GET ORDERS BODY: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data['data'] is List ? data['data'] : [];
      }
      if (data is List) return data;
      return [];
    } else if (response.statusCode == 401) {
      throw Exception('Unauthenticated. Token tidak valid.');
    } else {
      throw Exception(
        'Gagal memuat pesanan (${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<Map<String, dynamic>> getOrderById(int id) async {
    final token = await _storage.getToken();
    if (token == null) throw Exception("User belum login");

    final response = await http.get(
      ApiConfig.endpoint('order/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('GET ORDER BY ID STATUS: ${response.statusCode}');
    debugPrint('GET ORDER BY ID BODY: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data['data'] ?? {};
      }
      return {};
    } else if (response.statusCode == 401) {
      throw Exception('Unauthenticated. Token tidak valid.');
    } else {
      throw Exception(
        'Gagal memuat order (${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<bool> cancelOrder(int id) async {
    final token = await _storage.getToken();
    if (token == null) throw Exception("User belum login");

    final response = await http.put(
      ApiConfig.endpoint('orders/$id/cancel'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('CANCEL ORDER STATUS: ${response.statusCode}');
    debugPrint('CANCEL ORDER BODY: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final success = data['success'] == true || data['message'] != null;

      if (success) {
        try {
          ProductService.notifyProductsChanged();
        } catch (_) {}
      }
      return success;
    }

    throw Exception(
      'Gagal membatalkan order (${response.statusCode}): ${response.body}',
    );
  }

  // ================= SINGLE MIDTRANS =================
  Future<Map<String, dynamic>> payWithMidtrans({
    required int userId,
    required int productId,
    required int qty,
    required int total,
    required String recipientName,
    required String shippingAddress,
  }) async {
    final token = await _storage.getToken();
    if (token == null) throw Exception("User belum login");

    final response = await http.post(
      ApiConfig.endpoint('midtrans/checkout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'user_id': userId,
        'product_id': productId,
        'qty': qty,
        'total': total,
        'recipient_name': recipientName,
        'shipping_address': shippingAddress,
      }),
    );

    debugPrint('MIDTRANS SINGLE STATUS: ${response.statusCode}');
    debugPrint('MIDTRANS SINGLE BODY: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception("Gagal transaksi Midtrans: ${response.body}");
  }

  // ================= MULTI MIDTRANS =================
  Future<Map<String, dynamic>> payWithMidtransMulti({
    required int userId,
    required List<Map<String, dynamic>> items,
    required int total,
    required String recipientName,
    required String shippingAddress,
  }) async {
    final token = await _storage.getToken();
    if (token == null) throw Exception("User belum login");

    final response = await http.post(
      ApiConfig.endpoint('midtrans/checkout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'user_id': userId,
        'items': items
            .map(
              (e) => {
                'product_id': e['product_id'],
                'price': e['price'],
                'quantity': e['qty'],
                'name': e['name'],
              },
            )
            .toList(),
        'total': total,
        'recipient_name': recipientName,
        'shipping_address': shippingAddress,
      }),
    );

    debugPrint('MIDTRANS MULTI STATUS: ${response.statusCode}');
    debugPrint('MIDTRANS MULTI BODY: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception("Gagal transaksi Midtrans (multi): ${response.body}");
  }

  // ================= REVIEW =================
  Future<void> sendReview({
    required int productId,
    required int transactionId,
    required double rating,
    required String comment,
  }) async {
    final token = await _storage.getToken();
    if (token == null) throw Exception("User belum login");

    await http.post(
      ApiConfig.endpoint('reviews'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'product_id': productId,
        'transaction_id': transactionId,
        'rating': rating,
        'comment': comment,
      }),
    );
  }
}
