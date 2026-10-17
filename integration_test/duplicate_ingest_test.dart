import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spendlens/core/config/app_router.dart';
import 'package:spendlens/data/local/hive_service.dart';
import 'package:spendlens/main.dart' as app;
import 'package:spendlens/services/demo_data_service.dart';
import 'package:spendlens/services/sms_scanner_service.dart';

// Value: protects=users from duplicate payments after overlapping SMS scans
// (startup scan + resume scan + 15-min timer all call scanInbox concurrently);
// fails_when=the same raw SMS is stored under two transaction ids;
// why_new=no existing test exercises concurrent ingest; seam=none
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('overlapping inbox scans never duplicate transactions (demo active)',
      (tester) async {
    app.main();
    for (var attempt = 0;
        attempt < 60 &&
        find.byType(MaterialApp).evaluate().isEmpty;
        attempt++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));

    // Demo data active, exactly as the user runs it.
    await DemoDataService.activateDemo();
    await HiveService.settings.put('transactionAlerts', false);
    appRouter.go('/home');
    await tester.pump(const Duration(milliseconds: 500));

    // MainShell.initState kicked off the initial inbox scan. Fire three more
    // scans immediately — the same overlap that resume + timer produce.
    await Future.wait([
      SmsScannerService.scanInbox(),
      SmsScannerService.scanInbox(),
      SmsScannerService.scanInbox(),
    ]);
    await tester.pump(const Duration(seconds: 10));

    // Group every stored transaction by its raw-SMS hash: one SMS must never
    // produce more than one row.
    final byHash = <String, List<String>>{};
    for (final t in HiveService.transactions.values) {
      final h = t.rawSmsHash;
      if (h == null) continue;
      byHash.putIfAbsent(h, () => []).add('${t.id}/${t.merchant}/${t.amount}');
    }
    final dups = byHash.entries.where((e) => e.value.length > 1).toList();
    // ignore: avoid_print
    print('RACE RESULT: total=${HiveService.transactions.length} '
        'uniqueSms=${byHash.length} duplicateSms=${dups.length}');
    for (final d in dups.take(5)) {
      // ignore: avoid_print
      print('DUP ${d.key}: ${d.value}');
    }
    expect(dups, isEmpty,
        reason: 'one bank SMS was stored as multiple transactions');

    appRouter.go('/auth');
    // Bounded pump: the auth screen has looping animations, so pumpAndSettle
    // would never return.
    await tester.pump(const Duration(seconds: 2));
  });
}
