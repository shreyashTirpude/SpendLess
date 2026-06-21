import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../core/utils/totp.dart' show PasswordHasher;

/// App-lock password storage. Uses PBKDF2-HMAC-SHA256 (salted, 100k iterations)
/// so a leaked hash is impractical to brute-force. Transparently migrates the
/// old unsalted SHA-256 hashes to PBKDF2 on next successful unlock.
class PasswordService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions:
        IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );
  static const _key = 'spendlens_password_hash';

  static String _legacyHash(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  static Future<bool> hasPassword() async {
    final stored = await _storage.read(key: _key);
    return stored != null && stored.isNotEmpty;
  }

  static Future<void> setPassword(String password) async {
    await _storage.write(key: _key, value: PasswordHasher.hash(password));
  }

  static Future<bool> verifyPassword(String password) async {
    final stored = await _storage.read(key: _key);
    if (stored == null) return false;

    // New PBKDF2 format.
    if (stored.startsWith('pbkdf2\$')) {
      return PasswordHasher.verify(password, stored);
    }

    // Legacy unsalted SHA-256 → verify, then upgrade in place.
    if (_constantTimeEquals(stored, _legacyHash(password))) {
      await setPassword(password); // re-hash with PBKDF2
      return true;
    }
    return false;
  }

  static Future<void> clearPassword() async {
    await _storage.delete(key: _key);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
