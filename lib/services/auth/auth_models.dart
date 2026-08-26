/// Plain (codegen-free) models for the auth subsystem. Persisted as JSON inside
/// the Hive settings box so no new Hive type/adapter is required.
library;

class AuthAccount {
  final String id;
  final String email;
  String name;
  String passwordHash;
  final DateTime createdAt;

  // MFA
  bool mfaEnabled;
  String? mfaSecret; // base32 TOTP secret
  List<String> recoveryCodeHashes;

  // Membership
  String tier; // 'free' | 'plus' | 'pro' | 'family'
  DateTime? tierExpiry; // null = no expiry (free / lifetime)

  bool emailVerified;

  AuthAccount({
    required this.id,
    required this.email,
    required this.name,
    required this.passwordHash,
    required this.createdAt,
    this.mfaEnabled = false,
    this.mfaSecret,
    this.recoveryCodeHashes = const [],
    this.tier = 'free',
    this.tierExpiry,
    this.emailVerified = false,
  });

  bool get isPro => tier == 'pro' || tier == 'family' || tier == 'plus';

  bool get isExpired =>
      tierExpiry != null && DateTime.now().isAfter(tierExpiry!);

  int? get daysUntilExpiry => tierExpiry?.difference(DateTime.now()).inDays;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'passwordHash': passwordHash,
        'createdAt': createdAt.toIso8601String(),
        'mfaEnabled': mfaEnabled,
        'mfaSecret': mfaSecret,
        'recoveryCodeHashes': recoveryCodeHashes,
        'tier': tier,
        'tierExpiry': tierExpiry?.toIso8601String(),
        'emailVerified': emailVerified,
      };

  factory AuthAccount.fromJson(Map<String, dynamic> j) => AuthAccount(
        id: j['id'] as String,
        email: j['email'] as String,
        name: (j['name'] ?? '') as String,
        passwordHash: (j['passwordHash'] ?? '') as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        mfaEnabled: (j['mfaEnabled'] ?? false) as bool,
        mfaSecret: j['mfaSecret'] as String?,
        recoveryCodeHashes:
            (j['recoveryCodeHashes'] as List?)?.cast<String>() ?? const [],
        tier: (j['tier'] ?? 'free') as String,
        tierExpiry: j['tierExpiry'] != null
            ? DateTime.parse(j['tierExpiry'] as String)
            : null,
        emailVerified: (j['emailVerified'] ?? false) as bool,
      );
}

/// Outcome of an auth operation, with a typed status the UI switches on.
enum AuthStatus {
  ok,
  invalidCredentials,
  emailInUse,
  weakPassword,
  invalidEmail,
  userNotFound,
  otpRequired,
  otpInvalid,
  otpExpired,
  mfaRequired,
  mfaInvalid,
  rateLimited,
  networkError,
  unknown,
}

class AuthResult {
  final AuthStatus status;
  final String? message;
  final AuthAccount? account;

  /// In demo mode (no email backend) the OTP is returned here so the UI can
  /// surface it instead of relying on a real inbox.
  final String? demoOtp;

  const AuthResult(this.status, {this.message, this.account, this.demoOtp});

  bool get ok => status == AuthStatus.ok;

  factory AuthResult.success([AuthAccount? account]) =>
      AuthResult(AuthStatus.ok, account: account);
}

/// Password strength scoring for the live signup meter.
class PasswordStrength {
  final int score; // 0..4
  final String label;
  final List<String> unmet;

  const PasswordStrength(this.score, this.label, this.unmet);

  static PasswordStrength evaluate(String pw) {
    final unmet = <String>[];
    if (pw.length < 8) unmet.add('At least 8 characters');
    if (!RegExp(r'[A-Z]').hasMatch(pw)) unmet.add('One uppercase letter');
    if (!RegExp(r'[a-z]').hasMatch(pw)) unmet.add('One lowercase letter');
    if (!RegExp(r'[0-9]').hasMatch(pw)) unmet.add('One number');
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]').hasMatch(pw)) {
      unmet.add('One symbol');
    }
    final met = 5 - unmet.length;
    final score = pw.isEmpty ? 0 : met.clamp(0, 4);
    const labels = ['Very weak', 'Weak', 'Fair', 'Good', 'Strong'];
    return PasswordStrength(score, labels[score], unmet);
  }

  /// Minimum bar to accept a password at signup. Hardened: every complexity
  /// rule must be met (uppercase, lowercase, number, symbol) AND length ≥ 8.
  bool get isAcceptable => unmet.isEmpty;
}
