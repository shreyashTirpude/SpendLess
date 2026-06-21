import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/env_config.dart';

/// Result of an email send — carries whether it actually went out over the wire
/// or fell back to demo mode (where the OTP is surfaced in-app instead).
class EmailResult {
  final bool sent;
  final bool demoFallback;
  final String? error;
  const EmailResult({required this.sent, this.demoFallback = false, this.error});
}

/// Transactional email via Resend. When no RESEND_API_KEY is configured the
/// service degrades gracefully: it logs the message and returns [demoFallback]
/// so the UI can show the OTP directly (keeps the whole flow testable offline).
class EmailService {
  static const _endpoint = 'https://api.resend.com/emails';

  /// Send a 6-digit OTP for password reset / login verification.
  static Future<EmailResult> sendOtp({
    required String to,
    required String code,
    required String purpose, // e.g. "reset your password"
  }) {
    final html = _otpTemplate(code: code, purpose: purpose);
    return _send(
      to: to,
      subject: 'Your SpendLens verification code: $code',
      html: html,
    );
  }

  /// Send a welcome email after successful signup.
  static Future<EmailResult> sendWelcome({
    required String to,
    required String name,
  }) {
    final html = _welcomeTemplate(name: name);
    return _send(to: to, subject: 'Welcome to SpendLens 💸', html: html);
  }

  /// Notify a Pro member their membership is about to expire.
  static Future<EmailResult> sendExpiryReminder({
    required String to,
    required String name,
    required int daysLeft,
  }) {
    final html = _expiryTemplate(name: name, daysLeft: daysLeft);
    return _send(
      to: to,
      subject: 'Your SpendLens Pro expires in $daysLeft days',
      html: html,
    );
  }

  // ── Core sender ────────────────────────────────────────────────────────────

  static Future<EmailResult> _send({
    required String to,
    required String subject,
    required String html,
  }) async {
    if (!EnvConfig.hasEmail) {
      debugPrint('[EmailService] DEMO (no RESEND_API_KEY): "$subject" → $to');
      return const EmailResult(sent: false, demoFallback: true);
    }
    try {
      final resp = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer ${EnvConfig.resendApiKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'from': EnvConfig.emailFrom,
              'to': [to],
              'subject': subject,
              'html': html,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return const EmailResult(sent: true);
      }
      debugPrint('[EmailService] Resend ${resp.statusCode}: ${resp.body}');
      return EmailResult(sent: false, error: 'Email failed (${resp.statusCode})');
    } catch (e) {
      debugPrint('[EmailService] send error: $e');
      return EmailResult(sent: false, error: e.toString());
    }
  }

  // ── HTML templates ───────────────────────────────────────────────────────────

  static String _shell(String body) => '''
<!DOCTYPE html><html><body style="margin:0;padding:0;background:#0B0B12;font-family:-apple-system,Segoe UI,Roboto,sans-serif;">
  <div style="max-width:480px;margin:0 auto;padding:40px 24px;">
    <div style="text-align:center;margin-bottom:32px;">
      <span style="font-size:40px;">💸</span>
      <h1 style="color:#fff;font-size:22px;margin:8px 0 0;">SpendLens</h1>
    </div>
    <div style="background:#16161F;border:1px solid #26263A;border-radius:16px;padding:28px;">
      $body
    </div>
    <p style="color:#6B6B80;font-size:11px;text-align:center;margin-top:24px;line-height:1.6;">
      Your data stays on your device · End-to-end encrypted<br/>
      If you didn't request this, you can safely ignore this email.
    </p>
  </div>
</body></html>''';

  static String _otpTemplate({required String code, required String purpose}) =>
      _shell('''
    <h2 style="color:#fff;font-size:18px;margin:0 0 8px;">Verification code</h2>
    <p style="color:#A0A0B8;font-size:14px;line-height:1.6;margin:0 0 24px;">
      Use this code to $purpose. It expires in 10 minutes.
    </p>
    <div style="background:linear-gradient(135deg,#7C3AED,#6366F1);border-radius:12px;padding:20px;text-align:center;">
      <span style="color:#fff;font-size:34px;font-weight:800;letter-spacing:10px;">$code</span>
    </div>
    <p style="color:#6B6B80;font-size:12px;margin:20px 0 0;">
      Never share this code. SpendLens staff will never ask for it.
    </p>''');

  static String _welcomeTemplate({required String name}) => _shell('''
    <h2 style="color:#fff;font-size:18px;margin:0 0 8px;">Welcome, $name 👋</h2>
    <p style="color:#A0A0B8;font-size:14px;line-height:1.7;margin:0;">
      Your account is ready. SpendLens automatically tracks your spending from
      bank SMS — no manual entry. Set a budget, enable Face ID, and let the
      insights roll in.
    </p>''');

  static String _expiryTemplate({required String name, required int daysLeft}) =>
      _shell('''
    <h2 style="color:#fff;font-size:18px;margin:0 0 8px;">Your Pro plan is ending</h2>
    <p style="color:#A0A0B8;font-size:14px;line-height:1.7;margin:0 0 16px;">
      Hi $name, your SpendLens Pro membership expires in
      <strong style="color:#fff;">$daysLeft days</strong>. Renew now to keep the
      AI chatbot, micro-savings, and festival planner.
    </p>''');
}
