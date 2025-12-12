import 'dart:convert';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import '../services/storage_service.dart';
import '../models/chat_message.dart';

class ChatService {
  final StorageService _storage = StorageService();

  final int adminId = 1;

  Future<List<ChatMessage>> getMessages() async {
    final token = await _storage.getToken();
    if (token == null) {
      throw Exception('Belum login');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/chat/$adminId');

    final res = await http.get(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal load pesan: ${res.body}');
    }

    final List data = jsonDecode(res.body) as List;
    return data.map((e) => ChatMessage.fromJson(e)).toList();
  }

  Future<ChatMessage> sendMessage(
    String body, {
    int? productId,
    String? productName,
    int? productPrice,
    String? productImage,
  }) async {
    final token = await _storage.getToken();
    if (token == null) {
      throw Exception('Belum login');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/chat/$adminId');

    final res = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'body': body,
        'product_id': productId,
        'product_name': productName,
        'product_price': productPrice,
        'product_image': productImage,
      }),
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Gagal kirim pesan: ${res.body}');
    }

    final data = jsonDecode(res.body);
    return ChatMessage.fromJson(data);
  }
}
