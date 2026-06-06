import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          Text('Profile', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          _buildSettingTile(
            icon: '👤',
            title: 'Name',
            subtitle: 'Shreyash Tirpude',
            onTap: () {},
          ),
          _buildSettingTile(
            icon: '📱',
            title: 'Phone',
            subtitle: '+91 98765 43210',
            onTap: () {},
          ),
          const SizedBox(height: 24),

          // Security Section
          Text('Security', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          _buildToggleTile(
            icon: '🔐',
            title: 'Biometric Lock',
            subtitle: 'Fingerprint authentication',
            value: true,
            onChanged: (val) {},
          ),
          const SizedBox(height: 24),

          // Notifications Section
          Text('Notifications', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          _buildToggleTile(
            icon: '🔔',
            title: 'Transaction Alerts',
            subtitle: 'Get notified on new transactions',
            value: true,
            onChanged: (val) {},
          ),
          _buildToggleTile(
            icon: '⚠️',
            title: 'Budget Alerts',
            subtitle: 'When approaching limits',
            value: true,
            onChanged: (val) {},
          ),
          _buildToggleTile(
            icon: '📧',
            title: 'Weekly Reports',
            subtitle: 'Every Sunday at 8 PM',
            value: true,
            onChanged: (val) {},
          ),
          const SizedBox(height: 24),

          // Data Section
          Text('Data', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          _buildSettingTile(
            icon: '📥',
            title: 'Export Data',
            subtitle: 'Download as CSV',
            onTap: () {},
          ),
          _buildSettingTile(
            icon: '🗑️',
            title: 'Clear Local Data',
            subtitle: 'Remove all stored transactions',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.cardBg,
                  title: const Text('Clear Data?'),
                  content: const Text('This will delete all local data permanently.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // App Section
          Text('App', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          _buildSettingTile(
            icon: '📋',
            title: 'Privacy Policy',
            subtitle: 'View our privacy commitment',
            onTap: () {},
          ),
          _buildSettingTile(
            icon: 'ℹ️',
            title: 'About',
            subtitle: 'Version 1.0.0',
            onTap: () {},
          ),
          _buildSettingTile(
            icon: '⭐',
            title: 'Rate App',
            subtitle: 'Love SpendLens? Rate us',
            onTap: () {},
          ),
          _buildSettingTile(
            icon: '💬',
            title: 'Contact Support',
            subtitle: 'support@spendlens.app',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelMedium),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelMedium),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
