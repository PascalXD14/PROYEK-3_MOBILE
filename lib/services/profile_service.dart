import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'auth_service.dart';

class UserProfile {
  final int id;
  final String username;
  final String email;
  final String? name;
  final String? role;
  final String? avatarUrl;
  final String? phone;
  final String? address;
  final String? gender;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.name,
    this.role,
    this.avatarUrl,
    this.phone,
    this.address,
    this.gender,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) {
    final rawAvatar = (j['avatar_url'] ?? j['avatar'] ?? '') as String?;
    final avatar = ApiConfig.toAbsolute(rawAvatar);

    String? phone;
    if (j['phone'] != null && j['phone'].toString().trim().isNotEmpty) {
      phone = j['phone'].toString();
    } else if (j['phone_number'] != null &&
        j['phone_number'].toString().trim().isNotEmpty) {
      phone = j['phone_number'].toString();
    }

    String? address;
    if (j['address'] != null && j['address'].toString().trim().isNotEmpty) {
      address = j['address'].toString();
    } else if (j['alamat'] != null &&
        j['alamat'].toString().trim().isNotEmpty) {
      address = j['alamat'].toString();
    }

    String? gender;
    if (j['gender'] != null && j['gender'].toString().trim().isNotEmpty) {
      gender = j['gender'].toString();
    } else if (j['jenis_kelamin'] != null &&
        j['jenis_kelamin'].toString().trim().isNotEmpty) {
      gender = j['jenis_kelamin'].toString();
    }

    final idValue = j['id'];
    final id = idValue is int
        ? idValue
        : int.tryParse((idValue ?? '0').toString()) ?? 0;

    return UserProfile(
      id: id,
      username: (j['username'] ?? '').toString(),
      email: (j['email'] ?? '').toString(),
      name: j['name']?.toString(),
      role: j['role']?.toString(),
      avatarUrl: avatar.isNotEmpty ? avatar : null,
      phone: phone,
      address: address,
      gender: gender,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'name': name,
    'role': role,
    'avatar_url': avatarUrl,
    'phone': phone,
    'address': address,
    'gender': gender,
  };
}

class ProfileService {
  final String token;
  ProfileService(this.token);

  Map<String, String> get _jsonHeaders => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Map<String, String> get _acceptHeaders => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  /// GET /api/me
  Future<UserProfile> getMe() async {
    final uri = ApiConfig.endpoint('me');
    debugPrint('GET $uri');
    final res = await http.get(uri, headers: _acceptHeaders);

    debugPrint('GET /me => ${res.statusCode}: ${res.body}');

    if (res.statusCode != 200) {
      throw Exception('Gagal memuat profil (${res.statusCode}): ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final userJson = map['data'] ?? map;
    return UserProfile.fromJson(userJson as Map<String, dynamic>);
  }

  /// POST /api/me/avatar (multipart)
  Future<String> uploadAvatar(File file) async {
    final uri = ApiConfig.endpoint('me/avatar');
    debugPrint('UPLOAD AVATAR -> $uri (file: ${file.path})');

    final req = http.MultipartRequest('POST', uri)
      ..headers.addAll(_acceptHeaders)
      ..files.add(await http.MultipartFile.fromPath('avatar', file.path));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    debugPrint('UPLOAD AVATAR => ${res.statusCode}: ${res.body}');

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Upload gagal (${res.statusCode}): ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final avatarRaw =
        data['avatar_url'] ??
        data['data']?['avatar_url'] ??
        data['data']?['avatar'];
    final avatar = ApiConfig.toAbsolute(avatarRaw as String?);
    return avatar;
  }

  /// PATCH /api/me
  Future<UserProfile> updateProfile(Map<String, dynamic> payload) async {
    final uri = ApiConfig.endpoint('me'); // <- endpoint yang benar
    debugPrint('UPDATE PROFILE => PATCH $uri');
    debugPrint('Payload: ${jsonEncode(payload)}');

    final res = await http.patch(
      uri,
      headers: _jsonHeaders,
      body: jsonEncode(payload),
    );

    debugPrint('UPDATE RESP ${res.statusCode}: ${res.body}');

    // success with body (200 or 201)
    if (res.statusCode == 200 || res.statusCode == 201) {
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      final userJson = map['data'] ?? map;

      // simpan cache (jangan crash kalau AuthService bermasalah)
      try {
        await AuthService().setCachedUserInfo(userJson as Map<String, dynamic>);
      } catch (_) {}

      return UserProfile.fromJson(userJson as Map<String, dynamic>);
    }

    // accepted no content -> re-fetch
    if (res.statusCode == 204) {
      final me = await getMe();
      try {
        await AuthService().setCachedUserInfo(me.toJson());
      } catch (_) {}
      return me;
    }

    // validation error
    if (res.statusCode == 422 || res.statusCode == 400) {
      String msg = 'Gagal update profil (${res.statusCode})';
      try {
        final b = jsonDecode(res.body);
        msg += ': ${b.toString()}';
      } catch (_) {}
      throw Exception(msg);
    }

    if (res.statusCode == 401) {
      throw Exception('Unauthorized: token tidak valid atau kadaluarsa.');
    }
    if (res.statusCode == 403) {
      throw Exception(
        'Forbidden: tidak memiliki izin untuk mengubah profil ini.',
      );
    }
    throw Exception('Gagal update profil (${res.statusCode}): ${res.body}');
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final uri = ApiConfig.endpoint('me/change-password');
    debugPrint('CHANGE PASSWORD -> $uri');

    final res = await http.post(
      uri,
      headers: _jsonHeaders,
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation':
            newPassword, 
      }),
    );

    debugPrint('CHANGE PASSWORD => ${res.statusCode}: ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 204) {
      return;
    }

    // coba parse pesan error
    String msg = 'Gagal ganti password (${res.statusCode})';
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['message'] != null) {
        msg = body['message'].toString();
      } else if (body is Map && body['errors'] != null) {
        final errors = body['errors'] as Map;
        if (errors.values.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty)
            msg = first.first.toString();
          else
            msg = first.toString();
        }
      } else {
        msg = res.body;
      }
    } catch (_) {}
    throw Exception(msg);
  }

  //logout
  Future<void> logout() async {
    final uri = ApiConfig.endpoint('logout');
    debugPrint('LOGOUT -> $uri');
    try {
      await http.post(uri, headers: _acceptHeaders);
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }
}
