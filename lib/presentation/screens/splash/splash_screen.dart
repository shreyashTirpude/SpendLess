import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/local/hive_service.dart';
import '../../../services/password_service.dart';

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
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    try {
      // Primary check: local onboarding flag (works offline)
      final isOnboarded = HiveService.settings.get('isOnboarded', defaultValue: false) as bool;
      if (!isOnboarded) {
        // Also check Firebase as fallback
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          context.go('/onboarding');
          return;
        }
        // Firebase user exists but local flag not set — fix it and proceed
        await HiveService.settings.put('isOnboarded', true);
      }
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
          ],
        ),
      ),
    );
  }
}
