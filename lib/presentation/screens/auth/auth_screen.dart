import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/auth/auth_models.dart';
import '../../../services/demo_data_service.dart';
import '../../widgets/auth/auth_scaffold.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mfaController = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  bool _mfaRequired = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _mfaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _snack('Enter your email and password');
      return;
    }
    setState(() => _loading = true);

    final res = await ref.read(authProvider.notifier).login(
          email,
          password,
          mfaCode: _mfaRequired ? _mfaController.text.trim() : null,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    switch (res.status) {
      case AuthStatus.ok:
        context.go('/home');
      case AuthStatus.mfaRequired:
        setState(() => _mfaRequired = true);
        _snack('Enter your 6-digit authenticator code');
      case AuthStatus.mfaInvalid:
        _snack('Invalid authenticator code');
      default:
        _snack(res.message ?? 'Login failed');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.cardBgElevated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to keep tracking your money',
      children: [
        AuthTextField(
          controller: _emailController,
          label: 'Email address',
          hint: 'you@gmail.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _passwordController,
          label: 'Password',
          hint: '••••••••',
          icon: Icons.lock_outline,
          obscure: _obscure,
          onToggleObscure: () => setState(() => _obscure = !_obscure),
        ),

        // ── MFA field (revealed when account has MFA) ──────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: _mfaRequired
              ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: AuthTextField(
                    controller: _mfaController,
                    label: 'Authenticator code',
                    hint: '123456',
                    icon: Icons.shield_outlined,
                    keyboardType: TextInputType.number,
                  ),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push('/forgot-password'),
            child: const Text('Forgot password?',
                style: TextStyle(color: AppColors.primaryLight, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 8),

        GradientButton(
          label: _mfaRequired ? 'Verify & Sign In' : 'Sign In',
          loading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: 18),

        Center(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text("Don't have an account? ",
                  style: TextStyle(color: context.textSecondary, fontSize: 14)),
              GestureDetector(
                onTap: () => context.push('/signup'),
                child: const Text('Sign up',
                    style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ],
      footer: Column(
        children: [
          // Demo is available on every platform — including the Android APK.
          DemoButton(onPressed: _startDemo),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => context.go('/home'),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.textMuted,
                side: BorderSide(color: context.cardBorderColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Continue without login'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startDemo() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
    await DemoDataService.activateDemo();
    if (!mounted) return;
    Navigator.of(context).pop(); // close loader
    context.go('/home');
  }
}
