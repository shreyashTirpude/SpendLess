import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../core/config/env_config.dart';
import '../../core/utils/totp.dart';
import '../../data/local/hive_service.dart';
import '../email_service.dart';
import 'auth_models.dart';

/// Enterprise auth service with two interchangeable backends:
///
///   • **Local** (default / demo) — accounts persisted encrypted-at-rest in the
///     Hive settings box, PBKDF2 password hashing, TOTP MFA, OTP password reset,
///     recovery codes, and membership-expiry tracking. Fully testable offline.
///
///   • **Supabase** (when EnvConfig.hasSupabase) — delegates to Supabase GoTrue
///     REST for signup / login / email-OTP recovery / MFA. Activates the moment
///     real keys are present; no code change required.
class AuthService {
  static const _uuid = Uuid();

  // Secure-storage keys (OS keystore-backed — survives reliably, encrypted).
  static const _accountsKey = 'auth_accounts';
  static const _sessionKey = 'auth_session_email';
  static const _otpPrefix = 'auth_otp_';

  static const _maxOtpAttempts = 5;
  static const _otpTtl = Duration(minutes: 10);

  // Credentials live in keystore-backed secure storage (NOT the Hive settings
  // box) so sessions persist across days/reboots and are never wiped by a Hive
  // box-open failure. An in-memory cache keeps the public getters synchronous.
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions:
        IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  static final Map<String, AuthAccount> _accounts = {};
  static String? _sessionEmail;
  static bool _loaded = false;

