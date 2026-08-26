import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/local/hive_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildSlide(
                    title: 'Your money, tracked automatically',
                    subtitle: 'SpendLens reads your bank SMS and logs every transaction the moment it happens.',
                    emoji: '📱',
                  ),
                  _buildSlide(
                    title: 'Zero manual entry',
                    subtitle: 'Every UPI, debit card, and net banking transaction — automatically categorized.',
                    emoji: '✨',
                  ),
                  _buildSlide(
                    title: 'Your data stays private',
                    subtitle: 'Your SMS is processed on YOUR phone only. We never read or store your messages.',
                    emoji: '🔒',
                  ),
                  _buildSlide(
                    title: 'We built privacy in',
                    subtitle: 'One suggestion per week. You control your data. Delete anytime with one tap.',
                    emoji: '🛡️',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      4,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? AppColors.primary : AppColors.textMuted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_currentPage == 3) {
                          // Persist completion so the splash gate doesn't loop
                          // the user back to onboarding on every launch.
                          await HiveService.settings.put('isOnboarded', true);
                          if (context.mounted) context.go('/auth');
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Text(
                        _currentPage == 3 ? 'Get Started' : 'Next',
                        style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide({
    required String title,
    required String subtitle,
    required String emoji,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 80)),
        const SizedBox(height: 32),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.headingLarge.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
