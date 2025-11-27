import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class AuthService {
  static const _kToken = 'token';
  static const _kUserId = 'user_id';
  static const _kRole = 'role';
  static const _kName = 'name';
  static const _kEmail = 'email';
  static const _kUsername = 'username';
  static const _kAvatar = 'avatar_url';
  static const _kPhone = 'phone';
  static const _kAddress = 'address';

  // Notifier supaya UI (header dll.) bisa listen perubahan avatar langsung
  static final ValueNotifier<String?> avatarNotifier = ValueNotifier<String?>(
    null,
  );

  // Panggil sekali di app startup (main) supaya notifier diisi dari prefs
  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kAvatar) ?? '';
    avatarNotifier.value = ApiConfig.toAbsolute(raw);
  }

  Future<Map<String, dynamic>> guestLogin() async {
    final res = await http.get(ApiConfig.endpoint('guest-login'));
    if (res.statusCode != 200) {
      throw Exception('Gagal login sebagai tamu (${res.statusCode})');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();

    final token = data['token'];
    if (token != null && token.toString().isNotEmpty) {
      await prefs.setString(_kToken, token.toString());
    }
    await prefs.setString(_kRole, 'guest');

    // nggak ada avatar biasanya for guest -> kosong
    await prefs.remove(_kAvatar);
    // also remove phone/address for guest
    await prefs.remove(_kPhone);
    await prefs.remove(_kAddress);
    avatarNotifier.value = null;

    return data;
  }

  /// Customer login
  Future<Map<String, dynamic>> customerLogin(
    String username,
    String password,
  ) async {
    final res = await http.post(
      ApiConfig.endpoint('customer-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    debugPrint('LOGIN RESP (${res.statusCode}): ${res.body}');
    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      body = {};
    }

    final success =
        res.statusCode == 200 &&
        (body['status'] == 'success' || body['success'] == true);

    if (!success) {
      return {'success': false, 'message': body['message'] ?? 'Login gagal'};
    }

    final prefs = await SharedPreferences.getInstance();

    final token =
        body['token'] ?? body['data']?['token'] ?? body['user']?['token'];

    if (token != null && token.toString().isNotEmpty) {
      await prefs.setString(_kToken, token.toString());
      debugPrint('Token disimpan: $token');
    }

    // take user object from possible locations
    final user = (body['user'] ?? body['data'] ?? {}) as Map<String, dynamic>;
    if (user.isNotEmpty) {
      if (user['id'] != null) await prefs.setInt(_kUserId, user['id']);
      await prefs.setString(_kRole, (user['role'] ?? 'customer').toString());
      await prefs.setString(_kName, (user['name'] ?? '').toString());
      await prefs.setString(_kEmail, (user['email'] ?? '').toString());
      await prefs.setString(_kUsername, (user['username'] ?? '').toString());

      // phone (optional) — cek beberapa kemungkinan key (phone / phone_number)
      final phoneRaw = (user['phone'] ?? user['phone_number'] ?? '').toString();
      if (phoneRaw.isNotEmpty) {
        await prefs.setString(_kPhone, phoneRaw);
      } else {
        await prefs.remove(_kPhone);
      }

      // address (optional) — cek 'address' atau 'alamat'
      final addressRaw = (user['address'] ?? user['alamat'] ?? '').toString();
      if (addressRaw.isNotEmpty) {
        await prefs.setString(_kAddress, addressRaw);
      } else {
        await prefs.remove(_kAddress);
      }

      // pastikan avatar disimpan sebagai ABSOLUT
      final rawAvatar = (user['avatar_url'] ?? user['avatar'] ?? '').toString();
      final absoluteAvatar = ApiConfig.toAbsolute(rawAvatar);
      if (absoluteAvatar.isNotEmpty) {
        await prefs.setString(_kAvatar, absoluteAvatar);
        avatarNotifier.value = absoluteAvatar;
      } else {
        await prefs.remove(_kAvatar);
        avatarNotifier.value = null;
      }
    }

    return {
      'success': true,
      'message': body['message'] ?? 'Login berhasil',
      'user': user,
    };
  }

  /// Register (tetap sama)
  Future<Map<String, dynamic>> customerRegister({
    required String name,
    required String alamat,
    required String phone,
    required String gender,
    required String email,
    required String username,
    required String password,
  }) async {
    final res = await http.post(
      ApiConfig.endpoint('customer-register'),
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

    debugPrint('REGISTER STATUS: ${res.statusCode}');
    debugPrint('REGISTER BODY  : ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Gagal daftar (${res.statusCode}): ${res.body}');
  }

  Future<String?> getToken() async =>
      (await SharedPreferences.getInstance()).getString(_kToken);

  Future<int?> getUserId() async =>
      (await SharedPreferences.getInstance()).getInt(_kUserId);

  Future<Map<String, String>> getCachedUserInfo() async {
    final p = await SharedPreferences.getInstance();
    return {
      'name': p.getString(_kName) ?? '',
      'email': p.getString(_kEmail) ?? '',
      'username': p.getString(_kUsername) ?? '',
      'avatar_url': p.getString(_kAvatar) ?? '',
      'role': p.getString(_kRole) ?? '',
      'phone': p.getString(_kPhone) ?? '',
      'address': p.getString(_kAddress) ?? '',
    };
  }

  /// Simpan kembali informasi user ke cache (dipanggil setelah update profil sukses)
  Future<void> setCachedUserInfo(Map<String, dynamic> user) async {
    final p = await SharedPreferences.getInstance();
    if (user['id'] != null) {
      try {
        await p.setInt(
          _kUserId,
          (user['id'] is int) ? user['id'] : int.parse(user['id'].toString()),
        );
      } catch (_) {}
    }
    if (user['name'] != null)
      await p.setString(_kName, (user['name'] ?? '').toString());
    if (user['email'] != null)
      await p.setString(_kEmail, (user['email'] ?? '').toString());
    if (user['username'] != null)
      await p.setString(_kUsername, (user['username'] ?? '').toString());
    if (user['role'] != null)
      await p.setString(_kRole, (user['role'] ?? '').toString());

    // phone/address
    final phoneRaw = (user['phone'] ?? user['phone_number'] ?? '').toString();
    if (phoneRaw.isNotEmpty) {
      await p.setString(_kPhone, phoneRaw);
    } else {
      await p.remove(_kPhone);
    }

    final addressRaw = (user['address'] ?? user['alamat'] ?? '').toString();
    if (addressRaw.isNotEmpty) {
      await p.setString(_kAddress, addressRaw);
    } else {
      await p.remove(_kAddress);
    }

    // avatar (pastikan absolut)
    final rawAvatar = (user['avatar_url'] ?? user['avatar'] ?? '').toString();
    final absoluteAvatar = ApiConfig.toAbsolute(rawAvatar);
    if (absoluteAvatar.isNotEmpty) {
      await p.setString(_kAvatar, absoluteAvatar);
      avatarNotifier.value = absoluteAvatar;
    } else {
      await p.remove(_kAvatar);
      avatarNotifier.value = null;
    }
  }

  Future<void> setCachedAvatar(String url) async {
    final p = await SharedPreferences.getInstance();
    final absolute = ApiConfig.toAbsolute(url);
    if (absolute.isNotEmpty) {
      await p.setString(_kAvatar, absolute);
      avatarNotifier.value = absolute;
    } else {
      await p.remove(_kAvatar);
      avatarNotifier.value = null;
    }
  }

  Future<void> logout() async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      try {
        await http.post(
          ApiConfig.endpoint('logout'),
          headers: {'Authorization': 'Bearer $token'},
        );
      } catch (_) {
        // ignore network errors
      }
    }
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kUserId);
    await p.remove(_kRole);
    await p.remove(_kName);
    await p.remove(_kEmail);
    await p.remove(_kUsername);
    await p.remove(_kAvatar);
    await p.remove(_kPhone);
    await p.remove(_kAddress);
    avatarNotifier.value = null;
  }
}
