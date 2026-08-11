import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userRoleKey = 'user_role';

  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  static Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  static Future<bool> hasAccessToken() async {
    final String? token = await getAccessToken();

    return token != null && token.trim().isNotEmpty;
  }

  static Future<void> saveUser({
    required dynamic id,
    required String name,
    String? email,
    String? role,
  }) async {
    await Future.wait([
      _storage.write(key: _userIdKey, value: id.toString()),
      _storage.write(key: _userNameKey, value: name),
      _storage.write(key: _userEmailKey, value: email ?? ''),
      _storage.write(key: _userRoleKey, value: role ?? ''),
    ]);
  }

  static Future<String?> getUserId() async {
    return _storage.read(key: _userIdKey);
  }

  static Future<String?> getUserName() async {
    return _storage.read(key: _userNameKey);
  }

  static Future<String?> getUserEmail() async {
    return _storage.read(key: _userEmailKey);
  }

  static Future<String?> getUserRole() async {
    return _storage.read(key: _userRoleKey);
  }

  static Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _userNameKey),
      _storage.delete(key: _userEmailKey),
      _storage.delete(key: _userRoleKey),
    ]);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
