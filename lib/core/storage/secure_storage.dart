import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userRoleKey = 'user_role';

  static const String _cacheKeyPrefix = 'cache_key_';

  /// Kunci AES-256 acak per akun. Dibuat sekali, disimpan di Keystore/Keychain.
  static Future<List<int>> getOrCreateCacheKey(String userId) async {
    final String name = '$_cacheKeyPrefix$userId';
    final String? existing = await _storage.read(key: name);
    if (existing != null && existing.isNotEmpty) {
      return base64Decode(existing);
    }

    final Random rnd = Random.secure();
    final List<int> bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
    await _storage.write(key: name, value: base64Encode(bytes));
    return bytes;
  }

  static Future<void> deleteCacheKey(String userId) {
    return _storage.delete(key: '$_cacheKeyPrefix$userId');
  }

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
    final Map<String, String> semua = await _storage.readAll();
    for (final String key in semua.keys) {
      if (!key.startsWith(_cacheKeyPrefix)) {
        await _storage.delete(key: key);
      }
    }
  }
}
