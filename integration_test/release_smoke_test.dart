import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spendlens/core/config/app_router.dart';
import 'package:spendlens/data/local/hive_service.dart';
import 'package:spendlens/main.dart' as app;
import 'package:spendlens/services/demo_data_service.dart';
import 'package:spendlens/services/sms_scanner_service.dart';
import 'package:telephony/telephony.dart';

// Value: protects=Android navigation and durable manual transaction creation;
// fails_when=real app boot, form save, route changes or Hive persistence breaks;
// why_new=legacy integration tests assume obsolete labels and navigation; seam=none
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android demo: navigation, add transaction, persistence', (tester) async {
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      debugPrint(details.toString());
      previousErrorHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousErrorHandler);
    // Home renders subtle looping UI (and the chat screen repeats dot
    // animations), so pumpAndSettle would pump frames forever and time out.
    // A bounded pump sequence keeps the test deterministic instead.
    Future<void> settle() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
    }
    app.main();
    // main is async-void. Let native storage initialization complete before
    // interacting, using the mounted root rather than assuming a fixed delay.
    for (var attempt = 0; attempt < 60 && find.byType(MaterialApp).evaluate().isEmpty; attempt++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    // Synthetic data on a disposable emulator; no live account or inbox is used.
    await DemoDataService.activateDemo();
    appRouter.go('/home');
    await settle();
    expect(find.text('Home'), findsWidgets);
    // Exercise the real registered foreground adapter on Android, with
    // synthetic plugin events (not live bank messages or OS SMS delivery).
    await HiveService.settings.put('transactionAlerts', false);
    await SmsScannerService.startListening();
    final smsDate = DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch - 3600000);
    const smsBody = 'INR 1526.75 debited from A/c XX4821 via UPI. Avl Bal: INR 9500.00.';
    Future<void> emitSms(String? sender) async {
      await Telephony.instance.handler(MethodCall('onMessage', {
        'message': {
          'originating_address': sender,
          'message_body': smsBody,
          'timestamp': '${smsDate.millisecondsSinceEpoch}',
          'service_center': '',
          'status': '0',
        },
      }));
    }
    // The boot-time inbox scan streams rows into Hive while it parses. Capture
    // the baseline only once the transaction count has stopped changing, so
    // the scan's tail cannot race the foreground-handler assertions below.
    var baseline = HiveService.transactions.length;
    var stablePasses = 0;
    for (var attempt = 0; attempt < 60 && stablePasses < 4; attempt++) {
      await tester.pump(const Duration(milliseconds: 500));
      final current = HiveService.transactions.length;
      if (current == baseline) {
        stablePasses++;
      } else {
        stablePasses = 0;
        baseline = current;
      }
    }
    final initialCount = HiveService.transactions.length;
    await emitSms('AD-HDFCBKSCAM');
    await emitSms(null);
    expect(HiveService.transactions.length, initialCount);
    await emitSms('AD-HDFCBK');
    expect(HiveService.transactions.length, initialCount + 1);
    final imported = HiveService.transactions.values.singleWhere((t) => t.amount == 1526.75);
    expect(imported.transactionDate, smsDate);
    await emitSms('AD-HDFCBK');
    expect(HiveService.transactions.length, initialCount + 1);
    await settle();
    for (final label in ['Budget', 'Insights', 'Settings', 'Txns']) {
      await tester.tap(find.text(label).last);
      await settle();
      expect(tester.takeException(), isNull, reason: '$label renders without errors');
    }
    expect(find.text('Transactions'), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await settle();
    // The actual impulse guard can delay the form on busy demo days.
    for (var attempt = 0; attempt < 8 && find.text('Spending Check').evaluate().isNotEmpty; attempt++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await settle();
    final amount = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == '0');
    final merchant = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Merchant or person name');
    await tester.enterText(amount, '321');
    await tester.enterText(merchant, 'Release QA Fixture');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle();
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Add Transaction'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Transaction'));
    await settle();
    expect(find.text('Release QA Fixture'), findsWidgets);
    final saved = HiveService.transactions.values.where((t) => t.merchant == 'Release QA Fixture').single;
    expect(saved.amount, 321);
    expect(saved.source, 'manual');
    await tester.tap(find.text('Home').last);
    await settle();
    await tester.tap(find.text('Txns').last);
    await settle();
    expect(find.text('Release QA Fixture'), findsWidgets);
    expect(tester.takeException(), isNull);
    // Dispose real shell timers before ending the integration test.
    appRouter.go('/auth');
    await settle();
  });
}
