import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central access to environment configuration with graceful fallbacks.
///
/// The app runs in three modes depending on what's configured:
///   • **Demo**     — no backend keys; fully local enterprise auth, OTPs shown
///                    in-app, MFA via local TOTP. Everything testable offline.
///   • **Supabase** — real SUPABASE_URL + SUPABASE_ANON_KEY present; auth goes
///                    through Supabase GoTrue (signup, login, OTP email, MFA).
///   • **Email**    — RESEND_API_KEY present; OTP / reset emails actually send.
class EnvConfig {
  // ── Supabase ───────────────────────────────────────────────────────────────
  static String get supabaseUrl => _clean(dotenv.maybeGet('SUPABASE_URL'));
  static String get supabaseAnonKey =>
      _clean(dotenv.maybeGet('SUPABASE_ANON_KEY'));

  /// True only when a real (non-placeholder) Supabase project is configured.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('placeholder') &&
      !supabaseAnonKey.contains('placeholder');

  // ── Resend (transactional email) ─────────────────────────────────────────────
  static String get resendApiKey => _clean(dotenv.maybeGet('RESEND_API_KEY'));
  static String get emailFrom =>
      _clean(dotenv.maybeGet('EMAIL_FROM')).isEmpty
          ? 'SpendLens <onboarding@resend.dev>'
          : _clean(dotenv.maybeGet('EMAIL_FROM'));

  /// True when transactional email can actually be sent.
  static bool get hasEmail => resendApiKey.isNotEmpty;

  // ── Sentry (optional error tracking) ─────────────────────────────────────────
  static String get sentryDsn => _clean(dotenv.maybeGet('SENTRY_DSN'));

  // ── Helpers ──────────────────────────────────────────────────────────────────
  static String _clean(String? v) => (v ?? '').trim();
}
