import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:telephony/telephony.dart';
import '../core/utils/sms_parser.dart';
import '../data/local/hive_service.dart';

class SmsScannerService {
  static final _telephony = Telephony.instance;

  /// Call once on first launch (or from settings "Re-scan SMS").
  /// Reads the last 6 months of SMS, parses bank messages, saves new transactions.
  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<int> scanInbox() async {
    if (!_isAndroid) return 0;

    final granted = await _telephony.requestPhoneAndSmsPermissions ?? false;
    if (!granted) return 0;

    final cutoff = DateTime.now().subtract(const Duration(days: 180));
    final cutoffMs = cutoff.millisecondsSinceEpoch;

    List<SmsMessage> messages = [];
    try {
      messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.DATE).greaterThanOrEqualTo(cutoffMs.toString()),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );
    } catch (e) {
      debugPrint('[SmsScannerService] getInboxSms error: $e');
      return 0;
    }

    final box = HiveService.transactions;
    int added = 0;

    for (final sms in messages) {
      final body = sms.body;
      if (body == null || body.isEmpty) continue;

      final dateMs = int.tryParse(sms.date?.toString() ?? '');
      final receivedAt = dateMs != null
          ? DateTime.fromMillisecondsSinceEpoch(dateMs)
          : DateTime.now();

      final parsed = SmsParser.parse(body, receivedAt);
      if (parsed == null) continue;

      // Deduplicate by raw SMS hash
      final alreadyExists = box.values.any(
        (t) => t.rawSmsHash == parsed.rawSmsHash,
      );
      if (alreadyExists) continue;

      final tx = SmsParser.toTransaction(parsed);
      await box.add(tx);
      added++;
    }

    debugPrint('[SmsScannerService] Scanned ${messages.length} SMS, added $added new transactions');
    return added;
  }

  /// Listen for new incoming SMS in real-time.
  /// Must only be called AFTER runtime SMS permissions are granted.
  static Future<void> startListening() async {
    if (!_isAndroid) return;
    try {
      final granted = await _telephony.requestPhoneAndSmsPermissions ?? false;
      if (!granted) return;
      _telephony.listenIncomingSms(
        onNewMessage: _onNewSms,
        onBackgroundMessage: _onBackgroundSms,
        listenInBackground: false, // avoid background isolate crash on older devices
      );
    } catch (e) {
      debugPrint('[SmsScannerService] startListening error: $e');
    }
  }

  static Future<void> _onNewSms(SmsMessage message) async {
    final body = message.body;
    if (body == null) return;
    final parsed = SmsParser.parse(body, DateTime.now());
    if (parsed == null) return;
    final tx = SmsParser.toTransaction(parsed);
    await HiveService.transactions.add(tx);
    debugPrint('[SmsScannerService] New transaction: ${tx.merchant} ₹${tx.amount}');
  }
}

// Top-level background handler (required by telephony package)
@pragma('vm:entry-point')
Future<void> _onBackgroundSms(SmsMessage message) async {
  final body = message.body;
  if (body == null) return;
  final parsed = SmsParser.parse(body, DateTime.now());
  if (parsed == null) return;
  // In background we can't access Hive without re-initialising
  // The foreground service handles persistence; this just logs
  debugPrint('[BG] New bank SMS: ${parsed.merchant} ₹${parsed.amount}');
}
