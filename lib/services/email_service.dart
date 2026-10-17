import 'package:flutter/foundation.dart';

/// Result of an email send — carries whether it actually went out over the wire
/// or fell back to demo mode (where the OTP is surfaced in-app instead).
///
/// SECURITY: the client never holds an email-provider API key and never talks
/// to a mail provider directly. Provider secrets must live in a trusted backend.
class EmailResult {
  final bool sent;
  final bool demoFallback;
  final String? error;
  const EmailResult({required this.sent, this.demoFallback = false, this.error});
}

/// Transactional email is intentionally NOT sent from the client (no provider
/// keys are bundled). Every send therefore reports failure without claiming
/// success. In debug builds [EmailResult.demoFallback] is set so local flows can
/// surface the OTP themselves; release builds never expose the code.
///
/// Apps with a configured backend (Supabase) use that provider's own email flow
/// for password recovery instead of this service.
class EmailService {
  static const _unavailableError =
      'Email delivery is unavailable in the client build';

  /// Send a 6-digit OTP for password reset / login verification.
  static Future<EmailResult> sendOtp({
    required String to,
    required String code,
    required String purpose, // e.g. "reset your password"
  }) async {
    // The OTP itself is never logged.
    _logSkip('OTP ($purpose)', to);
    return _result();
  }

  /// Send a welcome email after successful signup.
  static Future<EmailResult> sendWelcome({
    required String to,
    required String name,
  }) async {
    _logSkip('Welcome, $name', to);
    return _result();
  }

  /// Notify a Pro member their membership is about to expire.
  static Future<EmailResult> sendExpiryReminder({
    required String to,
    required String name,
    required int daysLeft,
  }) async {
    _logSkip('Pro expiry reminder for $name ($daysLeft days left)', to);
    return _result();
  }

  // ── Core result ────────────────────────────────────────────────────────────

  /// Always a non-sent result: no network request is made and no key is used.
  /// Debug builds advertise the demo fallback so a local OTP can be shown;
  /// release builds never surface the code (demoFallback stays false).
  static EmailResult _result() =>
      const EmailResult(sent: false, demoFallback: !kReleaseMode, error: _unavailableError);

  static void _logSkip(String subject, String to) {
    // Release builds silence debugPrint (see main); never log the OTP body.
    debugPrint('[EmailService] not sent (no client email transport): "$subject" → $to');
  }
}
