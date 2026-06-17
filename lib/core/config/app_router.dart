import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/auth/auth_screen.dart';
import '../../presentation/screens/auth/lock_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/transactions/transactions_screen.dart';
import '../../presentation/screens/budget/budget_screen.dart';
import '../../presentation/screens/insights/insights_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/home/main_shell.dart';
import '../../presentation/screens/subscriptions/subscriptions_screen.dart';
import '../../presentation/screens/legal/terms_screen.dart';

// Slide-in from right + fade-in combo for full-screen pushes
Page<void> _slidePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(0.06, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);

      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

// Pure fade for splash/onboarding (no directional slide)
Page<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
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
