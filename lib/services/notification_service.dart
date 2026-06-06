import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: androidInit));
  }

  Future<void> showTransactionNotif({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'transactions',
      'Transactions',
      channelDescription: 'Auto-tracked expense notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@drawable/ic_notification',
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  Future<void> showBudgetAlert(String category, double percentUsed) async {
    final emoji = percentUsed >= 100 ? '🚨' : '⚠️';
    await _plugin.show(
      category.hashCode,
      '$emoji Budget Alert: $category',
      percentUsed >= 100
          ? 'You\'ve exceeded your $category budget!'
          : 'You\'ve used ${percentUsed.toInt()}% of your $category budget',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_alerts',
          'Budget Alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> scheduleMondaySummary() async {
    try {
      await _plugin.zonedSchedule(
        999,
        'Your weekly money snapshot 📊',
        'Open SpendLens to see where your money went last week',
        _nextMonday9AM(),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'weekly_summary',
            'Weekly Summary',
            importance: Importance.defaultImportance,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      print('Error scheduling Monday summary: $e');
    }
  }

  tz.TZDateTime _nextMonday9AM() {
    var scheduled = tz.TZDateTime.now(tz.local);
    while (scheduled.weekday != DateTime.monday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return tz.TZDateTime(tz.local, scheduled.year, scheduled.month,
        scheduled.day, 9, 0);
  }
}
