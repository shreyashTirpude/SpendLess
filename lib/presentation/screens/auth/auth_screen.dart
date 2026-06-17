import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController     = TextEditingController();
  bool _isSignUp    = false;
  bool _loading     = false;
  bool _obscure     = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _snack('Enter email and password');
      return;
    }
    setState(() => _loading = true);
    bool ok;
    if (_isSignUp) {
      ok = await ref.read(authProvider.notifier).signUpWithEmail(
            _nameController.text.trim(), email, password);
    } else {
      ok = await ref.read(authProvider.notifier).loginWithEmail(email, password);
    }
    if (mounted) setState(() => _loading = false);
    if (ok && mounted) {
      context.go('/home');
    } else if (mounted) {
      _snack(_isSignUp ? 'Sign-up failed — try a different email' : 'Login failed — check your credentials');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.surface),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SpendLens'),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────────────────
                    const SizedBox(height: 16),
                    Text(
                      _isSignUp ? 'Create account' : 'Welcome back',
                      style: AppTextStyles.headingMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isSignUp
                          ? 'Start tracking your expenses automatically'
                          : 'Sign in to continue',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 32),

                    // ── Name (sign-up only) ──────────────────────────────
                    if (_isSignUp) ...[
                      _label('Full name'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        style: AppTextStyles.bodyMedium,
                        decoration: const InputDecoration(
                          hintText: 'Shreyash Tirpude',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Email ────────────────────────────────────────────
                    _label('Email address'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: AppTextStyles.bodyMedium,
                      decoration: const InputDecoration(
                        hintText: 'you@gmail.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Password ─────────────────────────────────────────
                    _label('Password'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      style: AppTextStyles.bodyMedium,
                      decoration: InputDecoration(
                        hintText: _isSignUp ? 'Min 6 characters' : '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Submit button ────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                _isSignUp ? 'Create Account' : 'Login',
                                style: AppTextStyles.labelLarge,
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Toggle sign-up / login ────────────────────────────
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() {
                          _isSignUp = !_isSignUp;
                          _nameController.clear();
                        }),
                        child: Text(
                          _isSignUp
                              ? 'Already have an account? Login'
                              : "Don't have an account? Sign up",
                          style: TextStyle(color: AppColors.primary, fontSize: 14),
                        ),
                      ),
                    ),

                    // ── Info card ─────────────────────────────────────────
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Text('🔒', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Free forever · No credit card · Your data stays on your device',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Skip button ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  const Divider(color: AppColors.cardBorder),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => context.go('/home'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Continue without login'),
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

  Widget _label(String text) =>
      Text(text, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textMuted));
}
