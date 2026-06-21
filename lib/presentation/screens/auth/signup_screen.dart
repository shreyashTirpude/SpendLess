import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/auth/auth_models.dart';
import '../../../services/consent_service.dart';
import '../../../core/data/consent_agreement.dart';
import '../../providers/cache_provider.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/consent_checkbox.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  bool _consent = ConsentService.hasConsented;
  PasswordStrength _strength = PasswordStrength.evaluate('');

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) return _snack('Enter your name');
    if (!_strength.isAcceptable) {
      return _snack('Choose a stronger password');
    }
    if (!_consent) {
      return _snack('Please accept the Privacy Agreement to continue');
    }
    if (!ConsentService.hasConsented) {
      await ConsentService.accept(
          action: 'signup', agreementHash: ConsentAgreement.hash);
    }
    setState(() => _loading = true);
    final res = await ref.read(authProvider.notifier).signUp(
          _name.text.trim(),
          _email.text.trim(),
          _password.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);

    if (res.ok) {
      ref.read(transactionCacheProvider.notifier).bump(); // reflect clean state
      // Offer MFA setup right after signup
      final enable = await _askEnableMfa();
      if (!mounted) return;
      if (enable == true) {
        context.go('/mfa-setup');
      } else {
        context.go('/home');
      }
    } else {
      _snack(res.message ?? 'Sign-up failed');
    }
  }

  Future<bool?> _askEnableMfa() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Text('🛡️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Text('Secure your account',
              style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ]),
        content: Text(
          'Add two-factor authentication (2FA) with an authenticator app for '
          'enterprise-grade protection. You can also do this later in Settings.',
          style: TextStyle(color: context.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Skip for now',
                style: TextStyle(color: context.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enable 2FA'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.cardBgElevated),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: true,
      title: 'Create account',
      subtitle: 'Start tracking your spending automatically',
      children: [
        AuthTextField(
          controller: _name,
          label: 'Full name',
          hint: 'Shreyash Tirpude',
          icon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _email,
          label: 'Email address',
          hint: 'you@gmail.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _password,
          label: 'Password',
          hint: 'Min 8 chars, 1 upper, 1 number, 1 symbol',
          icon: Icons.lock_outline,
          obscure: _obscure,
          onToggleObscure: () => setState(() => _obscure = !_obscure),
          onChanged: (v) =>
              setState(() => _strength = PasswordStrength.evaluate(v)),
        ),
        const SizedBox(height: 12),
        _StrengthMeter(strength: _strength),
        const SizedBox(height: 18),
        ConsentCheckbox(
          value: _consent,
          onChanged: (v) => setState(() => _consent = v),
        ),
        const SizedBox(height: 22),
        GradientButton(
          label: 'Create Account',
          loading: _loading,
          onPressed: _submit,
        ),
      ],
      footer: Center(
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Already have an account? ',
                style: TextStyle(color: context.textSecondary, fontSize: 14)),
            GestureDetector(
              onTap: () => context.pop(),
              child: const Text('Sign in',
                  style: TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  final PasswordStrength strength;
  const _StrengthMeter({required this.strength});

  Color get _color => switch (strength.score) {
        0 || 1 => AppColors.error,
        2 => AppColors.warning,
        3 => AppColors.primaryLight,
        _ => AppColors.success,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            final active = i < strength.score;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 5,
                margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                decoration: BoxDecoration(
                  color: active ? _color : context.cardBorderColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(strength.label,
                style: TextStyle(
                    color: _color, fontSize: 12, fontWeight: FontWeight.w600)),
            if (strength.unmet.isNotEmpty)
              Flexible(
                child: Text('Need: ${strength.unmet.first}',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: context.textMuted, fontSize: 11)),
              ),
          ],
        ),
      ],
    );
  }
}
