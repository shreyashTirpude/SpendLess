import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/auth/auth_screen.dart';
import '../../presentation/screens/auth/signup_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/mfa_setup_screen.dart';
import '../../presentation/screens/auth/lock_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/transactions/transactions_screen.dart';
import '../../presentation/screens/budget/budget_screen.dart';
import '../../presentation/screens/insights/insights_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/home/main_shell.dart';
import '../../presentation/screens/subscriptions/subscriptions_screen.dart';
import '../../presentation/screens/legal/terms_screen.dart';
import '../../presentation/screens/paywall/paywall_screen.dart';
import '../../presentation/screens/chat/chat_screen.dart';
import '../../presentation/screens/savings/micro_savings_screen.dart';
import '../../presentation/screens/festival/festival_planner_screen.dart';

// Material shared-axis (X) — incoming slides+fades in, outgoing slides+fades out.
// Gives a premium, directional feel for full-screen pushes.
Page<void> _slidePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const curve = Curves.easeOutCubic;
      final inSlide = Tween<Offset>(
        begin: const Offset(0.10, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: curve));
      final outSlide = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.06, 0.0),
      ).animate(CurvedAnimation(parent: secondaryAnimation, curve: curve));

      return SlideTransition(
        position: outSlide,
        child: SlideTransition(
          position: inSlide,
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
        ),
      );
    },
  );
}

// Shared-axis (Z) — scale + fade. For splash/onboarding/auth transitions.
Page<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 420),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
      final scale = Tween<double>(begin: 0.96, end: 1.0)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
}

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => _fadePage(state, const SplashScreen()),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => _fadePage(state, const OnboardingScreen()),
    ),
    GoRoute(
      path: '/auth',
      pageBuilder: (context, state) => _slidePage(state, const AuthScreen()),
    ),
    GoRoute(
      path: '/signup',
      pageBuilder: (context, state) => _slidePage(state, const SignupScreen()),
    ),
    GoRoute(
      path: '/forgot-password',
      pageBuilder: (context, state) =>
          _slidePage(state, const ForgotPasswordScreen()),
    ),
    GoRoute(
      path: '/mfa-setup',
      pageBuilder: (context, state) => _slidePage(state, const MfaSetupScreen()),
    ),
    GoRoute(
      path: '/lock',
      pageBuilder: (context, state) => _fadePage(state, const LockScreen()),
    ),
    GoRoute(
      path: '/terms',
      pageBuilder: (context, state) => _slidePage(state, const TermsScreen()),
    ),
    GoRoute(
      path: '/subscriptions',
      pageBuilder: (context, state) => _slidePage(state, const SubscriptionsScreen()),
    ),
    GoRoute(
      path: '/paywall',
      pageBuilder: (context, state) => _slidePage(state, const PaywallScreen()),
    ),
    GoRoute(
      path: '/chat',
      pageBuilder: (context, state) => _slidePage(state, const ChatScreen()),
    ),
    GoRoute(
      path: '/savings',
      pageBuilder: (context, state) => _slidePage(state, const MicroSavingsScreen()),
    ),
    GoRoute(
      path: '/festival',
      pageBuilder: (context, state) => _slidePage(state, const FestivalPlannerScreen()),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => _fadePage(state, const HomeScreen()),
        ),
        GoRoute(
          path: '/transactions',
          pageBuilder: (context, state) => _fadePage(state, const TransactionsScreen()),
        ),
        GoRoute(
          path: '/budget',
          pageBuilder: (context, state) => _fadePage(state, const BudgetScreen()),
        ),
        GoRoute(
          path: '/insights',
          pageBuilder: (context, state) => _fadePage(state, const InsightsScreen()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => _fadePage(state, const SettingsScreen()),
        ),
      ],
    ),
  ],
);
