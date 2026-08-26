import 'package:flutter_test/flutter_test.dart';
import 'package:spendlens/core/constants/app_constants.dart';
import 'package:spendlens/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // google_fonts needs the binding

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
}
