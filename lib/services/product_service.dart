import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'api_config.dart';

class ProductService {
  static final ValueNotifier<int> refreshNotifier = ValueNotifier<int>(0);
  static void notifyProductsChanged() {
    refreshNotifier.value++;
  }

  Future<List<dynamic>> getProducts() async {
    final response = await http.get(ApiConfig.endpoint('products'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('data')) return data['data'];
      if (data is List) return data;
      throw Exception('Format respons tidak sesuai');
    } else {
      throw Exception('Gagal memuat produk (${response.statusCode})');
    }
  }

  Future<Map<String, dynamic>> getProductDetail(int id) async {
    final response = await http.get(ApiConfig.endpoint('products/$id'));
    debugPrint('Product Detail Response: ${response.statusCode}');
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
}
