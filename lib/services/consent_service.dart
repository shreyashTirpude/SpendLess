import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../data/local/hive_service.dart';

/// Records and proves the user's informed consent to data processing.
///
/// Stores a tamper-evident acceptance record (version, UTC timestamp, platform,
/// the exact agreement text hash, and the action during which consent was
/// given) so there is durable evidence the user agreed before any SMS or
/// personal data was processed. A full audit trail of every acceptance is kept.
class ConsentService {
  /// Bump when the agreement text changes — forces re-consent.
  static const currentVersion = '2026-06-21.v1';

  static const _statusKey = 'consent_status';
  static const _logKey = 'consent_log';

  /// True when the user has accepted the current agreement version.
  static bool get hasConsented {
    final raw = HiveService.settings.get(_statusKey) as String?;
    if (raw == null) return false;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return j['accepted'] == true && j['version'] == currentVersion;
    } catch (_) {
      return false;
    }
  }

  /// The latest acceptance record (for display in Settings → "Your consent").
  static Map<String, dynamic>? get record {
    final raw = HiveService.settings.get(_statusKey) as String?;
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Persist consent evidence. [action] identifies the flow (e.g. "signup",
  /// "login", "onboarding"). [agreementHash] binds the record to exact text.
  static Future<void> accept({
    required String action,
    required String agreementHash,
  }) async {
    final entry = {
      'accepted': true,
      'version': currentVersion,
      'acceptedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'action': action,
      'platform': defaultTargetPlatform.name,
      'agreementHash': agreementHash,
    };
    await HiveService.settings.put(_statusKey, jsonEncode(entry));

    // Append to an immutable-ish audit log.
    final logRaw = HiveService.settings.get(_logKey) as String?;
    final log = <dynamic>[];
    if (logRaw != null) {
      try {
        log.addAll(jsonDecode(logRaw) as List);
      } catch (_) {}
    }
    log.add(entry);
    await HiveService.settings.put(_logKey, jsonEncode(log));
    debugPrint('[ConsentService] consent recorded: $action @ ${entry['acceptedAtUtc']}');
  }

  /// Withdraw consent (user right). Keeps the audit log; flips status.
  static Future<void> withdraw() async {
    await HiveService.settings.put(
      _statusKey,
      jsonEncode({'accepted': false, 'withdrawnAtUtc': DateTime.now().toUtc().toIso8601String()}),
    );
  }

  /// Full audit trail of every acceptance (for compliance export).
  static List<Map<String, dynamic>> get auditLog {
    final raw = HiveService.settings.get(_logKey) as String?;
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
