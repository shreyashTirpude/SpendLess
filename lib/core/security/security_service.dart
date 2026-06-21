import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  static const _recoveryKeyStorageKey = 'spendlens_recovery_key';

  // ── Recovery key (generated when password is first set) ──────────────────

  static Future<String> generateAndStoreRecoveryKey() async {
    final random = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no ambiguous chars
    final key = List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
    final hashed = sha256.convert(utf8.encode(key)).toString();
    await _storage.write(key: _recoveryKeyStorageKey, value: hashed);
    return key; // shown once to user, never stored in plain
  }

  static Future<bool> verifyRecoveryKey(String input) async {
    final stored = await _storage.read(key: _recoveryKeyStorageKey);
    if (stored == null) return false;
    final inputHash = sha256.convert(utf8.encode(input.toUpperCase().trim())).toString();
    return _timingSafeCompare(stored, inputHash);
  }

  static Future<void> clearRecoveryKey() async {
    await _storage.delete(key: _recoveryKeyStorageKey);
  }

  // ── Input validation ──────────────────────────────────────────────────────

  static String? validateAmount(String input) {
    if (input.trim().isEmpty) return 'Amount is required';
    final cleaned = input.replaceAll(',', '').trim();
    final amount = double.tryParse(cleaned);
    if (amount == null) return 'Enter a valid number';
    if (amount <= 0) return 'Amount must be greater than zero';
    if (amount > 10000000) return 'Amount seems too large';
    return null; // valid
  }

  static String? validateMerchantName(String input) {
    if (input.trim().isEmpty) return 'Merchant name is required';
    if (input.length > 100) return 'Name too long (max 100 chars)';
    // Reject script-injection patterns
    if (_containsScriptPattern(input)) return 'Invalid characters in name';
    return null;
  }

  static String? validatePassword(String input) {
    if (input.length < 6) return 'Use at least 6 characters';
    if (input.length > 64) return 'Password too long';
    // Reject trivially-guessable PINs.
    const weak = {
      '000000', '111111', '123456', '654321', '121212', '123123',
      '112233', '1234', '0000', '1111', 'password', 'admin'
    };
    if (weak.contains(input.toLowerCase())) return 'This code is too common';
    return null;
  }

  static bool _containsScriptPattern(String input) {
    final patterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), // control chars
    ];
    return patterns.any((p) => p.hasMatch(input));
  }

  // Constant-time string comparison to prevent timing attacks
  static bool _timingSafeCompare(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  // ── Sanitize text for display (no XSS in webviews) ───────────────────────

  static String sanitizeForDisplay(String raw) {
    return raw
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }
}
