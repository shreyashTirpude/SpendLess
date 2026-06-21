import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/auth/auth_service.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/auth/otp_input.dart';

class MfaSetupScreen extends ConsumerStatefulWidget {
  const MfaSetupScreen({super.key});

  @override
  ConsumerState<MfaSetupScreen> createState() => _MfaSetupScreenState();
}

class _MfaSetupScreenState extends ConsumerState<MfaSetupScreen> {
  late final String _secret;
  late final String _uri;
  String _code = '';
  bool _loading = false;
  List<String>? _recoveryCodes;

  @override
  void initState() {
    super.initState();
    final email = AuthService.currentUser?.email ?? 'user@spendlens.app';
    final setup = AuthService.beginMfaSetup(email);
    _secret = setup.secret;
    _uri = setup.uri;
  }

  Future<void> _verify() async {
    if (_code.length != 6) return _snack('Enter the 6-digit code');
    final email = AuthService.currentUser?.email;
    if (email == null) return _snack('Not signed in');

    setState(() => _loading = true);
    final res = await AuthService.confirmMfaSetup(
        email: email, secret: _secret, code: _code);
    if (!mounted) return;
    setState(() => _loading = false);

    if (res.ok) {
      setState(() => _recoveryCodes = res.recoveryCodes);
      ref.read(authProvider.notifier).refresh();
    } else {
      _snack('Code did not match — check your authenticator app');
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
    if (_recoveryCodes != null) return _recoveryView();

    return AuthScaffold(
      showBack: true,
      title: 'Set up 2FA',
      subtitle: 'Add a code from your authenticator app',
      children: [
        _stepCard(
          '1',
          'Open your authenticator',
          'Google Authenticator, Authy, 1Password, or Microsoft Authenticator.',
        ),
        const SizedBox(height: 12),
        _stepCard(
          '2',
          'Add this secret key',
          'Tap to copy, then paste into your app as a new account.',
          child: _secretBox(),
        ),
        const SizedBox(height: 12),
        _stepCard(
          '3',
          'Enter the 6-digit code',
          'Your app generates a new code every 30 seconds.',
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OtpInput(
              autofocus: false,
              onChanged: (v) => _code = v,
              onCompleted: (v) => _code = v,
            ),
          ),
        ),
        const SizedBox(height: 24),
        GradientButton(
            label: 'Verify & Enable', loading: _loading, onPressed: _verify),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => context.go('/home'),
            child: Text('Skip for now',
                style: TextStyle(color: context.textMuted)),
          ),
        ),
      ],
    );
  }

  Widget _secretBox() => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: _secret));
            _snack('Secret key copied');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: context.bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.cardBorderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _secret,
                    style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        fontFamily: 'monospace'),
                  ),
                ),
                const Icon(Icons.copy_rounded,
                    size: 18, color: AppColors.primaryLight),
              ],
            ),
          ),
        ),
      );

  Widget _stepCard(String n, String title, String body, {Widget? child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientMid]),
                  shape: BoxShape.circle,
                ),
                child: Center(
                    child: Text(n,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(body,
                        style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12.5,
                            height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          if (child != null) child,
        ],
      ),
    );
  }

  // ── Recovery codes view ─────────────────────────────────────────────────────

  Widget _recoveryView() {
    return AuthScaffold(
      title: 'Save your recovery codes',
      subtitle: 'Use these if you lose access to your authenticator',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warningBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Each code works once. Store them somewhere safe — they won\'t be shown again.',
                  style: TextStyle(color: context.textSecondary, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.cardBorderColor),
          ),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: _recoveryCodes!
                .map((c) => Center(
                      child: Text(c,
                          style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                              letterSpacing: 1)),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy all codes'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryLight,
              side: BorderSide(color: context.cardBorderColor),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Clipboard.setData(
                  ClipboardData(text: _recoveryCodes!.join('\n')));
              _snack('Recovery codes copied');
            },
          ),
        ),
        const SizedBox(height: 12),
        GradientButton(
            label: "I've saved them — Continue",
            onPressed: () => context.go('/home')),
      ],
    );
  }
}
