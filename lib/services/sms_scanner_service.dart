import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:spendlens/domain/models/transaction.dart';
import 'package:telephony/telephony.dart';
import '../core/utils/sms_parser.dart';
import '../data/local/hive_service.dart';
import 'notification_service.dart';

class SmsScannerService {
  static final _telephony = Telephony.instance;

  /// Call once on first launch (or from settings "Re-scan SMS").
  /// Reads the last 6 months of SMS, parses bank messages, saves new transactions.
  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Normalized sender (address) for a message, or null when absent/blank.
  /// A null result means the adapter must drop the message rather than parse it
  /// unverified — this preserves the bank-allowlist guarantee.
  static String? _senderOrNull(SmsMessage message) {
    final address = message.address?.trim();
    if (address == null || address.isEmpty) return null;
    return address;
  }

  /// Message timestamp when present, otherwise "now".
  static DateTime _receivedAt(SmsMessage message) {
    final ms = message.date;
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : DateTime.now();
  }

  /// True while a full inbox scan runs; overlapping scan requests are dropped
  /// instead of racing each other's dedup snapshot.
  static bool _scanInFlight = false;

  /// True once this process has repaired legacy duplicate rows.
  static bool _dedupedOnce = false;

  /// One-time repair for installs that stored duplicates before ingest became
  /// idempotent (uuid v4 ids + unguarded concurrent scans kept the same bank
  /// SMS under 3-4 different rows — the duplicate-payments bug). Collapses
  /// rows that share a raw-SMS hash, keeping the earliest-created one.
  /// Idempotent; rows without a hash are never touched.
  static Future<void> removeDuplicateRows() async {
    if (_dedupedOnce) return;
    _dedupedOnce = true;

    final box = HiveService.transactions;
    final byHash = <String, List<String>>{};
    for (final t in box.values) {
      final h = t.rawSmsHash;
      if (h == null) continue;
      byHash.putIfAbsent(h, () => []).add(t.id);
    }

    final staleIds = <String>[];
    for (final ids in byHash.values) {
      if (ids.length < 2) continue;
      final rows = ids.map((id) => box.get(id)!).toList()
        ..sort((a, b) {
          final byCreated = a.createdAt.compareTo(b.createdAt);
          return byCreated != 0 ? byCreated : a.id.compareTo(b.id);
        });
      staleIds.addAll(rows.skip(1).map((t) => t.id));
    }

    if (staleIds.isEmpty) return;
    await box.deleteAll(staleIds);
    debugPrint(
        '[SmsScannerService] Removed ${staleIds.length} duplicate rows from pre-fix installs');
  }

  static Future<int> scanInbox() async {
    if (!_isAndroid) return 0;

    // Single-flight: startup, app-resume and the 15-minute timer can all ask
    // for a scan while one is already running. Each concurrent scan snapshots
    // the dedup hash set before the others write, so the same bank SMS was
    // stored 3-4 times under different ids (the duplicate-payments bug). The
    // in-flight scan already covers every message up to its snapshot and the
    // live listener covers newer ones, so a second scan adds no coverage.
    if (_scanInFlight) return 0;
    _scanInFlight = true;
    try {
      // Repair any pre-fix duplicate rows first, so the dedup snapshot below
      // (and everything the user sees) starts from a clean state.
      await removeDuplicateRows();

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

      // SmsParser owns parsing; the scanner only orchestrates + persists.
      final parsedMessages = SmsParser.parseMessages(messages).parsedMessages;
      final box = HiveService.transactions;

      final ingestedCount = await _ingestToHive(parsedMessages, box);

      debugPrint('[SmsScannerService] Scanned ${messages.length} SMS, added $ingestedCount new transactions');
      return ingestedCount;
    } finally {
      _scanInFlight = false;
    }
  }

  static Future<int> _ingestToHive(
      List<ParsedSms> messages,
      Box<Transaction> hiveBox,
      ) async {
    // Build the set of existing hashes once (O(n+m) dedup instead of O(n*m)).
    final existingHashes =
        hiveBox.values.map((t) => t.rawSmsHash).whereType<String>().toSet();
    int addedToHive = 0;

    for (final message in messages) {
      if (existingHashes.contains(message.rawSmsHash)) continue;

      final tx = SmsParser.toTransaction(message);
      await hiveBox.put(tx.id, tx);
      existingHashes.add(message.rawSmsHash);
      addedToHive++;
    }

    return addedToHive;
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
        // listenInBackground:false requires onBackgroundMessage:null; passing a
        // callback makes the plugin assert and the foreground listener never
        // registers in debug.
        listenInBackground: false, // avoid background isolate crash on older devices
      );
    } catch (e) {
      debugPrint('[SmsScannerService] startListening error: $e');
    }
  }

  static Future<void> _onNewSms(SmsMessage message) async {
    final body = message.body;
    if (body == null) return;
    // SMS adapters must supply the real sender so the bank-allowlist check runs;
    // a missing address must never silently bypass it.
    final address = _senderOrNull(message);
    if (address == null) {
      debugPrint('[SmsScannerService] Dropped SMS with no sender address');
      return;
    }
    final parsed = SmsParser.parseSingle(
      body,
      _receivedAt(message),
      senderAddress: address,
    );
    if (parsed == null) return;

    // Deduplicate by raw SMS hash — same check as scanInbox() to prevent
    // double entries when a bank SMS arrives while a rescan is in progress.
    final alreadyExists = HiveService.transactions.values.any(
      (t) => t.rawSmsHash == parsed.rawSmsHash,
    );
    if (alreadyExists) return;

    final tx = SmsParser.toTransaction(parsed);

    await HiveService.transactions.put(tx.id, tx);
    debugPrint('[SmsScannerService] New transaction: ${tx.merchant} ₹${tx.amount}');

    // Notify on the new transaction (respects the "Transaction alerts" toggle).
    if (HiveService.settings.get('transactionAlerts', defaultValue: true) as bool) {
      final notif = NotificationService();
      await notif.initialize();
      final sign = tx.isCredit ? '+' : '-';
      await notif.showTransactionNotif(
        title: '${tx.isCredit ? "💰 Received" : "💸 Spent"} $sign₹${tx.amount.toStringAsFixed(0)}',
        body: '${tx.merchant} · ${tx.category}',
      );
    }

    await _checkDailyBudget();
  }

  static Future<void> _checkDailyBudget() async {
    try {
      final settings = HiveService.settings;

      // Respect the user's "Budget alerts" toggle.
      if (!(settings.get('budgetAlerts', defaultValue: true) as bool)) return;
      final now = DateTime.now();
      final isWeekend =
          now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
      final limit = isWeekend
          ? (settings.get('weekendDailyBudget', defaultValue: 0.0) as num).toDouble()
          : (settings.get('weekdayDailyBudget', defaultValue: 0.0) as num).toDouble();
      if (limit <= 0) return;

      final today = DateTime(now.year, now.month, now.day);
      final todaySpend = HiveService.transactions.values
          .where((t) =>
              !t.isCredit &&
              !t.isIgnored &&
              t.transactionDate.year == today.year &&
              t.transactionDate.month == today.month &&
              t.transactionDate.day == today.day)
          .fold(0.0, (sum, t) => sum + t.amount);

      if (todaySpend > limit) {
        final notif = NotificationService();
        await notif.initialize();
        await notif.showDailyBudgetAlert(
          isWeekend: isWeekend,
          spent: todaySpend,
          limit: limit,
        );
      }
    } catch (e) {
      debugPrint('[SmsScannerService] _checkDailyBudget error: $e');
    }
  }
}
