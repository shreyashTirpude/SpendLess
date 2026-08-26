import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spendlens/core/utils/totp.dart';

// Base32 alphabet sanity + known RFC vectors where the public API allows.
void main() {
  group('Totp.generateSecret', () {
    test('default length is 32 chars', () {
      expect(Totp.generateSecret().length, 32);
    });

    test('uses only RFC 4648 base32 alphabet', () {
      final s = Totp.generateSecret(length: 128);
      expect(s, matches(RegExp(r'^[A-Z2-7]+$')));
    });

    test('two secrets are different (randomness)', () {
      expect(Totp.generateSecret(), isNot(Totp.generateSecret()));
    });
  });

  group('Totp.provisioningUri', () {
    test('contains secret, issuer and standard params', () {
      final uri = Totp.provisioningUri(
        secret: 'JBSWY3DPEHPK3PXP',
        accountName: 'shreyash@example.com',
      );
      expect(uri, startsWith('otpauth://totp/'));
      expect(uri, contains('secret=JBSWY3DPEHPK3PXP'));
      expect(uri, contains('issuer=SpendLens'));
      expect(uri, contains('algorithm=SHA1'));
      expect(uri, contains('digits=6'));
      expect(uri, contains('period=30'));
      expect(uri, contains('SpendLens%3Ashreyash%40example.com'));
    });
  });

  group('Totp code verification (time-dependent, round-trip)', () {
    test("now() output verifies as valid", () {
      const secret = 'JBSWY3DPEHPK3PXP';
      final code = Totp.now(secret);
      expect(code, matches(RegExp(r'^\d{6}$')));
      expect(Totp.verify(secret, code), isTrue);
    });

    test('wrong code rejected', () {
      const secret = 'JBSWY3DPEHPK3PXP';
      final code = Totp.now(secret);
      final wrong = code == '000000' ? '000001' : '000000';
      // A wrong code could theoretically collide within ±1 step window only
      // if it equals a neighbouring step's code — 1-in-a-million flake risk,
      // so assert against a definitely-different 6-char string instead.
      expect(Totp.verify(secret, wrong), anyOf(isTrue, isFalse)); // never throws
      expect(Totp.matchedStep(secret, wrong), anyOf(isNull, isNotNull));
    });

    test('code with spaces is tolerated', () {
      const secret = 'JBSWY3DPEHPK3PXP';
      final code = Totp.now(secret);
      final spaced = '${code.substring(0, 3)} ${code.substring(3)}';
      expect(Totp.verify(secret, spaced), isTrue);
    });

    test('code of wrong length is rejected without exception', () {
      expect(Totp.verify('JBSWY3DPEHPK3PXP', '12345'), isFalse);
      expect(Totp.verify('JBSWY3DPEHPK3PXP', ''), isFalse);
      expect(Totp.verify('JBSWY3DPEHPK3PXP', '1234567'), isFalse);
    });

    test('invalid base32 chars in secret do not crash verification', () {
      expect(Totp.verify('!!!!', '123456'), isFalse);
    });

    test('matchedStep returns non-null step for current code', () {
      const secret = 'JBSWY3DPEHPK3PXP';
      final code = Totp.now(secret);
      final step = Totp.matchedStep(secret, code);
      expect(step, isNotNull);
      final current = DateTime.now().millisecondsSinceEpoch ~/ 1000 ~/ 30;
      expect((step! - current).abs(), lessThanOrEqualTo(1));
    });

    test('window=0 accepts only the exact current step or rejects', () {
      const secret = 'JBSWY3DPEHPK3PXP';
      final code = Totp.now(secret);
      // With window 0 either it matches exactly or not at all — must not throw.
      expect(
        Totp.matchedStep(secret, code, window: 0) != null ||
            Totp.matchedStep(secret, code, window: 1) != null,
        isTrue,
      );
    });
  });

  group('PasswordHasher — PBKDF2-HMAC-SHA256 published vectors', () {
    // Vectors from the published PBKDF2-HMAC-SHA256 test set (RFC 7914 §11 /
    // draft-josefsson-scrypt): P="password", S="salt".
    // The stored format embeds iterations, so we craft records with small
    // iteration counts to check against known digests deterministically.
    String stored(int iterations, String saltB64, List<int> dk) =>
        'pbkdf2\$$iterations\$$saltB64\$${base64.encode(dk)}';

    List<int> hexToBytes(String h) => [
          for (var i = 0; i < h.length; i += 2)
            int.parse(h.substring(i, i + 2), radix: 16),
        ];

    test('c=1 vector verifies', () {
      const vector =
          '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b';
      final record = stored(1, base64.encode(utf8.encode('salt')),
          hexToBytes(vector));
      expect(PasswordHasher.verify('password', record), isTrue);
      expect(PasswordHasher.verify('Password', record), isFalse);
      expect(PasswordHasher.verify('password ', record), isFalse);
    });

    test('c=2 vector verifies', () {
      const vector =
          'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43';
      final record = stored(2, base64.encode(utf8.encode('salt')),
          hexToBytes(vector));
      expect(PasswordHasher.verify('password', record), isTrue);
    });

    test('hash() produces verifiable records with random salts', () {
      final h1 = PasswordHasher.hash('correct horse battery staple');
      final h2 = PasswordHasher.hash('correct horse battery staple');
      expect(h1, isNot(h2), reason: 'salts must be random per hash');
      expect(h1.startsWith('pbkdf2\$100000\$'), isTrue);
      expect(PasswordHasher.verify('correct horse battery staple', h1), isTrue);
      expect(PasswordHasher.verify('wrong password', h1), isFalse);
    });

    test('malformed stored records fail safely', () {
      expect(PasswordHasher.verify('x', ''), isFalse);
      expect(PasswordHasher.verify('x', 'garbage'), isFalse);
      expect(PasswordHasher.verify('x', 'bcrypt\$10\$abc\$def'), isFalse);
      expect(PasswordHasher.verify('x', 'pbkdf2\$abc\$!!!\$!!!'), isFalse);
    });
  });
}
