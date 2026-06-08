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

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (_, __) => const AuthScreen(),
    ),
    GoRoute(
      path: '/lock',
      builder: (_, __) => const LockScreen(),
    ),
    GoRoute(
      path: '/subscriptions',
      builder: (_, __) => const SubscriptionsScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          path: '/transactions',
          builder: (_, __) => const TransactionsScreen(),
        ),
        GoRoute(
          path: '/budget',
          builder: (_, __) => const BudgetScreen(),
        ),
        GoRoute(
          path: '/insights',
          builder: (_, __) => const InsightsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
