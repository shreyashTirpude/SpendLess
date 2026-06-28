import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/local/hive_service.dart';
import '../../../services/password_service.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/demo_data_service.dart';

/// Non-Android platforms (macOS/web dev) auto-seed + skip straight to home.
bool get _isDemoPlatform =>
    kIsWeb || defaultTargetPlatform != TargetPlatform.android;

/// Show the DEMO badge when running on a demo platform OR the user explicitly
/// activated demo mode from the login screen (works on Android too).
bool get _isDemoMode => _isDemoPlatform || DemoDataService.isActive;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(Duration(milliseconds: _isDemoMode ? 800 : 2000));
    if (!mounted) return;

    // Demo platform (mac/web) or an active demo session: skip every gate.
    if (_isDemoMode) {
      context.go('/home');
      return;
    }

    try {
      // Gate 1: Terms & Conditions must be accepted before anything else
      final termsAccepted =
          HiveService.settings.get('termsAccepted', defaultValue: false) as bool;
      if (!termsAccepted) {
        context.go('/terms');
        return;
      }

      // Gate 2: Onboarding
      final isOnboarded =
          HiveService.settings.get('isOnboarded', defaultValue: false) as bool;
      if (!isOnboarded) {
        context.go('/onboarding');
        return;
      }

      // Gate 3: Authentication — if not signed in, show login (with Demo option)
      if (!AuthService.isLoggedIn) {
        context.go('/auth');
        return;
      }

      // Gate 4: App lock
      final locked = await PasswordService.hasPassword();
      if (!mounted) return;
      context.go(locked ? '/lock' : '/home');
    } catch (_) {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientMid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gradientStart.withValues(alpha: 0.45),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 44),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'SpendLens',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Track every rupee, effortlessly',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            if (_isDemoMode) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '🧪  DEMO MODE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
