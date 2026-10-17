/// Central access to environment configuration, compiled in from public values.
///
/// The app runs in two modes depending on what's configured at build time:
///   • **Demo**     — no backend keys; fully local enterprise auth, MFA via
///                    local TOTP. Local demo OTPs are debug-only: in debug
///                    builds they're surfaced in-app for testing, but in
///                    release builds local password recovery is unavailable
///                    (it fails with a network error rather than showing a
///                    code). Everything is testable offline in debug.
///   • **Supabase** — real SUPABASE_URL + SUPABASE_ANON_KEY present; auth goes
///                    through Supabase GoTrue (signup, login, MFA), and password
///                    recovery is handled by Supabase's email flow.
///
/// Only PUBLIC values are read — via `--dart-define` / `const String.fromEnvironment`.
/// Provider secrets (API keys for transactional email, etc.) are never bundled
/// into the client; sending mail is the job of a trusted backend, not the app.
class EnvConfig {
  // ── Supabase (public project URL + anon key) ─────────────────────────────────
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  /// True only when a real Supabase project is configured.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('placeholder') &&
      !supabaseAnonKey.contains('placeholder');

  // ── Email / password recovery ────────────────────────────────────────────────
  /// True when email-backed auth (password recovery, verification) is available.
  /// The client no longer talks to any email provider directly — recovery email
  /// is delivered by Supabase when a project is configured.
  static bool get hasEmail => hasSupabase;

  // ── Sentry (optional error tracking) ─────────────────────────────────────────
  static const String sentryDsn =
      String.fromEnvironment('SENTRY_DSN', defaultValue: '');
}
