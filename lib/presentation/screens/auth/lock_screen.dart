import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/security/security_service.dart';
import '../../../services/password_service.dart';
import '../../../data/local/hive_service.dart';
import '../../../services/biometric_service.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  final _biometrics = BiometricService();
  bool _biometricAvailable = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
    _focusNode.addListener(_onFocusChange);
    // Offer biometric unlock (and auto-prompt) when the user enabled it in
    // Settings. Password entry always remains available as the fallback.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBiometrics());
  }

  Future<void> _checkBiometrics() async {
    final enabled =
        HiveService.settings.get('biometricEnabled', defaultValue: false) as bool;
    if (!enabled) return;
    final available = await _biometrics.isAvailable();
    if (!mounted) return;
    setState(() => _biometricAvailable = available);
    if (!available) return;
    final ok = await _biometrics.authenticate();
    if (!mounted || !ok) return;
    context.go('/home');
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // Scroll to show the Unlock button after keyboard animation completes
      Future.delayed(const Duration(milliseconds: 350), () {
        if (_scrollCtrl.hasClients && mounted) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final pw = _controller.text.trim();
    if (pw.isEmpty) {
      setState(() => _error = 'Enter your password');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await PasswordService.verifyPassword(pw);
    if (!mounted) return;
    if (ok) {
      context.go('/home');
    } else {
      _controller.clear();
      _shakeCtrl.forward(from: 0);
      setState(() {
        _loading = false;
        _error = 'Incorrect password';
      });
    }
  }

  Future<void> _showForgotDialog() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ForgotPasswordSheet(ctx: ctx),
    );
    if (choice == null || !mounted) return;

    if (choice == 'recovery') {
      await _showRecoveryKeyDialog();
    } else if (choice == 'wipe') {
      await _confirmWipeAndReset();
    }
  }

  Future<void> _showRecoveryKeyDialog() async {
    final keyCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Enter Recovery Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the 8-character recovery key shown when you set your password.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: keyCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'XXXX-XXXX',
                prefixIcon: Icon(Icons.vpn_key_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    final valid = await SecurityService.verifyRecoveryKey(keyCtrl.text);
    if (!mounted) return;

    if (valid) {
      await _showSetNewPasswordDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid recovery key. Try again or use "Clear All Data".'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showSetNewPasswordDialog() async {
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Set New Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newCtrl,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Set Password'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    if (newCtrl.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 4 characters')),
      );
      return;
    }
    if (newCtrl.text != confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    await PasswordService.setPassword(newCtrl.text);
    await SecurityService.clearRecoveryKey(); // old key invalidated
    if (!mounted) return;
    context.go('/home');
  }

  Future<void> _confirmWipeAndReset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all transactions and data. Cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await PasswordService.clearPassword();
    await SecurityService.clearRecoveryKey();
    await HiveService.transactions.clear();
    await HiveService.budgets.clear();
    await HiveService.settings.put('appLockEnabled', false);
    await HiveService.settings.put('biometricEnabled', false);
    if (!mounted) return;
    context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      child: _buildContent(context, isDark),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0F) : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollCtrl,
          padding: EdgeInsets.fromLTRB(
            32,
            MediaQuery.of(context).size.height * 0.12,
            32,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('💸', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 12),
              Text(
                'SpendLens',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your password to continue',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: context.textMuted),
              ),
              const SizedBox(height: 48),
              AnimatedBuilder(
                animation: _shakeAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(_shakeAnim.value * ((_shakeCtrl.value < 0.5) ? 1 : -1), 0),
                  child: child,
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  obscureText: _obscure,
                  autofocus: true,
                  onSubmitted: (_) => _unlock(),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    errorText: _error,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _unlock,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Unlock', style: TextStyle(fontSize: 16)),
                ),
              ),
              if (_biometricAvailable) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _loading ? null : _checkBiometrics,
                  icon: const Icon(Icons.fingerprint_rounded, size: 20),
                  label: const Text(
                    'Unlock with biometrics',
                    style: TextStyle(color: AppColors.primary, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: _showForgotDialog,
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(color: AppColors.primary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Forgot password options sheet ─────────────────────────────────────────────

class _ForgotPasswordSheet extends StatelessWidget {
  final BuildContext ctx;
  const _ForgotPasswordSheet({required this.ctx});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: context.cardBorderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Forgot Password?',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Choose a recovery method',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted),
          ),
          const SizedBox(height: 24),
          _RecoveryOption(
            icon: '🔑',
            title: 'Use Recovery Key',
            subtitle: 'Enter the 8-char key shown when you set your password',
            onTap: () => Navigator.pop(ctx, 'recovery'),
          ),
          const SizedBox(height: 10),
          _RecoveryOption(
            icon: '🗑️',
            title: 'Clear All Data',
            subtitle: 'Delete everything and start fresh — cannot be undone',
            isDestructive: true,
            onTap: () => Navigator.pop(ctx, 'wipe'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _RecoveryOption extends StatelessWidget {
  final String icon, title, subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  const _RecoveryOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDestructive
                ? AppColors.error.withValues(alpha: 0.3)
                : context.cardBorderColor,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isDestructive ? AppColors.error : null,
                        ),
                  ),
                  Text(subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: context.textMuted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: isDestructive ? AppColors.error : context.textMuted),
          ],
        ),
      ),
    );
  }
}
