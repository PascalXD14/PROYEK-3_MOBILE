import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'storage_service.dart';
import '../models/app_notification.dart';

class NotificationService {
  final StorageService _storage = StorageService();

  Future<List<AppNotification>> getNotifications() async {
    final token = await _storage.getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/notifications');
    print('HIT NOTIF: $url');
    print('TOKEN: $token');

    final response = await http.get(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    print('STATUS CODE: ${response.statusCode}');
    print('BODY: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final body = jsonDecode(response.body);

    final List<dynamic> list = body is Map<String, dynamic>
        ? (body['data'] as List<dynamic>)
        : body;

    print('LIST RAW: $list');
    list.forEach((e) {
      print('IMG: ${e['image_url']}'); // 🔍 CEK NILAI
    });

    return list
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> deleteNotification(int id) async {
    final token = await _storage.getToken();
    if (token == null) throw Exception("Token tidak ditemukan");

    final url = Uri.parse("${ApiConfig.baseUrl}/notifications/$id");

    final response = await http.delete(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }
}
