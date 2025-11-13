import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'storage_service.dart';

class AddressService {
  final StorageService _storage = StorageService();

  Future<List<dynamic>> getAddresses() async {
    final token = await _storage.getToken(); // ambil token login Sanctum
    final url = ApiConfig.endpoint('addresses');

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
    final token = await _storage.getToken();
    final url = ApiConfig.endpoint('addresses');

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
        'is_default': isPrimary ? 1 : 0, // gunakan dari parameter
      }),
    );

    if (response.statusCode != 201) {
      debugPrint('❌ ERROR: ${response.body}');
      throw Exception('Gagal menyimpan alamat (${response.statusCode})');
    }
  }

  Future<void> deleteAddress(int id) async {
    final token = await _storage.getToken();
    final url = ApiConfig.endpoint('addresses/$id');

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
    final token = await _storage.getToken();
    final url = ApiConfig.endpoint('addresses/$id/default');

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
}
