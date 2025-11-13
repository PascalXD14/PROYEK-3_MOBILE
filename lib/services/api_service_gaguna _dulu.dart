import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // 🔗 Ganti sesuai IP server Laravel kamu
  static const String baseUrl = 'http://192.168.1.15:8000/api';

  // ==========================================================
  // Ambil Token & Role
  // ==========================================================
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    debugPrint('Token disimpan: $token');
    return token;
  }

  Future<String?> _getRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    debugPrint('👤 Role disimpan: $role');
    return role;
  }

  // ==========================================================
  // Ambil Semua Produk
  // ==========================================================
  Future<List<dynamic>> getProducts() async {
    final url = Uri.parse('$baseUrl/products');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('data')) {
        return data['data'];
      } else if (data is List) {
        return data;
      } else {
        throw Exception('Format respons tidak sesuai');
      }
    } else {
      throw Exception('Gagal memuat produk (${response.statusCode})');
    }
  }

  // ==========================================================
  // Guest Login (Hanya untuk lihat produk, bukan keranjang)
  // ==========================================================
  Future<Map<String, dynamic>> guestLogin() async {
    final url = Uri.parse('$baseUrl/guest-login');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('role', 'guest'); // ✅ simpan role guest
      return data;
    } else {
      throw Exception('Gagal login sebagai tamu (${response.statusCode})');
    }
  }

  // ==========================================================
  // Login Customer
  // ==========================================================
  Future<Map<String, dynamic>> customerLogin(
    String username,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/customer-login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    debugPrint('🔐 LOGIN RESP (${response.statusCode}): ${response.body}');

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 &&
        (body['status'] == 'success' || body['success'] == true)) {
      final prefs = await SharedPreferences.getInstance();

      // Ambil token dari berbagai kemungkinan key
      final token =
          body['token'] ?? body['data']?['token'] ?? body['user']?['token'];

      if (token != null && token.toString().isNotEmpty) {
        await prefs.setString('token', token.toString());
        debugPrint('🪙 Token disimpan ke SharedPreferences: $token');
      } else {
        debugPrint('⚠️ Tidak ada token di response JSON');
      }

      // Simpan info user
      final user = body['user'];
      if (user != null) {
        await prefs.setInt('user_id', user['id']);
        await prefs.setString('role', user['role'] ?? 'customer');
      }

      debugPrint('✅ Token & Role berhasil disimpan!');
      return {
        'success': true,
        'message': body['message'] ?? 'Login berhasil',
        'user': user,
      };
    } else {
      debugPrint('❌ Login gagal: ${body['message']}');
      return {'success': false, 'message': body['message'] ?? 'Login gagal'};
    }
  }

  // ==========================================================
  // Register Customer
  // ==========================================================
  Future<Map<String, dynamic>> customerRegister({
    required String name,
    required String alamat,
    required String phone,
    required String gender,
    required String email,
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/customer-register');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'alamat': alamat,
        'phone': phone,
        'gender': gender,
        'email': email,
        'username': username,
        'password': password,
      }),
    );

    debugPrint("REGISTER STATUS: ${response.statusCode}");
    debugPrint("REGISTER RAW BODY: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        "Gagal daftar (${response.statusCode}): ${response.body}",
      );
    }
  }

  // ==========================================================
  // Produk
  // ==========================================================
  Future<Map<String, dynamic>> getProductDetail(int id) async {
    final url = Uri.parse('$baseUrl/products/$id');
    final response = await http.get(url);

    debugPrint('📦 Product Detail Response: ${response.statusCode}');
    debugPrint(response.body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data is Map<String, dynamic> && data.containsKey('data'))
          ? data['data']
          : data;
    } else {
      throw Exception('Gagal mengambil detail produk (${response.statusCode})');
    }
  }

  // ==========================================================
  // Buat Pesanan (Hanya Customer Login)
  // ==========================================================
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) throw Exception("User belum login");

    final url = Uri.parse('$baseUrl/orders');
    final response = await http.post(
      url,
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
      // coba parse body
      try {
        final error = jsonDecode(response.body);
        throw Exception(
          'Gagal membuat pesanan: ${error['message'] ?? response.body}',
        );
      } catch (e) {
        throw Exception('Gagal membuat pesanan: ${response.body}');
      }
    }
  }

  // ==========================================================
  // Ambil Semua Pesanan User (List)
  // ==========================================================
  Future<List<dynamic>> getOrders() async {
    final token = await getToken();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (token == null || userId == null) throw Exception("User belum login");

    final url = Uri.parse('$baseUrl/orders/$userId');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('GET ORDERS STATUS: ${response.statusCode}');
    debugPrint('GET ORDERS BODY: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Pastikan struktur: { success: true, data: [...] }
      if (data is Map<String, dynamic>) {
        return data['data'] is List ? data['data'] : [];
      } else if (data is List) {
        return data;
      } else {
        return [];
      }
    } else if (response.statusCode == 401) {
      throw Exception('Unauthenticated. Token tidak valid.');
    } else {
      throw Exception(
        'Gagal memuat pesanan (${response.statusCode}): ${response.body}',
      );
    }
  }

  // ==========================================================
  // Ambil Single Order (detail) berdasarkan order id
  // ==========================================================
  Future<Map<String, dynamic>> getOrderById(int id) async {
    final token = await getToken();
    if (token == null) throw Exception("User belum login");

    final url = Uri.parse(
      '$baseUrl/order/$id',
    ); // pastikan route di Laravel sama
    final response = await http.get(
      url,
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
        return data['data'] is Map<String, dynamic>
            ? data['data']
            : (data['data'] ?? {});
      } else {
        return {};
      }
    } else if (response.statusCode == 401) {
      throw Exception('Unauthenticated. Token tidak valid.');
    } else {
      throw Exception(
        'Gagal memuat order (${response.statusCode}): ${response.body}',
      );
    }
  }

  // ==========================================================
  // Batalkan Pesanan (update status => Batal)
  // ==========================================================
  Future<bool> cancelOrder(int id) async {
    final token = await getToken();
    if (token == null) throw Exception("User belum login");

    final url = Uri.parse(
      '$baseUrl/orders/$id/cancel',
    ); // pastikan route di Laravel sama
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('CANCEL ORDER STATUS: ${response.statusCode}');
    debugPrint('CANCEL ORDER BODY: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true || (data['message'] != null);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthenticated. Token tidak valid.');
    } else {
      throw Exception(
        'Gagal membatalkan order (${response.statusCode}): ${response.body}',
      );
    }
  }

  // ==========================================================
  // Review Produk
  // ==========================================================
  Future<List<dynamic>> getReviews(int productId) async {
    final url = Uri.parse('$baseUrl/products/$productId/reviews');
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
    final token = await getToken();
    if (token == null) throw Exception("User belum login");

    final url = Uri.parse('$baseUrl/reviews');
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

  // ==========================================================
  // Keranjang (Cek Role)
  // ==========================================================
  Future<List<dynamic>> getCart(int userId) async {
    final token = await getToken();
    if (token == null) throw Exception("User belum login");

    final url = Uri.parse('$baseUrl/cart/$userId');
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
    final token = await getToken();
    if (token == null) throw Exception("User belum login");

    final url = Uri.parse('$baseUrl/cart/$cartId');
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

  // ==========================================================
  // Tambah ke Keranjang
  // ==========================================================
  Future<Map<String, dynamic>> addToCart({
    required int userId,
    required int productId,
    required int qty,
  }) async {
    final token = await getToken();
    final role = await _getRole();

    if (token == null || token.isEmpty) {
      throw Exception("User belum login — token kosong/null");
    }
    if (role == 'guest') {
      throw Exception("Guest tidak bisa menambah ke keranjang");
    }

    final url = Uri.parse('$baseUrl/cart/add');
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
    final token = await getToken();
    if (token == null) throw Exception("User belum login");

    final url = Uri.parse('$baseUrl/cart/remove/$cartId');
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

  // ==========================================================
  // Checkout
  // ==========================================================
  Future<Map<String, dynamic>> checkoutOrder({
    required int userId,
    required int productId,
    required int qty,
    required int price,
    required int total,
    required String paymentMethod,
    required int shipping,
    required int serviceFee,
    required String recipientName,
    required int addressId,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception("User belum login");

    final url = Uri.parse('$baseUrl/orders');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'user_id': userId,
        'product_id': productId,
        'qty': qty,
        'price': price,
        'total': total,
        'payment_method': paymentMethod,
        'shipping': shipping,
        'service_fee': serviceFee,
        'recipient_name': recipientName,
        'shipping_address_id': addressId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        'Gagal membuat pesanan: ${error['message'] ?? response.body}',
      );
    }
  }

  // ==========================================================
  // Alamat Customer
  // ==========================================================
  Future<List<dynamic>> getAddresses() async {
    final token = await getToken(); // ambil token login Sanctum
    final url = Uri.parse('$baseUrl/addresses');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data']; // ini langsung list alamat
      } else {
        throw Exception(data['message'] ?? 'Gagal memuat alamat');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Unauthenticated. Token tidak valid.');
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> addAddress({
    required String recipientName,
    required String phone,
    required String address,
    required bool isPrimary,
  }) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/addresses');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'recipient_name': recipientName,
        'phone': phone,
        'address': address,
        'is_default': isPrimary ? 1 : 0, // ✅ gunakan dari parameter
      }),
    );

    if (response.statusCode != 201) {
      debugPrint('❌ ERROR: ${response.body}');
      throw Exception('Gagal menyimpan alamat (${response.statusCode})');
    }
  }

  Future<void> deleteAddress(int id) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/addresses/$id');

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus alamat: ${response.body}');
    }
  }

  Future<void> setDefaultAddress(int id) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/addresses/$id/default');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengatur alamat utama: ${response.body}');
    }
  }

  // ✅ Booking Service
  Future<Map<String, dynamic>> bookService({
    required String name,
    required String address,
    required String phone,
    required String vehicle,
    required String type,
    required String date,
    required String time,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception("User belum login");

    final url = Uri.parse('$baseUrl/service-booking');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'address': address,
        'phone': phone,
        'vehicle': vehicle,
        'type': type,
        'date': date,
        'time': time,
      }),
    );

    debugPrint("📌 BOOKING RESP: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        "Gagal booking (${response.statusCode}): ${response.body}",
      );
    }
  }

  // ✅ Ambil data booking milik user
  Future<List<dynamic>> getUserServiceBookings(int userId) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/service-booking/$userId');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    } else {
      throw Exception("Gagal memuat data booking");
    }
  }

  // ✅ Ambil Resume Service berdasarkan ID
  Future<Map<String, dynamic>> getResumeById(int serviceId) async {
    final token = await getToken();
    if (token == null) throw Exception("User belum login");

    final url = Uri.parse('$baseUrl/service/$serviceId');
    // pastikan endpoint kamu di Laravel sama seperti ini

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    debugPrint("📌 RESUME RESP: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        "Gagal mengambil resume (${response.statusCode}): ${response.body}",
      );
    }
  }
}
