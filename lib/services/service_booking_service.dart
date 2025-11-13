import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'storage_service.dart';

class ServiceBookingService {
  final StorageService _storage = StorageService();

  /// Membuat booking service. Mengembalikan object `data` dari response API.
  Future<Map<String, dynamic>> bookService({
    required String name,
    required String address,
    required String phone,
    required String vehicle,
    required String type,
    required String date,
    required String time,
  }) async {
    final token = await _storage.getToken();
    if (token == null) throw Exception("User belum login");

    final url = ApiConfig.endpoint('service-booking');

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
      final Map<String, dynamic> json = jsonDecode(response.body);
      // Kembalikan data booking (utamakan json['data'] bila ada)
      if (json.containsKey('data') && json['data'] is Map) {
        return Map<String, dynamic>.from(json['data']);
      } else {
        return json;
      }
    } else {
      throw Exception("Gagal booking (${response.statusCode}): ${response.body}");
    }
  }

  /// Ambil booking milik user tertentu. Mengembalikan list `data`.
  Future<List<dynamic>> getUserServiceBookings(int userId) async {
    final token = await _storage.getToken();
    final url = ApiConfig.endpoint('service-booking/$userId');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    debugPrint("📌 GET BOOKINGS RESP: ${response.body}");

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return List<dynamic>.from(json['data'] ?? []);
    } else {
      throw Exception("Gagal memuat data booking");
    }
  }

  /// Ambil resume by id (detail). Mengembalikan object data atau {data: {...}}
  Future<Map<String, dynamic>?> getResumeById(int serviceId) async {
    final token = await _storage.getToken();
    if (token == null) throw Exception("User belum login");

    final url = ApiConfig.endpoint('service/$serviceId');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    debugPrint("📌 RESUME RESP: ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      if (json.containsKey('data') && json['data'] is Map) {
        return Map<String, dynamic>.from(json['data']);
      } else {
        // kalau API mengembalikan object langsung
        return Map<String, dynamic>.from(json);
      }
    } else {
      throw Exception("Gagal mengambil resume (${response.statusCode}): ${response.body}");
    }
  }
}
