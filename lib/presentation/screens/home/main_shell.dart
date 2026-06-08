import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/local/hive_service.dart';
import '../../../services/sms_scanner_service.dart';
import '../../providers/cache_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({Key? key, required this.child}) : super(key: key);

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  StreamSubscription? _hiveWatcher;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      SmsScannerService.startListening();
      final added = await SmsScannerService.scanInbox();
      if (added > 0 && mounted) {
        ref.read(transactionCacheProvider.notifier).bump();
      }
    });

    // Auto-refresh UI whenever Hive transactions box changes (real-time SMS)
    _hiveWatcher = HiveService.transactions.watch().listen((_) {
      if (mounted) {
        ref.read(transactionCacheProvider.notifier).bump();
      }
    });
  }

  @override
  void dispose() {
    _hiveWatcher?.cancel();
    super.dispose();
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/budget')) return 2;
    if (location.startsWith('/insights')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _selectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
        child: KeyedSubtree(key: ValueKey(idx), child: widget.child),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: idx,
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? AppColors.cardBg : Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: isDark ? AppColors.textMuted : AppColors.textMutedLight,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          onTap: (i) {
            switch (i) {
              case 0: context.go('/home'); break;
              case 1: context.go('/transactions'); break;
              case 2: context.go('/budget'); break;
              case 3: context.go('/insights'); break;
              case 4: context.go('/settings'); break;
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Transactions'),
            BottomNavigationBarItem(icon: Icon(Icons.pie_chart_rounded), label: 'Budget'),
            BottomNavigationBarItem(icon: Icon(Icons.trending_up_rounded), label: 'Insights'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
