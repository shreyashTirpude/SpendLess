import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/hive_service.dart';
import '../../domain/models/user_profile.dart';

// ─── User Profile ────────────────────────────────────────────────────────────

class UserProfileNotifier extends Notifier<UserProfile?> {
  @override
  UserProfile? build() {
    final profiles = HiveService.user.values;
    return profiles.isEmpty ? null : profiles.first;
  }

  Future<void> updateName(String name) async {
    final profile = state;
    if (profile == null) return;
    profile.name = name.trim();
    await profile.save();
    state = UserProfile(
      id: profile.id,
      phone: profile.phone,
      name: profile.name,
      monthlyBudget: profile.monthlyBudget,
      adsRemoved: profile.adsRemoved,
      biometricEnabled: profile.biometricEnabled,
      createdAt: profile.createdAt,
    );
  }

  Future<void> updatePhone(String phone) async {
    final profile = state;
    if (profile == null) return;
    profile.phone = phone.trim();
    await profile.save();
    state = UserProfile(
      id: profile.id,
      phone: profile.phone,
      name: profile.name,
      monthlyBudget: profile.monthlyBudget,
      adsRemoved: profile.adsRemoved,
      biometricEnabled: profile.biometricEnabled,
      createdAt: profile.createdAt,
    );
  }
}

final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new,
);

// ─── App Settings (notifications, preferences) ───────────────────────────────

typedef AppSettings = ({
  bool appLockEnabled,
  bool transactionAlerts,
  bool budgetAlerts,
  bool weeklyReports,
});

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final s = HiveService.settings;
    return (
      appLockEnabled: s.get('appLockEnabled', defaultValue: false) as bool,
      transactionAlerts: s.get('transactionAlerts', defaultValue: true) as bool,
      budgetAlerts: s.get('budgetAlerts', defaultValue: true) as bool,
      weeklyReports: s.get('weeklyReports', defaultValue: true) as bool,
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

  bool _getValue(String key) {
    switch (key) {
      case 'appLockEnabled': return state.appLockEnabled;
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
      transactionAlerts: s.get('transactionAlerts', defaultValue: true) as bool,
      budgetAlerts: s.get('budgetAlerts', defaultValue: true) as bool,
      weeklyReports: s.get('weeklyReports', defaultValue: true) as bool,
    );
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
