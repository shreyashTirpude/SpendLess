import 'package:flutter_test/flutter_test.dart';
import 'package:telephony/telephony.dart';
import 'package:spendlens/core/utils/sms_parser.dart';

// Value: protects=bank SMS sender identity at the inbox/parser boundary;
// fails_when=address is dropped or a lookalike header bypasses the allowlist;
// why_new=parser body tests omit sender metadata; seam=none
void main() {
  const body = 'INR 500.00 debited from A/c XX4821 via UPI. Avl Bal: INR 9500.00.';
  final date = DateTime(2026, 6, 19, 10);
  for (final sender in ['HDFCBK', 'AD-HDFCBK', 'VM-HDFCBK-S', 'SBIBNK-T']) {
    test('accepts registered bank header $sender', () {
      expect(SmsParser.parseSingle(body, date, senderAddress: sender)?.amount, 500);
    });
  }
  for (final sender in ['+919999999999', 'HDFCBKSCAM', 'AD-HDFCBKSCAM']) {
    test('rejects sender $sender', () {
      expect(SmsParser.parseSingle(body, date, senderAddress: sender), isNull);
    });
  }
  test('bulk inbox parser rejects untrusted and missing sender metadata', () {
    SmsMessage message(String? address) => SmsMessage.fromMap({
      'address': address, 'body': body, 'date': '${date.millisecondsSinceEpoch}',
    }, [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE]);
    final result = SmsParser.parseMessages([
      message('AD-HDFCBK'), message('+919999999999'), message(null), message(''),
    ]);
    expect(result.parsedMessages, hasLength(1));
    expect(result.rejectedCount, 3);
    expect(result.parsedMessages.single.transactionDate, date);
  });
}
