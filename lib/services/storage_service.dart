import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _kToken    = 'token';
  static const _kUserId   = 'user_id';
  static const _kRole     = 'role';
  static const _kName     = 'name';
  static const _kEmail    = 'email';
  static const _kUsername = 'username';
  static const _kAvatar   = 'avatar_url';

  Future<String?> getToken() async =>
      (await SharedPreferences.getInstance()).getString(_kToken);

  Future<int?> getUserId() async =>
      (await SharedPreferences.getInstance()).getInt(_kUserId);

  Future<String?> getRole() async =>
      (await SharedPreferences.getInstance()).getString(_kRole);

  Future<String?> getName() async =>
      (await SharedPreferences.getInstance()).getString(_kName);

  Future<String?> getEmail() async =>
      (await SharedPreferences.getInstance()).getString(_kEmail);

  Future<String?> getUsername() async =>
      (await SharedPreferences.getInstance()).getString(_kUsername);

  Future<String?> getAvatarUrl() async =>
      (await SharedPreferences.getInstance()).getString(_kAvatar);

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user.containsKey('id') && user['id'] != null) {
      await prefs.setInt(_kUserId, user['id'] as int);
    }
    if (user.containsKey('role') && user['role'] != null) {
      await prefs.setString(_kRole, user['role'].toString());
    }
    if (user.containsKey('name')) {
      await prefs.setString(_kName, (user['name'] ?? '').toString());
    }
    if (user.containsKey('email')) {
      await prefs.setString(_kEmail, (user['email'] ?? '').toString());
    }
    if (user.containsKey('username')) {
      await prefs.setString(_kUsername, (user['username'] ?? '').toString());
    }
    if (user.containsKey('avatar_url')) {
      await prefs.setString(_kAvatar, (user['avatar_url'] ?? '').toString());
    }
  }

  Future<void> setAvatar(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAvatar, url);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUserId);
    await prefs.remove(_kRole);
    await prefs.remove(_kName);
    await prefs.remove(_kEmail);
    await prefs.remove(_kUsername);
    await prefs.remove(_kAvatar);
  }
}
