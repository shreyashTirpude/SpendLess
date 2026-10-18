import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/hive_service.dart';
import '../../domain/models/user_profile.dart';
import '../../services/auth/auth_service.dart';

// ─── User Profile ────────────────────────────────────────────────────────────

class UserProfileNotifier extends Notifier<UserProfile?> {
  @override
  UserProfile? build() {
    final p = _load();
    _autoSyncFromAccount(p);
    return p;
  }

  UserProfile? _load() {
    final profiles = HiveService.user.values;
    return profiles.isEmpty ? null : profiles.first;
  }

  /// If the user signed up / logged in, auto-fill the profile name from their
  /// account so Settings reflects it without re-entry.
  void _autoSyncFromAccount(UserProfile? p) {
    final acct = AuthService.currentUser;
    if (acct == null) return;
    final nameMissing = (p?.name == null || (p?.name?.isEmpty ?? true));
    if (nameMissing && acct.name.isNotEmpty) {
      Future.microtask(() => updateName(acct.name));
    }
  }

  Future<UserProfile> _ensureProfile() async {
    var profile = state;
    if (profile == null) {
      profile = UserProfile(
        id: const Uuid().v4(),
        phone: '',
        createdAt: DateTime.now(),
      );
      await HiveService.user.add(profile);
    }
    return profile;
  }

  Future<void> updateName(String name) async {
    final profile = await _ensureProfile();
    profile.name = name.trim();
    await profile.save();
    state = _load();
  }

  Future<void> updatePhone(String phone) async {
    final profile = await _ensureProfile();
    profile.phone = phone.trim();
    await profile.save();
    state = _load();
  }
}

final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new,
);

/// The authenticated account's email (auto-synced display in Settings).
final accountEmailProvider = Provider<String?>((ref) {
  return AuthService.currentUser?.email;
});

// ─── App Settings (notifications, preferences) ───────────────────────────────

typedef AppSettings = ({
  bool appLockEnabled,
  bool biometricEnabled,
  bool transactionAlerts,
  bool budgetAlerts,
  bool weeklyReports,
  double weekdayDailyBudget,
  double weekendDailyBudget,
});

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final s = HiveService.settings;
    return (
      appLockEnabled: s.get('appLockEnabled', defaultValue: false) as bool,
      biometricEnabled: s.get('biometricEnabled', defaultValue: false) as bool,
      transactionAlerts: s.get('transactionAlerts', defaultValue: true) as bool,
      budgetAlerts: s.get('budgetAlerts', defaultValue: true) as bool,
      weeklyReports: s.get('weeklyReports', defaultValue: true) as bool,
      weekdayDailyBudget: (s.get('weekdayDailyBudget', defaultValue: 0.0) as num).toDouble(),
      weekendDailyBudget: (s.get('weekendDailyBudget', defaultValue: 0.0) as num).toDouble(),
    );
  }

  Future<void> toggle(String key) async {
    final current = _getValue(key);
    await HiveService.settings.put(key, !current);
    state = _reload();
  }

  Future<void> setAppLock(bool enabled) async {
    await HiveService.settings.put('appLockEnabled', enabled);
    state = _reload();
  }

  Future<void> setWeekdayBudget(double amount) async {
    await HiveService.settings.put('weekdayDailyBudget', amount);
    state = _reload();
  }

  Future<void> setWeekendBudget(double amount) async {
    await HiveService.settings.put('weekendDailyBudget', amount);
    state = _reload();
  }

  bool _getValue(String key) {
    switch (key) {
      case 'appLockEnabled': return state.appLockEnabled;
      case 'biometricEnabled': return state.biometricEnabled;
      case 'transactionAlerts': return state.transactionAlerts;
      case 'budgetAlerts': return state.budgetAlerts;
      case 'weeklyReports': return state.weeklyReports;
      default: return false;
    }
  }

  AppSettings _reload() {
    final s = HiveService.settings;
    return (
      appLockEnabled: s.get('appLockEnabled', defaultValue: false) as bool,
      biometricEnabled: s.get('biometricEnabled', defaultValue: false) as bool,
      transactionAlerts: s.get('transactionAlerts', defaultValue: true) as bool,
      budgetAlerts: s.get('budgetAlerts', defaultValue: true) as bool,
      weeklyReports: s.get('weeklyReports', defaultValue: true) as bool,
      weekdayDailyBudget: (s.get('weekdayDailyBudget', defaultValue: 0.0) as num).toDouble(),
      weekendDailyBudget: (s.get('weekendDailyBudget', defaultValue: 0.0) as num).toDouble(),
    );
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

// ─── Savings Goal ─────────────────────────────────────────────────────────────

class SavingsGoalNotifier extends Notifier<double> {
  @override
  double build() =>
      (HiveService.settings.get('monthlySavingsGoal', defaultValue: 0.0) as num).toDouble();

  Future<void> setGoal(double amount) async {
    await HiveService.settings.put('monthlySavingsGoal', amount);
    state = amount;
  }
}

final savingsGoalProvider = NotifierProvider<SavingsGoalNotifier, double>(
  SavingsGoalNotifier.new,
);
