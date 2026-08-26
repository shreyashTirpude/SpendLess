import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/local/hive_service.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _termsScrollController = ScrollController();
  final _privacyScrollController = ScrollController();

  bool _termsScrolled = false;
  bool _privacyScrolled = false;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _termsScrollController.addListener(_onTermsScroll);
    _privacyScrollController.addListener(_onPrivacyScroll);
  }

  void _onTermsScroll() {
    if (!_termsScrolled) {
      final pos = _termsScrollController.position;
      if (pos.maxScrollExtent == 0 || pos.pixels >= pos.maxScrollExtent - 80) {
        setState(() => _termsScrolled = true);
      }
    }
  }

  void _onPrivacyScroll() {
    if (!_privacyScrolled) {
      final pos = _privacyScrollController.position;
      if (pos.maxScrollExtent == 0 || pos.pixels >= pos.maxScrollExtent - 80) {
        setState(() => _privacyScrolled = true);
      }
    }
  }

  bool get _canAgree => _termsScrolled && _privacyScrolled;

  Future<void> _agree() async {
    setState(() => _accepting = true);
    try {
      await HiveService.settings.put('termsAccepted', true);
      if (!mounted) return;
      final isOnboarded =
          HiveService.settings.get('isOnboarded', defaultValue: false) as bool;
      context.go(isOnboarded ? '/home' : '/onboarding');
    } catch (_) {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _termsScrollController.removeListener(_onTermsScroll);
    _privacyScrollController.removeListener(_onPrivacyScroll);
    _termsScrollController.dispose();
    _privacyScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor:
          isDark ? AppColors.background : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardBg : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? AppColors.cardBorder
                        : const Color(0xFFE5E7EB),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('💸',
                              style: TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SpendLens',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                          ),
                          Text(
                            'Before you start',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: isDark
                                      ? AppColors.textMuted
                                      : const Color(0xFF6B7280),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please read and accept our Terms & Conditions and Privacy Policy to continue. Scroll to the bottom of each tab to unlock the Agree button.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textMuted
                              : const Color(0xFF6B7280),
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),

            // ── Tab bar ───────────────────────────────────────────────
            Container(
              color: isDark ? AppColors.cardBg : Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor:
                    isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
                indicatorColor: AppColors.primary,
                indicatorWeight: 2.5,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _termsScrolled
                              ? Icons.check_circle_rounded
                              : Icons.article_outlined,
                          size: 16,
                          color: _termsScrolled
                              ? AppColors.success
                              : null,
                        ),
                        const SizedBox(width: 6),
                        const Text('Terms', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _privacyScrolled
                              ? Icons.check_circle_rounded
                              : Icons.privacy_tip_outlined,
                          size: 16,
                          color: _privacyScrolled
                              ? AppColors.success
                              : null,
                        ),
                        const SizedBox(width: 6),
                        const Text('Privacy', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab content ───────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _LegalDocument(
                    controller: _termsScrollController,
                    sections: _termsSections,
                    isDark: isDark,
                  ),
                  _LegalDocument(
                    controller: _privacyScrollController,
                    sections: _privacySections,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            // ── Footer / CTA ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardBg : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.cardBorder
                        : const Color(0xFFE5E7EB),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_canAgree)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 13,
                              color: isDark
                                  ? AppColors.textMuted
                                  : const Color(0xFF9CA3AF)),
                          const SizedBox(width: 5),
                          Text(
                            'Scroll to the bottom of both tabs to continue',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textMuted
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: ElevatedButton(
                        onPressed:
                            (_canAgree && !_accepting) ? _agree : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: isDark
                              ? const Color(0xFF374151)
                              : const Color(0xFFE5E7EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: _canAgree ? 4 : 0,
                        ),
                        child: _accepting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _canAgree
                                    ? '✓  I Agree — Let\'s Start'
                                    : 'Read both documents to continue',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _canAgree
                                      ? Colors.white
                                      : (isDark
                                          ? AppColors.textMuted
                                          : const Color(0xFF9CA3AF)),
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By agreeing you confirm you are 18+ years old. Free forever · No cloud upload · DPDP Act 2023 compliant',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.textMuted
                          : const Color(0xFF9CA3AF),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}

// ── Scrollable legal document ────────────────────────────────────────────────

class _LegalDocument extends StatelessWidget {
  final ScrollController controller;
  final List<_Section> sections;
  final bool isDark;

  const _LegalDocument({
    required this.controller,
    required this.sections,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      itemCount: sections.length,
      itemBuilder: (context, i) {
        final s = sections[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (s.title.isNotEmpty) ...[
                Text(
                  s.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                s.body,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFFD1D5DB)
                      : const Color(0xFF374151),
                  height: 1.6,
                ),
              ),
              if (s.bullets.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...s.bullets.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        Expanded(
                          child: Text(
                            b,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFFD1D5DB)
                                  : const Color(0xFF374151),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (s.isHighlight)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    s.highlightText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Section {
  final String title;
  final String body;
  final List<String> bullets;
  final bool isHighlight;
  final String highlightText;

  const _Section({
    this.title = '',
    this.body = '',
    this.bullets = const [],
    this.isHighlight = false,
    this.highlightText = '',
  });
}

// ── Terms & Conditions content ───────────────────────────────────────────────

const _termsSections = [
  _Section(
    title: 'Terms & Conditions',
    body: 'SpendLens — Personal Finance Tracker\nEffective Date: June 17, 2026',
    isHighlight: true,
    highlightText:
        'By tapping "I Agree," you confirm that you have read, understood, and agree to be bound by these Terms. If you do not agree, do not use the app.',
  ),
  _Section(
    title: '1. About SpendLens',
    body:
        'SpendLens is a personal expense tracking application designed for Android devices in India. It reads your bank SMS messages to automatically detect and categorize your financial transactions, helping you understand your spending habits. All processing and storage happens entirely on your device.',
  ),
  _Section(
    title: '2. SMS Permission',
    body: 'SpendLens requests permission to read your SMS messages solely to detect bank transaction alerts. This includes:',
    bullets: [
      'Identifying transaction amounts (debits and credits)',
      'Identifying merchant or payee names',
      'Identifying transaction dates and times',
      'Identifying your bank account or card (partially masked)',
    ],
  ),
  _Section(
    title: '2b. What We Do NOT Do',
    body: '',
    bullets: [
      'Read personal, social, or non-bank SMS messages',
      'Store the raw text of any SMS message',
      'Share any SMS content with any third party',
      'Upload any SMS data to any server or cloud',
    ],
    isHighlight: true,
    highlightText:
        'Non-financial SMS messages are discarded immediately and never recorded.',
  ),
  _Section(
    title: '3. Local-Only Storage',
    body:
        'All data generated or collected by SpendLens is stored exclusively on your device using AES-256 encryption. SpendLens has no servers, no cloud backend, and no internet connectivity. Your financial data never leaves your device.',
  ),
  _Section(
    title: '4. Not Financial Advice',
    body:
        'SpendLens is an expense tracking tool only. Nothing in the app constitutes financial, investment, tax, or legal advice. Spending summaries, budgets, and analytics are informational only. Always consult a qualified financial advisor before making financial decisions.',
    isHighlight: true,
    highlightText: '⚠️ Not financial advice. Informational use only.',
  ),
  _Section(
    title: '5. User Responsibilities',
    body: 'You agree to:',
    bullets: [
      'Use SpendLens only for your own personal, non-commercial use',
      'Not attempt to reverse-engineer, decompile, or tamper with the app',
      'Keep your device secure, as all app data is stored locally on your device',
    ],
  ),
  _Section(
    title: '6. Limitation of Liability',
    body: 'To the fullest extent permitted by applicable Indian law, SpendLens and its developers shall not be liable for:',
    bullets: [
      'Any inaccuracy in transaction detection or categorization',
      'Any loss of data due to device loss, damage, factory reset, or uninstallation',
      'Any financial decisions made based on information displayed in the app',
      'Any indirect, incidental, or consequential damages arising from app use',
    ],
    isHighlight: true,
    highlightText:
        'Total liability is limited to INR 0, as SpendLens is provided free of charge.',
  ),
  _Section(
    title: '7. Intellectual Property',
    body:
        'All app design, code, and content are the property of SpendLens. You may not copy, reproduce, or distribute any part of the app without prior written permission.',
  ),
  _Section(
    title: '8. Changes to Terms',
    body:
        'We may update these Terms from time to time. If we make material changes, you will be prompted to review and re-accept them on next app launch.',
  ),
  _Section(
    title: '9. Governing Law',
    body:
        'These Terms are governed by the laws of India. Any disputes shall be subject to the exclusive jurisdiction of the courts of India.',
  ),
  _Section(
    title: '10. Contact',
    body: 'For any questions, concerns, or legal queries:\n\nEmail: tshreyash2002@gmail.com',
    isHighlight: true,
    highlightText: '✅ You have read the full Terms & Conditions.',
  ),
];

// ── Privacy Policy content ───────────────────────────────────────────────────

const _privacySections = [
  _Section(
    title: 'Privacy Policy',
    body: 'SpendLens — Personal Finance Tracker\nEffective Date: June 17, 2026',
    isHighlight: true,
    highlightText:
        'Your financial data belongs to you and stays on your device. We collect no personal data on any server. We have no servers.',
  ),
  _Section(
    title: '1. Compliance',
    body:
        'This Privacy Policy is drafted in accordance with India\'s Digital Personal Data Protection (DPDP) Act, 2023. By using SpendLens, you act as the Data Principal and grant consent to local on-device processing as described below.',
  ),
  _Section(
    title: '2. Data We Process (On-Device Only)',
    body: 'When you grant SMS permission, SpendLens scans bank SMS messages to extract:',
    bullets: [
      'Transaction amount (debit/credit) — to log your expense or income',
      'Merchant or payee name — to categorize the transaction',
      'Transaction date and time — for timeline and reports',
      'Partial account/card reference — to match the right account',
    ],
    isHighlight: true,
    highlightText:
        '🔒 Raw SMS text is NEVER stored. The app extracts only the above fields and immediately discards the full message text.',
  ),
  _Section(
    title: '3. User-Provided Data',
    body: 'Information you manually enter in the app:',
    bullets: [
      'Your name (optional) — to personalize the home screen',
      'Monthly income (optional) — for budget calculations',
      'Manual transactions (optional) — transactions you add yourself',
    ],
  ),
  _Section(
    title: '4. Data We Do NOT Collect',
    body: '',
    bullets: [
      'Raw SMS message text or content',
      'Personal, social, OTP, or promotional SMS messages',
      'Location data',
      'Contact list',
      'Device identifiers (IMEI, Android ID, etc.)',
      'Photos, files, or any other device content',
      'Browsing history or app usage patterns',
      'Any data through the internet (the app has no internet access)',
    ],
  ),
  _Section(
    title: '5. Where Data is Stored',
    body:
        'Everything is stored locally on your device only, in an AES-256 encrypted Hive database. The encryption key is generated on your device and never transmitted anywhere. No data is sent to any server, cloud service, analytics platform, or third party — ever.',
    isHighlight: true,
    highlightText: '📵 No internet. No server. No cloud. Ever.',
  ),
  _Section(
    title: '6. Data Sharing',
    body:
        'We do not share, sell, rent, or disclose your data to any third party. There are no third-party SDKs (analytics, advertising, crash reporting) in SpendLens.',
  ),
  _Section(
    title: '7. Your Rights Under DPDP Act 2023',
    body: 'As a Data Principal under the DPDP Act, you have these rights — all exercisable directly within the app:',
    bullets: [
      'Right to access — View all your data in the app at any time',
      'Right to correction — Edit any transaction or profile detail in Settings',
      'Right to erasure — Settings > Delete All Data — permanently wipes all app data',
      'Right to withdraw consent — Revoke SMS permission via Android Settings > Apps > SpendLens > Permissions',
    ],
    isHighlight: true,
    highlightText:
        'Deleting all data or uninstalling the app removes all information completely and irreversibly, as no copy exists elsewhere.',
  ),
  _Section(
    title: '8. Children\'s Privacy',
    body:
        'SpendLens is not intended for use by persons under 18 years of age. We do not knowingly process data from minors.',
  ),
  _Section(
    title: '9. Data Breach',
    body:
        'Since all data is stored only on your device and we have no servers, a data breach on our end is not possible. If your device is lost or compromised, your data is protected by AES-256 encryption.',
  ),
  _Section(
    title: '10. Contact & Grievance Officer',
    body:
        'For privacy-related questions, requests, or grievances under the DPDP Act 2023:\n\nEmail: tshreyash2002@gmail.com\nResponse time: Within 72 hours',
    isHighlight: true,
    highlightText: '✅ You have read the full Privacy Policy.',
  ),
];
