import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// RFC 6238 TOTP + RFC 4226 HOTP — dependency-free MFA implementation.
///
/// Compatible with Google Authenticator, Authy, 1Password, Microsoft
/// Authenticator. Generates the otpauth:// URI for QR provisioning and verifies
/// 6-digit codes with a ±1 step window to tolerate clock skew.
class Totp {
  static const _base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  /// Generate a new random base32 secret (160-bit, 32 chars).
  static String generateSecret({int length = 32}) {
    final rnd = Random.secure();
    final buf = StringBuffer();
    for (var i = 0; i < length; i++) {
      buf.write(_base32Alphabet[rnd.nextInt(_base32Alphabet.length)]);
    }
    return buf.toString();
  }

  /// otpauth:// URI for QR-code provisioning into an authenticator app.
  static String provisioningUri({
    required String secret,
    required String accountName,
    String issuer = 'SpendLens',
  }) {
    final label = Uri.encodeComponent('$issuer:$accountName');
    final params = {
      'secret': secret,
      'issuer': issuer,
      'algorithm': 'SHA1',
      'digits': '6',
      'period': '30',
    };
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return 'otpauth://totp/$label?$query';
  }

  /// Current 6-digit code for a secret.
  static String now(String secret, {int digits = 6, int period = 30}) {
    final counter = DateTime.now().millisecondsSinceEpoch ~/ 1000 ~/ period;
    return _hotp(secret, counter, digits: digits);
  }

  /// Verify a user-entered code against the secret, allowing ±1 time step.
  static bool verify(String secret, String code,
          {int digits = 6, int period = 30, int window = 1}) =>
      matchedStep(secret, code,
          digits: digits, period: period, window: window) !=
      null;

  /// Like [verify] but returns the time-step that matched (or null). Callers
  /// persist the last accepted step to block replay of the same code within
  /// its validity window.
  static int? matchedStep(String secret, String code,
      {int digits = 6, int period = 30, int window = 1}) {
    final clean = code.replaceAll(RegExp(r'\s'), '');
    if (clean.length != digits) return null;
    final step = DateTime.now().millisecondsSinceEpoch ~/ 1000 ~/ period;
    for (var i = -window; i <= window; i++) {
      if (_hotp(secret, step + i, digits: digits) == clean) return step + i;
    }
    return null;
  }

  // ── Internals ────────────────────────────────────────────────────────────────

  static String _hotp(String secret, int counter, {int digits = 6}) {
    final key = _base32Decode(secret);
    final msg = ByteData(8)..setUint64(0, counter, Endian.big);
    final hmac = Hmac(sha1, key).convert(msg.buffer.asUint8List()).bytes;
    final offset = hmac[hmac.length - 1] & 0x0f;
    final binary = ((hmac[offset] & 0x7f) << 24) |
        ((hmac[offset + 1] & 0xff) << 16) |
        ((hmac[offset + 2] & 0xff) << 8) |
        (hmac[offset + 3] & 0xff);
    final otp = binary % pow(10, digits).toInt();
    return otp.toString().padLeft(digits, '0');
  }

  static Uint8List _base32Decode(String input) {
    final clean = input.toUpperCase().replaceAll('=', '').replaceAll(' ', '');
    var bits = 0;
    var value = 0;
    final out = <int>[];
    for (final c in clean.codeUnits) {
      final idx = _base32Alphabet.indexOf(String.fromCharCode(c));
      if (idx < 0) continue;
      value = (value << 5) | idx;
      bits += 5;
      if (bits >= 8) {
        out.add((value >> (bits - 8)) & 0xff);
        bits -= 8;
      }
    }
    return Uint8List.fromList(out);
  }
}

/// Strong password hashing using PBKDF2-HMAC-SHA256 with a random salt.
/// Stored format: `pbkdf2$<iterations>$<saltB64>$<hashB64>`.
class PasswordHasher {
  static const _iterations = 100000;
  static const _keyLen = 32;

  static String hash(String password) {
    final salt = _randomBytes(16);
    final dk = _pbkdf2(utf8.encode(password), salt, _iterations, _keyLen);
    return 'pbkdf2\$$_iterations\$${base64.encode(salt)}\$${base64.encode(dk)}';
  }

  static bool verify(String password, String stored) {
    try {
      final parts = stored.split('\$');
      if (parts.length != 4 || parts[0] != 'pbkdf2') return false;
      final iterations = int.parse(parts[1]);
      final salt = base64.decode(parts[2]);
      final expected = base64.decode(parts[3]);
      final dk = _pbkdf2(utf8.encode(password), salt, iterations, expected.length);
      return _constantTimeEquals(dk, expected);
    } catch (_) {
      return false;
    }
  }

  static List<int> _pbkdf2(
      List<int> password, List<int> salt, int iterations, int keyLen) {
    final hmac = Hmac(sha256, password);
    final blocks = (keyLen / 32).ceil();
    final out = <int>[];
    for (var block = 1; block <= blocks; block++) {
      final salted = [...salt, ...(_intToBytes(block))];
      var u = hmac.convert(salted).bytes;
      final t = List<int>.from(u);
      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      out.addAll(t);
    }
    return out.sublist(0, keyLen);
  }

  static List<int> _intToBytes(int value) => [
        (value >> 24) & 0xff,
        (value >> 16) & 0xff,
        (value >> 8) & 0xff,
        value & 0xff,
      ];

  static List<int> _randomBytes(int n) {
    final rnd = Random.secure();
    return List<int>.generate(n, (_) => rnd.nextInt(256));
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
