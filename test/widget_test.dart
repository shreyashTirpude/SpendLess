import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendlens/core/constants/app_constants.dart';
import 'package:spendlens/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:spendlens/presentation/widgets/auth/auth_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // google_fonts needs the binding
  GoogleFonts.config.allowRuntimeFetching = false; // fonts are bundled assets

  // Real smoke checks replacing the old `expect(true, isTrue)` placeholder:
  // theme construction and core constants are load-bearing for every screen.
  test('AppTheme exposes valid light & dark themes', () {
    final light = AppTheme.lightTheme;
    final dark = AppTheme.darkTheme;
    expect(light.colorScheme.brightness, Brightness.light);
    expect(dark.colorScheme.brightness, Brightness.dark);
    expect(light.useMaterial3, isTrue);
  });

  test('AppConstants are sane', () {
    expect(AppConstants.appName, isNotEmpty);
    expect(AppConstants.defaultBudget, greaterThan(0));
  });

  // Value: protects=readable and tappable demo entry on narrow phones;
  // fails_when=the long demo label overflows fixed width/height;
  // why_new=theme tests do not render auth controls; seam=none
  for (final scale in [1.0, 1.5]) {
    testWidgets('demo entry fits 320dp at text scale $scale', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var tapped = false;
      await tester.pumpWidget(MaterialApp(theme: AppTheme.lightTheme,
        home: MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(body: Padding(padding: const EdgeInsets.all(24),
            child: DemoButton(onPressed: () => tapped = true))))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isTrue);
      expect(find.text('Try Demo — Explore with Sample Data'), findsOneWidget);
    });
  }
}
