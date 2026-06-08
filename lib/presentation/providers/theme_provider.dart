import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/hive_service.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final isDark = HiveService.settings.get('isDarkMode', defaultValue: true) as bool;
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void toggle() {
    final nowDark = state == ThemeMode.dark;
    state = nowDark ? ThemeMode.light : ThemeMode.dark;
    HiveService.settings.put('isDarkMode', !nowDark);
  }

  void setDark() {
    state = ThemeMode.dark;
    HiveService.settings.put('isDarkMode', true);
  }

  void setLight() {
    state = ThemeMode.light;
    HiveService.settings.put('isDarkMode', false);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
