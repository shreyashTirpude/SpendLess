import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/local/hive_service.dart';
import '../../../services/password_service.dart';

bool get _isDemoMode =>
    kIsWeb || defaultTargetPlatform != TargetPlatform.android;

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

    // Demo mode: skip every gate — go straight to /home
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
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          context.go('/onboarding');
          return;
        }
        await HiveService.settings.put('isOnboarded', true);
      }

      // Gate 3: App lock
      final locked = await PasswordService.hasPassword();
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
            Text(
              '💸',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 80),
            ),
            const SizedBox(height: 20),
            Text(
              'SpendLens',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.primary,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
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
