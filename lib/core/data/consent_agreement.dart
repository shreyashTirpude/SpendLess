import 'dart:convert';
import 'package:crypto/crypto.dart';

/// The full data-processing & privacy agreement shown to the user. Plain,
/// specific language (not legalese) so consent is genuinely informed. The
/// [hash] binds a stored acceptance record to this exact text as evidence.
class ConsentAgreement {
  static const String text = '''
SpendLens — Data Processing & Privacy Agreement

Last updated: 21 June 2026

By continuing, you ("you", "the user") give SpendLens ("we", "the app") your
informed, explicit consent to process your data strictly as described below.

1. WHAT WE READ
   • Bank & payment SMS messages on this device, to automatically detect and
     categorise your transactions (amount, merchant, date, account last-4).
   • Optionally, your device contacts — only to label money transfers as
     "Friends" or "Family". Contact names/numbers never leave your device.
   • The profile details you choose to enter (name, email).

2. WHY WE READ IT
   • Solely to power the app's features: spend tracking, budgets, insights,
     subscription detection, and reminders. Nothing else.
   • We do NOT read OTPs, personal/promotional messages, or non-financial SMS.
     Such messages are filtered out and never stored.

3. WHERE YOUR DATA LIVES
   • All transaction and personal data is stored LOCALLY on your device in an
     AES-256 encrypted database. It does not leave your device unless you
     explicitly enable cloud sync.
   • We do NOT sell, rent, or share your data with advertisers or data brokers.

4. CLOUD & THIRD PARTIES (only if you enable them)
   • Authentication & optional sync: Supabase (EU/US region).
   • Transactional email (verification, password reset): Resend.
   • These process only the minimum needed (e.g. your email for a reset code).

5. YOUR RIGHTS
   • Access, export, or delete your data at any time from Settings.
   • Withdraw this consent at any time — after which SMS reading stops.
   • Withdrawal does not affect processing already performed lawfully.

6. SECURITY
   • Local encryption (AES-256), PBKDF2-hashed passwords, optional 2FA and
     biometric app-lock. We never store your password in plain text.

7. EVIDENCE OF CONSENT
   • When you accept, we store the agreement version, a UTC timestamp, your
     platform, and a hash of this exact text — as a record that you consented
     before any data was processed.

8. CHILDREN
   • SpendLens is not intended for users under 18.

By tapping "I Agree", you confirm you have read and accept this agreement and
consent to the processing described above.
''';

  /// SHA-256 of the agreement text — stored with each acceptance as evidence.
  static String get hash =>
      sha256.convert(utf8.encode(text)).toString();

  /// Short summary for the inline checkbox label.
  static const String shortNotice =
      'I agree to the Data Processing & Privacy Agreement, including reading '
      'bank SMS on this device to track my spending. My data stays encrypted '
      'on my device.';
}
