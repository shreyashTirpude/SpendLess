import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class PasswordService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _key = 'spendlens_password_hash';

  static String _hash(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  static Future<bool> hasPassword() async {
    final stored = await _storage.read(key: _key);
    return stored != null && stored.isNotEmpty;
  }

  static Future<void> setPassword(String password) async {
    await _storage.write(key: _key, value: _hash(password));
  }

  static Future<bool> verifyPassword(String password) async {
    final stored = await _storage.read(key: _key);
    if (stored == null) return false;
    return stored == _hash(password);
  }

  static Future<void> clearPassword() async {
    await _storage.delete(key: _key);
  }
}