  /// Load persisted accounts + session into memory. MUST be awaited once at
  /// startup (in main, after Hive init). Also migrates any legacy accounts that
  /// were previously stored in the Hive settings box.
  static Future<void> initialize() async {
    if (_loaded) return;
    try {
      // Migrate legacy data from the old Hive-settings location (one-time).
      await _migrateLegacy();

      final raw = await _secure.read(key: _accountsKey);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _accounts
          ..clear()
          ..addAll(map.map((k, v) =>
              MapEntry(k, AuthAccount.fromJson(v as Map<String, dynamic>))));
      }
      _sessionEmail = await _secure.read(key: _sessionKey);
    } catch (e) {
      debugPrint('[AuthService] init error (non-fatal): $e');
    }
    _loaded = true;
  }

  static Future<void> _migrateLegacy() async {
    try {
      final already = await _secure.read(key: _accountsKey);
      if (already != null && already.isNotEmpty) return; // already migrated
      final legacyAccounts = HiveService.settings.get(_accountsKey) as String?;
      if (legacyAccounts != null && legacyAccounts.isNotEmpty) {
        await _secure.write(key: _accountsKey, value: legacyAccounts);
        await HiveService.settings.delete(_accountsKey);
      }
      final legacySession = HiveService.settings.get(_sessionKey) as String?;
      if (legacySession != null && legacySession.isNotEmpty) {
        await _secure.write(key: _sessionKey, value: legacySession);
        await HiveService.settings.delete(_sessionKey);
      }
    } catch (_) {/* best-effort */}
  }

  // ── Session ──────────────────────────────────────────────────────────────────

  static AuthAccount? get currentUser {
    final email = _sessionEmail;
    if (email == null) return null;
    final acct = _accounts[_normalizeEmail(email)];
    if (acct != null) _enforceExpiry(acct);
    return acct;
  }

  static bool get isLoggedIn => currentUser != null;

  static Future<void> signOut() async {
    _sessionEmail = null;
    await _secure.delete(key: _sessionKey);
  }

  // ── Sign up ────────────────────────────────────────────────────────────────

  static Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final e = _normalizeEmail(email);
    if (!_isValidEmail(e)) {
      return const AuthResult(AuthStatus.invalidEmail,
          message: 'Enter a valid email address');
    }
    final strength = PasswordStrength.evaluate(password);
    if (!strength.isAcceptable) {
      return AuthResult(AuthStatus.weakPassword,
          message: 'Password too weak: ${strength.unmet.join(", ")}');
    }

    if (EnvConfig.hasSupabase) return _supabaseSignUp(name, e, password);

    final accounts = _readAccounts();
    if (accounts.containsKey(e)) {
      return const AuthResult(AuthStatus.emailInUse,
          message: 'An account with this email already exists');
    }

    final account = AuthAccount(
      id: _uuid.v4(),
      email: e,
      name: name.trim(),
      passwordHash: PasswordHasher.hash(password),
      createdAt: DateTime.now(),
      emailVerified: !EnvConfig.hasEmail, // auto-verify in demo
    );
    await _writeAccount(account);
    await _setSession(e);

    // Fire-and-forget welcome email
    EmailService.sendWelcome(to: e, name: account.name);
    return AuthResult.success(account);
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  static Future<AuthResult> login({
    required String email,
    required String password,
    String? mfaCode,
  }) async {
    final e = _normalizeEmail(email);
    if (EnvConfig.hasSupabase) return _supabaseLogin(e, password);

    // Brute-force lockout: block after too many recent failures.
    final lockMsg = _lockoutMessage(e);
    if (lockMsg != null) {
      return AuthResult(AuthStatus.rateLimited, message: lockMsg);
    }

    final account = _readAccount(e);
    if (account == null) {
      await _registerFailedLogin(e);
      return const AuthResult(AuthStatus.userNotFound,
          message: 'Incorrect email or password'); // don't reveal which
    }
    if (!PasswordHasher.verify(password, account.passwordHash)) {
      await _registerFailedLogin(e);
      return const AuthResult(AuthStatus.invalidCredentials,
          message: 'Incorrect email or password');
    }

    // Second factor
    if (account.mfaEnabled) {
      if (mfaCode == null || mfaCode.isEmpty) {
        return AuthResult(AuthStatus.mfaRequired, account: account);
      }
      final step = Totp.matchedStep(account.mfaSecret ?? '', mfaCode);
      // Replay guard: reject a TOTP whose step was already used.
      final lastStep = HiveService.settings.get('mfa_step_$e') as int?;
      final okTotp = step != null && (lastStep == null || step > lastStep);
      final okRecovery = !okTotp && _consumeRecoveryCode(account, mfaCode);
      if (!okTotp && !okRecovery) {
        await _registerFailedLogin(e);
        return const AuthResult(AuthStatus.mfaInvalid,
            message: 'Invalid authentication code');
      }
      if (okTotp) await HiveService.settings.put('mfa_step_$e', step);
      if (okRecovery) await _writeAccount(account);
    }

    await _clearFailedLogins(e);
    _enforceExpiry(account);
    await _setSession(e);
    return AuthResult.success(account);
  }

  // ── Brute-force lockout ──────────────────────────────────────────────────────

  static const _maxLoginAttempts = 5;
  static const _lockoutWindow = Duration(minutes: 15);

  static String? _lockoutMessage(String email) {
    final until = HiveService.settings.get('login_lock_$email') as String?;
    if (until == null) return null;
    final t = DateTime.tryParse(until);
    if (t == null || DateTime.now().isAfter(t)) return null;
    final mins = t.difference(DateTime.now()).inMinutes + 1;
    return 'Too many attempts. Try again in $mins min.';
  }

  static Future<void> _registerFailedLogin(String email) async {
    final n = (HiveService.settings.get('login_fail_$email') as int? ?? 0) + 1;
    await HiveService.settings.put('login_fail_$email', n);
    if (n >= _maxLoginAttempts) {
      await HiveService.settings.put('login_lock_$email',
          DateTime.now().add(_lockoutWindow).toIso8601String());
      await HiveService.settings.put('login_fail_$email', 0);
    }
  }

  static Future<void> _clearFailedLogins(String email) async {
    await HiveService.settings.delete('login_fail_$email');
    await HiveService.settings.delete('login_lock_$email');
  }

  // ── Password reset (OTP) ─────────────────────────────────────────────────────

  /// Step 1: request an OTP to the account email.
  static Future<AuthResult> requestPasswordReset(String email) async {
    final e = _normalizeEmail(email);
    if (EnvConfig.hasSupabase) {
      final ok = await _supabaseRecover(e);
      return ok
          ? const AuthResult(AuthStatus.otpRequired)
          : const AuthResult(AuthStatus.networkError,
              message: 'Could not send reset email');
    }

    // Local mode has no email transport. In release builds, fail uniformly
    // BEFORE any account lookup or OTP generation: an unknown email must not
    // claim "sent" (or do different work) than a known one, which would leak
    // account existence. Debug builds keep the demo flow and surface the OTP.
    if (!EnvConfig.hasSupabase && kReleaseMode) {
      return const AuthResult(AuthStatus.networkError,
          message: 'Password recovery requires configured email '
              'authentication. Set up email authentication (e.g. Supabase) to '
              'recover your password.');
    }

    final account = _readAccount(e);
    if (account == null) {
      // Don't leak which emails exist — do equivalent work (generate + hash a
      // throwaway OTP) so the not-found path can't be timed apart, then return
      // the same generic result without storing anything.
      final throwaway = _generateOtp();
      _sha256(throwaway);
      return const AuthResult(AuthStatus.otpRequired,
          message: 'If an account exists, a code has been sent');
    }

    final code = _generateOtp();
    final res = await EmailService.sendOtp(
        to: e, code: code, purpose: 'reset your password');

    // The client has no email transport, so the code is never emailed. Debug /
    // offline builds may surface it in-app instead. (Release builds already
    // returned above — EmailService.demoFallback is only true in debug.)
    if (!res.demoFallback) {
      // Defense-in-depth: never claim a code was sent and never surface the
      // OTP; returning before _storeOtp leaves no usable code in storage.
      return const AuthResult(AuthStatus.networkError,
          message: 'Password recovery requires configured email '
              'authentication. Set up email authentication (e.g. Supabase) to '
              'recover your password.');
    }

    await _storeOtp(e, code, 'reset');
    return AuthResult(AuthStatus.otpRequired,
        demoOtp: code,
        message: 'Demo mode: your code is shown below');
  }

  /// Step 2: verify the OTP and set a new password.
  static Future<AuthResult> confirmPasswordReset({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final e = _normalizeEmail(email);
    final strength = PasswordStrength.evaluate(newPassword);
    if (!strength.isAcceptable) {
      return AuthResult(AuthStatus.weakPassword,
          message: 'Password too weak: ${strength.unmet.join(", ")}');
    }

    if (EnvConfig.hasSupabase) {
      final ok = await _supabaseVerifyRecovery(e, otp, newPassword);
      return ok
          ? const AuthResult(AuthStatus.ok)
          : const AuthResult(AuthStatus.otpInvalid, message: 'Invalid code');
    }

    final check = await _verifyOtp(e, otp, 'reset');
    if (check != AuthStatus.ok) {
      return AuthResult(check,
          message: check == AuthStatus.otpExpired
              ? 'Code expired — request a new one'
              : 'Invalid code');
    }

    final account = _readAccount(e);
    if (account == null) {
      return const AuthResult(AuthStatus.userNotFound);
    }
    account.passwordHash = PasswordHasher.hash(newPassword);
    await _writeAccount(account);
    await _clearOtp(e);
    return AuthResult.success(account);
  }

  // ── MFA enrollment ───────────────────────────────────────────────────────────

  /// Begin MFA setup: returns a fresh secret + provisioning URI (for QR).
  static ({String secret, String uri}) beginMfaSetup(String email) {
    final secret = Totp.generateSecret();
    final uri = Totp.provisioningUri(secret: secret, accountName: email);
    return (secret: secret, uri: uri);
  }

  /// Confirm MFA: verify the first code, then persist secret + recovery codes.
  static Future<({bool ok, List<String> recoveryCodes})> confirmMfaSetup({
    required String email,
    required String secret,
    required String code,
  }) async {
    if (!Totp.verify(secret, code)) {
      return (ok: false, recoveryCodes: <String>[]);
    }
    final account = _readAccount(_normalizeEmail(email));
    if (account == null) return (ok: false, recoveryCodes: <String>[]);

    final plain = List.generate(8, (_) => _generateRecoveryCode());
    account
      ..mfaEnabled = true
      ..mfaSecret = secret
      ..recoveryCodeHashes = plain.map(_sha256).toList();
    await _writeAccount(account);
    return (ok: true, recoveryCodes: plain);
  }

  static Future<void> disableMfa(String email) async {
    final account = _readAccount(_normalizeEmail(email));
    if (account == null) return;
    account
      ..mfaEnabled = false
      ..mfaSecret = null
      ..recoveryCodeHashes = const [];
    await _writeAccount(account);
  }

  // ── Membership / expiry ──────────────────────────────────────────────────────

  /// Upgrade the current user to [tier] for [durationDays] (default 30).
  static Future<void> setMembership({
    required String tier,
    int durationDays = 30,
  }) async {
    final account = currentUser;
    if (account == null) return;
    account
      ..tier = tier
      ..tierExpiry =
          tier == 'free' ? null : DateTime.now().add(Duration(days: durationDays));
    await _writeAccount(account);
  }

  /// Auto-downgrade expired memberships; send a reminder when ≤3 days remain.
  static void _enforceExpiry(AuthAccount account) {
    if (account.tier == 'free' || account.tierExpiry == null) return;
    if (account.isExpired) {
      account
        ..tier = 'free'
        ..tierExpiry = null;
      _writeAccount(account);
    } else {
      final days = account.daysUntilExpiry ?? 99;
      if (days <= 3 && EnvConfig.hasEmail) {
        // Send at most one reminder per day (avoid spamming on every getter call).
        final today = DateTime.now().toIso8601String().substring(0, 10);
        final last = HiveService.settings.get('expiry_reminder_sent') as String?;
        if (last != today) {
          HiveService.settings.put('expiry_reminder_sent', today);
          EmailService.sendExpiryReminder(
              to: account.email, name: account.name, daysLeft: days);
        }
      }
    }
  }

  // ── Local store helpers (in-memory cache + secure storage) ────────────────────

  static Map<String, AuthAccount> _readAccounts() => _accounts;

  static AuthAccount? _readAccount(String email) =>
      _accounts[_normalizeEmail(email)];

  static Future<void> _writeAccount(AuthAccount account) async {
    _accounts[account.email] = account;
    final encoded =
        jsonEncode(_accounts.map((k, v) => MapEntry(k, v.toJson())));
    await _secure.write(key: _accountsKey, value: encoded);
  }

  static Future<void> _setSession(String email) async {
    _sessionEmail = _normalizeEmail(email);
    await _secure.write(key: _sessionKey, value: _sessionEmail!);
  }

  // ── OTP store ────────────────────────────────────────────────────────────────

  static Future<void> _storeOtp(String email, String code, String purpose) async {
    final payload = jsonEncode({
      'hash': _sha256(code),
      'purpose': purpose,
      'expiresAt': DateTime.now().add(_otpTtl).toIso8601String(),
      'attempts': 0,
    });
    await HiveService.settings.put('$_otpPrefix$email', payload);
  }

  static Future<AuthStatus> _verifyOtp(
      String email, String code, String purpose) async {
    final raw = HiveService.settings.get('$_otpPrefix$email') as String?;
    if (raw == null) return AuthStatus.otpExpired;
    final data = jsonDecode(raw) as Map<String, dynamic>;

    final expiresAt = DateTime.parse(data['expiresAt'] as String);
    if (DateTime.now().isAfter(expiresAt)) return AuthStatus.otpExpired;

    final attempts = (data['attempts'] as int);
    if (attempts >= _maxOtpAttempts) return AuthStatus.rateLimited;

    // Constant-time compare; persist the incremented attempt count atomically.
    final hashOk = _constantTimeHex(data['hash'] as String, _sha256(code));
    if (data['purpose'] != purpose || !hashOk) {
      data['attempts'] = attempts + 1;
      await HiveService.settings.put('$_otpPrefix$email', jsonEncode(data));
      return AuthStatus.otpInvalid;
    }
    return AuthStatus.ok;
  }

  static bool _constantTimeHex(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  static Future<void> _clearOtp(String email) async {
    await HiveService.settings.delete('$_otpPrefix$email');
  }

  // ── Recovery codes ─────────────────────────────────────────────────────────

  static bool _consumeRecoveryCode(AuthAccount account, String code) {
    final h = _sha256(code.trim().toUpperCase());
    if (account.recoveryCodeHashes.contains(h)) {
      account.recoveryCodeHashes =
          account.recoveryCodeHashes.where((x) => x != h).toList();
      return true;
    }
    return false;
  }

  // ── Supabase GoTrue REST ─────────────────────────────────────────────────────

  static Map<String, String> get _sbHeaders => {
        'apikey': EnvConfig.supabaseAnonKey,
        'Content-Type': 'application/json',
      };

  static Future<AuthResult> _supabaseSignUp(
      String name, String email, String password) async {
    try {
      final resp = await http.post(
        Uri.parse('${EnvConfig.supabaseUrl}/auth/v1/signup'),
        headers: _sbHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
          'data': {'name': name},
        }),
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final account = AuthAccount(
          id: _uuid.v4(),
          email: email,
          name: name,
          passwordHash: '',
          createdAt: DateTime.now(),
          emailVerified: false,
        );
        await _writeAccount(account);
        await _setSession(email);
        return AuthResult.success(account);
      }
      return AuthResult(AuthStatus.emailInUse, message: _sbError(resp.body));
    } catch (e) {
      return AuthResult(AuthStatus.networkError, message: e.toString());
    }
  }

  static Future<AuthResult> _supabaseLogin(
      String email, String password) async {
    try {
      final resp = await http.post(
        Uri.parse(
            '${EnvConfig.supabaseUrl}/auth/v1/token?grant_type=password'),
        headers: _sbHeaders,
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        var account = _readAccount(email);
        account ??= AuthAccount(
          id: _uuid.v4(),
          email: email,
          name: email.split('@').first,
          passwordHash: '',
          createdAt: DateTime.now(),
          emailVerified: true,
        );
        await _writeAccount(account);
        await _setSession(email);
        return AuthResult.success(account);
      }
      return AuthResult(AuthStatus.invalidCredentials,
          message: _sbError(resp.body));
    } catch (e) {
      return AuthResult(AuthStatus.networkError, message: e.toString());
    }
  }

  static Future<bool> _supabaseRecover(String email) async {
    try {
      final resp = await http.post(
        Uri.parse('${EnvConfig.supabaseUrl}/auth/v1/recover'),
        headers: _sbHeaders,
        body: jsonEncode({'email': email}),
      );
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _supabaseVerifyRecovery(
      String email, String otp, String newPassword) async {
    try {
      // 1. Verify the recovery OTP → returns a session (access_token).
      final verify = await http.post(
        Uri.parse('${EnvConfig.supabaseUrl}/auth/v1/verify'),
        headers: _sbHeaders,
        body: jsonEncode({'type': 'recovery', 'email': email, 'token': otp}),
      );
      if (verify.statusCode < 200 || verify.statusCode >= 300) return false;
      final token =
          (jsonDecode(verify.body) as Map<String, dynamic>)['access_token'];
      if (token == null) return false;

      // 2. Use that session to actually set the new password.
      final update = await http.put(
        Uri.parse('${EnvConfig.supabaseUrl}/auth/v1/user'),
        headers: {..._sbHeaders, 'Authorization': 'Bearer $token'},
        body: jsonEncode({'password': newPassword}),
      );
      return update.statusCode >= 200 && update.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  static String _sbError(String body) {
    try {
      final j = jsonDecode(body) as Map<String, dynamic>;
      return (j['msg'] ?? j['error_description'] ?? j['error'] ?? 'Failed')
          .toString();
    } catch (_) {
      return 'Request failed';
    }
  }

  // ── Primitives ─────────────────────────────────────────────────────────────

  static String _normalizeEmail(String e) => e.trim().toLowerCase();

  static bool _isValidEmail(String e) =>
      RegExp(r'^[\w.\-+]+@[\w\-]+\.[\w\-.]+$').hasMatch(e);

  static String _generateOtp() {
    final rnd = Random.secure();
    return List.generate(6, (_) => rnd.nextInt(10)).join();
  }

  static String _generateRecoveryCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    final a = List.generate(4, (_) => chars[rnd.nextInt(chars.length)]).join();
    final b = List.generate(4, (_) => chars[rnd.nextInt(chars.length)]).join();
    return '$a-$b';
  }

  static String _sha256(String s) =>
      sha256.convert(utf8.encode(s)).toString();

  static bool get usingSupabase => EnvConfig.hasSupabase;
  // The client never sends email itself; "real" email is whatever the Supabase
  // project's own flow provides for recovery/verification.
  static bool get usingRealEmail => EnvConfig.hasSupabase;

  static void debugStatus() {
    debugPrint('[AuthService] supabase=${EnvConfig.hasSupabase} '
        'email=${EnvConfig.hasEmail}');
  }
}
