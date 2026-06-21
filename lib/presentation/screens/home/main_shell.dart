import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/local/hive_service.dart';
import '../../../services/sms_scanner_service.dart';
import '../../../services/demo_data_service.dart';
import '../../../services/notification_service.dart';
import '../../providers/cache_provider.dart';

bool get _isDemoMode =>
    kIsWeb ||
    defaultTargetPlatform != TargetPlatform.android ||
    DemoDataService.isActive;

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({Key? key, required this.child}) : super(key: key);

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  StreamSubscription? _hiveWatcher;
  Timer? _periodicScan;

  /// How often to re-scan the SMS inbox while the app is in the foreground.
  /// 15 min balances freshness against battery; new SMS also arrive instantly
  /// via the real-time listener, so this is just a safety-net catch-up.
  static const _scanInterval = Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Initialise notifications + request Android 13 permission once.
      await NotificationService().initialize();
      await SmsScannerService.startListening();
      await _rescan();
    });

    // Periodic catch-up scan (foreground only).
    _periodicScan = Timer.periodic(_scanInterval, (_) => _rescan());

    // Auto-refresh UI whenever Hive transactions box changes (real-time SMS)
    _hiveWatcher = HiveService.transactions.watch().listen((_) {
      if (mounted) {
        ref.read(transactionCacheProvider.notifier).bump();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Catch up on any SMS that arrived while the app was backgrounded.
    if (state == AppLifecycleState.resumed) _rescan();
  }

  Future<void> _rescan() async {
    final added = await SmsScannerService.scanInbox();
    if (added > 0 && mounted) {
      ref.read(transactionCacheProvider.notifier).bump();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodicScan?.cancel();
    _hiveWatcher?.cancel();
    super.dispose();
  }

  void _showDemoInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('🧪', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text('Demo Mode', style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 12),
            Text(
              '150+ mock transactions across 4 months. All Pro features unlocked. '
              'No real SMS data is used.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            const _DemoFeatureRow('💸', 'Transactions', '150+ entries across 18 categories'),
            const _DemoFeatureRow('📊', 'Budgets', 'Pre-set limits — some over, some under'),
            const _DemoFeatureRow('🔄', 'Subscriptions', 'Netflix, Spotify, Hotstar recurring'),
            const _DemoFeatureRow('📈', 'Insights', 'Month-over-month trends + day ranking'),
            const _DemoFeatureRow('💰', 'Cashflow', 'Salary, Rent, Friends, Family buckets'),
            const _DemoFeatureRow('🎉', 'Festival Planner', 'Diwali, Dussehra budgets set'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reset & Re-seed Demo Data'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7C3AED),
                  side: const BorderSide(color: Color(0xFF7C3AED)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await DemoDataService.reset();
                  await DemoDataService.seed();
                  if (mounted) ref.read(transactionCacheProvider.notifier).bump();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Demo data reset and re-seeded ✓')),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Exit Demo Mode'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _exitDemo(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exitDemo(BuildContext sheetContext) async {
    Navigator.pop(sheetContext); // close the sheet
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Exit demo mode?',
            style: TextStyle(color: context.textPrimary)),
        content: Text(
          'This clears all sample data and returns to the login screen.',
          style: TextStyle(color: context.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: context.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await DemoDataService.reset();
    if (mounted) ref.read(transactionCacheProvider.notifier).bump();
    if (mounted) context.go('/auth');
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
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.025),
                end: Offset.zero,
              ).animate(animation);
              final scale = Tween<double>(begin: 0.985, end: 1.0)
                  .animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: slide,
                  child: ScaleTransition(scale: scale, child: child),
                ),
              );
            },
            child: KeyedSubtree(key: ValueKey(idx), child: widget.child),
          ),
          // Demo mode banner — top-right corner
          if (_isDemoMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 12,
              child: GestureDetector(
                onTap: () => _showDemoInfo(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🧪', style: TextStyle(fontSize: 11)),
                      SizedBox(width: 4),
                      Text(
                        'DEMO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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

// ── Demo feature row ──────────────────────────────────────────────────────────

class _DemoFeatureRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  const _DemoFeatureRow(this.emoji, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                children: [
                  TextSpan(text: '$title  ', style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  TextSpan(text: subtitle),
                ],
              ),
            ),
          ),
        ],
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
