import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class UserProfile {
  final int id;
  final String username;
  final String email;
  final String? name;
  final String? role;
  final String? avatarUrl;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.name,
    this.role,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id: j['id'] as int,
        username: (j['username'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        name: j['name'] as String?,
        role: j['role'] as String?,
        avatarUrl: ApiConfig.toAbsolute(j['avatar_url'] as String?),
      );
}

class ProfileService {
  final String token;
  ProfileService(this.token);

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

  Future<UserProfile> getMe() async {
    final res = await http.get(ApiConfig.endpoint('me'), headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Gagal memuat profil (${res.statusCode})');
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return UserProfile.fromJson(map);
  }

  Future<String> uploadAvatar(File file) async {
    final req = http.MultipartRequest('POST', ApiConfig.endpoint('me/avatar'))
      ..headers.addAll(_headers)
      ..files.add(await http.MultipartFile.fromPath('avatar', file.path));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      throw Exception('Upload gagal (${res.statusCode})');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return ApiConfig.toAbsolute(data['avatar_url'] as String?);
  }

  Future<void> logout() async {
    await http.post(ApiConfig.endpoint('logout'), headers: _headers);
  }
}
