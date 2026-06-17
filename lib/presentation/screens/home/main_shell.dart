import 'dart:async';
import 'dart:ui';
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
      await SmsScannerService.startListening();
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
      bottomNavigationBar: _PillNavBar(
        selectedIndex: idx,
        isDark: isDark,
        onTap: (i) {
          switch (i) {
            case 0: context.go('/home'); break;
            case 1: context.go('/transactions'); break;
            case 2: context.go('/budget'); break;
            case 3: context.go('/insights'); break;
            case 4: context.go('/settings'); break;
          }
        },
      ),
    );
  }
}

// ── Apple-style pill bottom nav ───────────────────────────────────────────────

class _PillNavBar extends StatelessWidget {
  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _PillNavBar({
    required this.selectedIndex,
    required this.isDark,
    required this.onTap,
  });

  static const _items = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.receipt_long_rounded, label: 'Txns'),
    (icon: Icons.pie_chart_rounded, label: 'Budget'),
    (icon: Icons.trending_up_rounded, label: 'Insights'),
    (icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.surface : Colors.white;
    final borderColor = isDark ? AppColors.cardBorder : const Color(0xFFE4E4ED);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: isDark ? 0.85 : 0.92),
            border: Border(top: BorderSide(color: borderColor, width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: Row(
                children: List.generate(_items.length, (i) {
                  final item = _items[i];
                  final isSelected = i == selectedIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              padding: EdgeInsets.symmetric(
                                horizontal: isSelected ? 14 : 0,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item.icon,
                                size: 22,
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.textMuted : AppColors.textMutedLight),
                              ),
                            ),
                            const SizedBox(height: 2),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.textMuted : AppColors.textMutedLight),
                              ),
                              child: Text(item.label),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
