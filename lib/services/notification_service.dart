import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get _isMacOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(const InitializationSettings(
      android: androidInit,
      macOS: darwinInit,
    ));
  }

  Future<void> showTransactionNotif({
    required String title,
    required String body,
  }) async {
    final details = _buildDetails(
      androidChannelId: 'transactions',
      androidChannelName: 'Transactions',
      androidDesc: 'Auto-tracked expense notifications',
      androidIcon: '@drawable/ic_notification',
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  Future<void> showBudgetAlert(String category, double percentUsed) async {
    final emoji = percentUsed >= 100 ? '🚨' : '⚠️';
    final details = _buildDetails(
      androidChannelId: 'budget_alerts',
      androidChannelName: 'Budget Alerts',
      high: true,
    );
    await _plugin.show(
      category.hashCode,
      '$emoji Budget Alert: $category',
      percentUsed >= 100
          ? 'You\'ve exceeded your $category budget!'
          : 'You\'ve used ${percentUsed.toInt()}% of your $category budget',
      details,
    );
  }

  Future<void> showDailyBudgetAlert({
    required bool isWeekend,
    required double spent,
    required double limit,
  }) async {
    final dayType = isWeekend ? 'Weekend' : 'Weekday';
    final excess = spent - limit;
    final details = _buildDetails(
      androidChannelId: 'daily_limits',
      androidChannelName: 'Daily Spending Limits',
      androidDesc: 'Alerts when daily spending exceeds your set limit',
      high: true,
    );
    await _plugin.show(
      isWeekend ? 2001 : 2000,
      isWeekend ? '🏖️ Weekend Limit Exceeded' : '📅 Weekday Limit Exceeded',
      '$dayType: ₹${spent.toStringAsFixed(0)} spent — ₹${excess.toStringAsFixed(0)} over your ₹${limit.toStringAsFixed(0)} daily limit',
      details,
    );
  }

  Future<void> scheduleMondaySummary() async {
    if (!_isAndroid && !_isMacOS) return;
    try {
      final details = _buildDetails(
        androidChannelId: 'weekly_summary',
        androidChannelName: 'Weekly Summary',
      );
      if (_isAndroid) {
        await _plugin.zonedSchedule(
          999,
          'Your weekly money snapshot 📊',
          'Open SpendLens to see where your money went last week',
          _nextMonday9AM(),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } catch (e) {
      // Scheduling not critical — swallow silently
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  NotificationDetails _buildDetails({
    required String androidChannelId,
    required String androidChannelName,
    String? androidDesc,
    String? androidIcon,
    bool high = false,
  }) {
    final android = _isAndroid
        ? AndroidNotificationDetails(
            androidChannelId,
            androidChannelName,
            channelDescription: androidDesc,
            icon: androidIcon,
            importance: high ? Importance.high : Importance.defaultImportance,
            priority: high ? Priority.high : Priority.defaultPriority,
          )
        : null;
    const darwin = DarwinNotificationDetails();
    return NotificationDetails(android: android, macOS: darwin);
  }

  tz.TZDateTime _nextMonday9AM() {
    var scheduled = tz.TZDateTime.now(tz.local);
    while (scheduled.weekday != DateTime.monday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return tz.TZDateTime(
        tz.local, scheduled.year, scheduled.month, scheduled.day, 9, 0);
  }
}
