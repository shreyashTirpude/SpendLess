import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spendlens/services/email_service.dart';

// Value: protects=email provider secrets from the distributed app;
// fails_when=client reads a provider credential or sends email directly;
// why_new=existing security tests do not exercise email transport or assets; seam=none
void main() {
  test('client cannot send email with a bundled provider credential', () async {
    dotenv.testLoad(fileInput: 'RESEND_API_KEY=synthetic-test-value');
    final requests = <http.Request>[];
    final result = await http.runWithClient(
      () => EmailService.sendOtp(to: 'fixture@example.invalid', code: '123456', purpose: 'test'),
      () => MockClient((request) async {
        requests.add(request);
        return http.Response('{}', 200);
      }),
    );
    expect(requests, isEmpty);
    expect(result.sent, isFalse);
  });
  test('private environment files are not declared as Flutter assets', () {
    final manifest = File('pubspec.yaml').readAsStringSync();
    expect(RegExp(r'^\s*-\s*\.env\s*$', multiLine: true).hasMatch(manifest), isFalse);
  });
}
