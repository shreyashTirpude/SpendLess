import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/auth/auth_models.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/otp_input.dart';

enum _Step { email, otp, reset }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _newPassword = TextEditingController();

  _Step _step = _Step.email;
  bool _loading = false;
  bool _obscure = true;
  String _otp = '';
  String? _demoOtp;
  PasswordStrength _strength = PasswordStrength.evaluate('');

  @override
  void dispose() {
    _email.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (_email.text.trim().isEmpty) return _snack('Enter your email');
    setState(() => _loading = true);
    final res = await ref.read(authProvider.notifier).requestReset(_email.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _demoOtp = res.demoOtp;
      _step = _Step.otp;
    });
    if (res.message != null) _snack(res.message!);
  }

  void _verifyOtpStep() {
    if (_otp.length != 6) return _snack('Enter the 6-digit code');
    setState(() => _step = _Step.reset);
  }

  Future<void> _resetPassword() async {
    if (!_strength.isAcceptable) return _snack('Choose a stronger password');
    setState(() => _loading = true);
    final res = await ref
        .read(authProvider.notifier)
        .confirmReset(_email.text, _otp, _newPassword.text);
    if (!mounted) return;
    setState(() => _loading = false);

    if (res.ok) {
      _snack('Password updated — please sign in');
      context.go('/auth');
    } else if (res.status == AuthStatus.otpExpired) {
      _snack('Code expired — request a new one');
      setState(() => _step = _Step.email);
    } else {
      _snack(res.message ?? 'Reset failed');
    }
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
      title: switch (_step) {
        _Step.email => 'Reset password',
        _Step.otp => 'Check your email',
        _Step.reset => 'New password',
      },
      subtitle: switch (_step) {
        _Step.email => "We'll send a 6-digit code to your email",
        _Step.otp => 'Enter the code we sent to ${_email.text.trim()}',
        _Step.reset => 'Choose a strong new password',
      },
      children: [
        if (_step == _Step.email) ..._emailStep(),
        if (_step == _Step.otp) ..._otpStep(),
        if (_step == _Step.reset) ..._resetStep(),
      ],
    );
  }

  List<Widget> _emailStep() => [
        AuthTextField(
          controller: _email,
          label: 'Email address',
          hint: 'you@gmail.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        GradientButton(
            label: 'Send Code', loading: _loading, onPressed: _requestOtp),
      ];

  List<Widget> _otpStep() => [
        OtpInput(
          onChanged: (v) => _otp = v,
          onCompleted: (v) => _otp = v,
        ),
        const SizedBox(height: 16),
        if (_demoOtp != null) _demoBanner(_demoOtp!),
        const SizedBox(height: 24),
        GradientButton(label: 'Verify Code', onPressed: _verifyOtpStep),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _loading ? null : _requestOtp,
            child: const Text('Resend code',
                style: TextStyle(color: AppColors.primaryLight)),
          ),
        ),
      ];

  List<Widget> _resetStep() => [
        AuthTextField(
          controller: _newPassword,
          label: 'New password',
          hint: 'Min 8 chars, 1 upper, 1 number, 1 symbol',
          icon: Icons.lock_outline,
          obscure: _obscure,
          onToggleObscure: () => setState(() => _obscure = !_obscure),
          onChanged: (v) =>
              setState(() => _strength = PasswordStrength.evaluate(v)),
        ),
        const SizedBox(height: 12),
        Text(_strength.label,
            style: TextStyle(
                color: _strength.isAcceptable
                    ? AppColors.success
                    : AppColors.warning,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        GradientButton(
            label: 'Update Password',
            loading: _loading,
            onPressed: _resetPassword),
      ];

  Widget _demoBanner(String otp) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0x337C3AED), Color(0x336366F1)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Text('🧪', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                  children: [
                    const TextSpan(text: 'Demo mode — your code is '),
                    TextSpan(
                        text: otp,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
