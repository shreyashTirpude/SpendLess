import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// Value: protects=legal/privacy credibility of every shipped UI string
// fails_when=a false "no internet / no servers" style claim reappears in lib/
// why_new=Terms/Help/onboarding once claimed the app has no internet at all
// while optional account sign-in (Firebase) exists — a claim that DPDP-facing
// trust copy cannot survive; seam=none
void main() {
  // Lowercased phrases that must never appear in shipped UI copy. The app has
  // optional internet-backed sign-in, so absolute offline claims are false.
  // Accuracy rule: financial analysis is on-device and financial data is never
  // uploaded — say THAT, not "the app has no internet".
  const banned = [
    'no servers',
    'no server.',
    'no internet access',
    'no internet. no server',
    'no cloud backend',
    'never read or store',
    'no account, no cloud sync',
  ];

  test('shipped UI copy contains no false offline/no-server privacy claims',
      () {
    final offenders = <String>[];
    for (final entry in Directory('lib').listSync(recursive: true)) {
      if (entry is! File || !entry.path.endsWith('.dart')) continue;
      final text = entry.readAsStringSync().toLowerCase();
      for (final phrase in banned) {
        if (text.contains(phrase)) {
          offenders.add('${entry.path}: "$phrase"');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'Replace with accurate on-device-processing wording. '
            'Offenders: $offenders');
  });
}
