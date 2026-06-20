import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/config/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/local/hive_service.dart';
import 'presentation/providers/theme_provider.dart';
import 'services/password_service.dart';
import 'services/demo_data_service.dart';

bool get _isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('[SpendLens] dotenv load failed: $e');
  }

  try {
    await HiveService.initialize();
  } catch (e) {
    debugPrint('[SpendLens] Hive init failed: $e');
  }

  // Seed demo data on every non-Android platform (macOS, web, iOS, Windows)
  if (!_isAndroid) {
    try {
      await DemoDataService.seed();
    } catch (e) {
      debugPrint('[SpendLens] Demo seed: $e');
    }
  }

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('[SpendLens] Firebase init: $e');
  }

  runApp(const ProviderScope(child: SpendLensApp()));
}

class SpendLensApp extends ConsumerStatefulWidget {
  const SpendLensApp({Key? key}) : super(key: key);

  @override
  ConsumerState<SpendLensApp> createState() => _SpendLensAppState();
}

class _SpendLensAppState extends ConsumerState<SpendLensApp>
    with WidgetsBindingObserver {
  bool _wasBackgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _wasBackgrounded = true;
    } else if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      _lockIfNeeded();
    }
  }

  Future<void> _lockIfNeeded() async {
    final hasPassword = await PasswordService.hasPassword();
    if (hasPassword) {
      appRouter.go('/lock');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'SpendLens',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
