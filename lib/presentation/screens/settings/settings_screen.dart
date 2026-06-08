import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/security/security_service.dart';
import '../../../data/local/hive_service.dart';
import '../../../services/password_service.dart';
import '../../../services/sms_scanner_service.dart';
import '../../providers/theme_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/cache_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final profile = ref.watch(userProfileProvider);
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Manage your preferences',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted),
            ),
            const SizedBox(height: 24),

            // ── Appearance ──────────────────────────────────────────────────
            _SectionLabel(label: 'Appearance'),
            _ToggleTile(
              icon: isDark ? '🌙' : '☀️',
              title: 'Dark Mode',
              subtitle: isDark ? 'Switch to light theme' : 'Switch to dark theme',
              value: isDark,
              onChanged: (_) async => ref.read(themeModeProvider.notifier).toggle(),
            ),
            const SizedBox(height: 20),

            // ── Profile ─────────────────────────────────────────────────────
            _SectionLabel(label: 'Profile'),
            _ActionTile(
              icon: '👤',
              title: 'Name',
              subtitle: profile?.name?.isNotEmpty == true ? profile!.name! : 'Tap to set your name',
              onTap: () => _showEditDialog(
                context,
                ref,
                title: 'Your Name',
                hint: 'Enter your name',
                initial: profile?.name ?? '',
                onSave: (v) => ref.read(userProfileProvider.notifier).updateName(v),
              ),
            ),
            _ActionTile(
              icon: '📱',
              title: 'Phone',
              subtitle: profile?.phone.isNotEmpty == true ? profile!.phone : 'Tap to set phone',
              onTap: () => _showEditDialog(
                context,
                ref,
                title: 'Phone Number',
                hint: '+91 98765 43210',
                initial: profile?.phone ?? '',
                keyboardType: TextInputType.phone,
                onSave: (v) => ref.read(userProfileProvider.notifier).updatePhone(v),
              ),
            ),
            _ActionTile(
              icon: '📅',
              title: 'Salary Payday',
              subtitle: () {
                final day = HiveService.settings.get('salaryDay', defaultValue: 1) as int;
                return 'Day $day of every month — used for Safe-to-Spend';
              }(),
              onTap: () => _showEditDialog(
                context,
                ref,
                title: 'Salary Payday (1–31)',
                hint: 'e.g. 27',
                initial: (HiveService.settings.get('salaryDay', defaultValue: 1) as int).toString(),
                keyboardType: TextInputType.number,
                onSave: (v) async {
                  final day = int.tryParse(v.trim()) ?? 1;
                  await HiveService.settings.put('salaryDay', day.clamp(1, 31));
                  ref.invalidate(homeStatsProvider);
                },
              ),
            ),
            const SizedBox(height: 20),

            // ── Security ────────────────────────────────────────────────────
            _SectionLabel(label: 'Security'),
            _ActionTile(
              icon: '🔑',
              title: 'App Password',
              subtitle: settings.appLockEnabled
                  ? 'Password lock enabled — tap to change or remove'
                  : 'Set a password to lock the app on startup',
              onTap: () => _showPasswordDialog(context, ref, settings.appLockEnabled),
              trailing: settings.appLockEnabled
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ON',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            ),
            if (settings.appLockEnabled)
              _ActionTile(
                icon: '🔒',
                title: 'Lock App Now',
                subtitle: 'Go to lock screen immediately',
                onTap: () => context.go('/lock'),
              ),
            _ActionTile(
              icon: '🚪',
              title: 'Logout',
              subtitle: 'Sign out and return to onboarding',
              onTap: () => _confirmLogout(context, ref),
              isDestructive: true,
            ),
            const SizedBox(height: 20),

            // ── Notifications ────────────────────────────────────────────────
            _SectionLabel(label: 'Notifications'),
            _ToggleTile(
              icon: '🔔',
              title: 'Transaction Alerts',
              subtitle: 'Get notified on new auto-tracked transactions',
              value: settings.transactionAlerts,
              onChanged: (_) => ref.read(appSettingsProvider.notifier).toggle('transactionAlerts'),
            ),
            _ToggleTile(
              icon: '⚠️',
              title: 'Budget Alerts',
              subtitle: 'Alert when approaching spending limits',
              value: settings.budgetAlerts,
              onChanged: (_) => ref.read(appSettingsProvider.notifier).toggle('budgetAlerts'),
            ),
            _ToggleTile(
              icon: '📊',
              title: 'Weekly Reports',
              subtitle: 'Every Monday — spending snapshot summary',
              value: settings.weeklyReports,
              onChanged: (_) => ref.read(appSettingsProvider.notifier).toggle('weeklyReports'),
            ),
            const SizedBox(height: 20),

            // ── Data ─────────────────────────────────────────────────────────
            _SectionLabel(label: 'Data'),
            _ActionTile(
              icon: '📤',
              title: 'Export to CSV',
              subtitle: 'Copy all transactions as CSV text',
              onTap: () => _exportCsv(context, ref),
            ),
            _ActionTile(
              icon: '🔄',
              title: 'Re-scan SMS Inbox',
              subtitle: 'Re-parse last 6 months of bank messages',
              onTap: () => _rescanSms(context, ref),
            ),
            _ActionTile(
              icon: '🗑️',
              title: 'Clear All Data',
              subtitle: 'Permanently delete all transactions & budgets',
              onTap: () => _confirmClearData(context, ref),
              isDestructive: true,
            ),
            const SizedBox(height: 20),

            // ── About ─────────────────────────────────────────────────────────
            _SectionLabel(label: 'About'),
            _ActionTile(
              icon: 'ℹ️',
              title: 'SpendLens',
              subtitle: 'Version 1.0.0 · Built with Flutter',
              onTap: () {},
            ),
            _ActionTile(
              icon: '⭐',
              title: 'Rate the App',
              subtitle: 'Enjoying SpendLens? Leave a review!',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening Play Store…')),
                );
              },
            ),
            _ActionTile(
              icon: '💬',
              title: 'Send Feedback',
              subtitle: 'tshreyash2002@gmail.com',
              onTap: () {
                Clipboard.setData(const ClipboardData(text: 'tshreyash2002@gmail.com'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email copied to clipboard')),
                );
              },
            ),
            const _PrivacyManifestCard(),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String hint,
    required String initial,
    required Future<void> Function(String) onSave,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final controller = TextEditingController(text: initial);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: keyboardType,
                autofocus: true,
                decoration: InputDecoration(hintText: hint),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await onSave(controller.text);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPasswordDialog(BuildContext context, WidgetRef ref, bool hasLock) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PasswordSheet(hasLock: hasLock, ref: ref),
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final txns = HiveService.transactions.values.toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    if (txns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Date,Merchant,Category,Amount,Type,Account');
    for (final t in txns) {
      final date = DateFormat('yyyy-MM-dd').format(t.transactionDate);
      final type = t.isCredit ? 'Credit' : 'Debit';
      final acct = t.accountLast4 ?? '';
      buffer.writeln('$date,"${t.merchant}","${t.category}",${t.amount},$type,$acct');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${txns.length} transactions copied as CSV — paste into any spreadsheet'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _rescanSms(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Re-scanning SMS inbox…')),
    );
    final added = await SmsScannerService.scanInbox();
    if (added > 0) {
      ref.read(transactionCacheProvider.notifier).bump();
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(added > 0
              ? 'Added $added new transaction${added != 1 ? 's' : ''} from SMS'
              : 'No new transactions found'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _confirmClearData(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear All Data?', style: Theme.of(context).textTheme.headlineSmall),
        content: Text(
          'This will permanently delete all transactions, budgets, and settings. This cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: context.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await HiveService.transactions.clear();
    await HiveService.budgets.clear();
    ref.read(transactionCacheProvider.notifier).bump();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared')),
      );
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout?', style: Theme.of(context).textTheme.headlineSmall),
        content: Text(
          'Your data will remain on this device. You will be taken back to the welcome screen.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: context.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;
    await HiveService.settings.put('isOnboarded', false);
    await PasswordService.clearPassword();
    await ref.read(appSettingsProvider.notifier).setAppLock(false);
    if (context.mounted) context.go('/onboarding');
  }
}

// ─── Password Bottom Sheet ────────────────────────────────────────────────────

class _PasswordSheet extends StatefulWidget {
  final bool hasLock;
  final WidgetRef ref;
  const _PasswordSheet({required this.hasLock, required this.ref});

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() { _error = null; _loading = true; });

    if (widget.hasLock) {
      final ok = await PasswordService.verifyPassword(_currentCtrl.text);
      if (!ok) {
        setState(() { _error = 'Current password is incorrect'; _loading = false; });
        return;
      }
    }

    final newPw = _newCtrl.text;
    if (newPw.length < 4) {
      setState(() { _error = 'Password must be at least 4 characters'; _loading = false; });
      return;
    }
    if (newPw != _confirmCtrl.text) {
      setState(() { _error = 'Passwords do not match'; _loading = false; });
      return;
    }

    await PasswordService.setPassword(newPw);
    await widget.ref.read(appSettingsProvider.notifier).setAppLock(true);

    // Generate recovery key only on first-time setup (not when changing)
    if (!widget.hasLock && mounted) {
      final recoveryKey = await SecurityService.generateAndStoreRecoveryKey();
      if (!mounted) return;
      Navigator.pop(context);
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Save Your Recovery Key'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Store this key safely. If you forget your password, '
                'use this to reset it without losing data.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    recoveryKey,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: AppColors.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy Key'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: recoveryKey));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Recovery key copied')),
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('I\'ve saved it'),
            ),
          ],
        ),
      );
    } else if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
    }
  }

  Future<void> _remove() async {
    setState(() { _error = null; _loading = true; });
    final ok = await PasswordService.verifyPassword(_currentCtrl.text);
    if (!ok) {
      setState(() { _error = 'Current password is incorrect'; _loading = false; });
      return;
    }
    await PasswordService.clearPassword();
    await widget.ref.read(appSettingsProvider.notifier).setAppLock(false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App password removed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Text(
                widget.hasLock ? 'Change Password' : 'Set App Password',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                widget.hasLock
                    ? 'Enter your current password, then the new one.'
                    : 'Your app will require this password on every launch.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted),
              ),
              const SizedBox(height: 20),

              if (widget.hasLock) ...[
                _PasswordField(
                  controller: _currentCtrl,
                  label: 'Current Password',
                  obscure: _obscureCurrent,
                  onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
                const SizedBox(height: 12),
              ],

              _PasswordField(
                controller: _newCtrl,
                label: 'New Password',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 12),
              _PasswordField(
                controller: _confirmCtrl,
                label: 'Confirm New Password',
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),

              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(widget.hasLock ? 'Update Password' : 'Set Password'),
                ),
              ),

              if (widget.hasLock) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _remove,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Remove Password'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.textMuted,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final Widget? trailing;
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.cardBorderColor),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
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
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!
            else Icon(Icons.chevron_right_rounded, color: context.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _PrivacyPoint extends StatelessWidget {
  final String icon, title, body;
  final BuildContext context;
  const _PrivacyPoint({required this.icon, required this.title, required this.body, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(body,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyManifestCard extends StatelessWidget {
  const _PrivacyManifestCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.primary.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Text('🛡️', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacy First — Zero Leakage',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'SpendLens never uploads your data. Everything stays on your device, encrypted.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Data manifest
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ManifestHeader(label: 'What IS stored', color: AppColors.success),
                const SizedBox(height: 8),
                const _ManifestRow(icon: '💰', text: 'Transaction amount (e.g. ₹250.00)'),
                const _ManifestRow(icon: '🏪', text: 'Merchant name (e.g. Swiggy, Amazon)'),
                const _ManifestRow(icon: '📅', text: 'Date and time of the transaction'),
                const _ManifestRow(icon: '🏷️', text: 'Auto-detected category (Food, Travel…)'),
                const SizedBox(height: 14),
                _ManifestHeader(label: 'What is NOT stored', color: AppColors.error),
                const SizedBox(height: 8),
                const _ManifestRow(icon: '🚫', text: 'Raw SMS text or full message body', negative: true),
                const _ManifestRow(icon: '🚫', text: 'Account numbers or card details', negative: true),
                const _ManifestRow(icon: '🚫', text: 'Your name or personal contact info', negative: true),
                const _ManifestRow(icon: '🚫', text: 'Any data uploaded to the internet', negative: true),
              ],
            ),
          ),

          // Encryption badge
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Text('🔐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AES-256 encryption via Android Keystore — same standard used by banks.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManifestHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _ManifestHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _ManifestRow extends StatelessWidget {
  final String icon;
  final String text;
  final bool negative;
  const _ManifestRow({required this.icon, required this.text, this.negative = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: negative ? context.textSecondary : context.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool value;
  final Future<void> Function(bool) onChanged;
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
