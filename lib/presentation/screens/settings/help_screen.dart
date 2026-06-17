import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Help & Guide',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          _WelcomeBanner(),
          const SizedBox(height: 20),
          _Section(
            emoji: '🏠',
            title: 'Home Screen',
            color: const Color(0xFF6366F1),
            items: [
              _HelpItem(
                q: 'What is "Total Spent" or "Net Balance"?',
                a: 'It shows how much money you have spent this month. '
                    'If your salary or income was also detected from SMS, it shows "Net Balance" — '
                    'meaning money left after spending. If only expenses are tracked, it shows "Total Spent".',
              ),
              _HelpItem(
                q: 'What is "Safe to Spend"?',
                a: 'This is the amount you can safely spend each day for the rest of the month '
                    'without going over your income. It divides your remaining balance by the days left '
                    'in the month. If you see ₹500/day, that means spend ₹500 or less per day.',
              ),
              _HelpItem(
                q: 'What is the circular ring on the card?',
                a: 'The ring shows how much of your income you have already used. '
                    'Green = good, Orange = careful, Red = you have used most of your money.',
              ),
              _HelpItem(
                q: 'Why is income showing ₹0?',
                a: 'SpendLens reads your bank SMS messages. If your salary SMS was not sent '
                    'by your bank, or was sent before the app was installed, it won\'t appear. '
                    'You can set your salary day in Settings → Profile → Salary Payday so the '
                    'app can plan your spending cycle correctly.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            emoji: '📋',
            title: 'Transactions',
            color: const Color(0xFF10B981),
            items: [
              _HelpItem(
                q: 'How does SpendLens track my expenses?',
                a: 'It automatically reads SMS messages sent by your bank. '
                    'Every time you pay with UPI, card, or net banking, your bank sends an SMS. '
                    'SpendLens reads that SMS and records the expense for you — no manual entry needed.',
              ),
              _HelpItem(
                q: 'Why is a wrong amount shown for a transaction?',
                a: 'Sometimes the bank SMS contains both the transaction amount and the available balance. '
                    'SpendLens tries to pick the right one, but in rare cases it may pick the balance. '
                    'You can tap on any transaction and edit the amount manually.',
              ),
              _HelpItem(
                q: 'How do I delete or ignore a wrong transaction?',
                a: 'Swipe left on any transaction to delete it, or tap on it and mark it as "Ignored". '
                    'Ignored transactions are hidden from all totals and charts.',
              ),
              _HelpItem(
                q: 'Can I add a transaction manually?',
                a: 'Yes — tap the + button on the Transactions screen to add cash payments or '
                    'any expense that was not captured from SMS.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            emoji: '🎯',
            title: 'Budget',
            color: const Color(0xFFF59E0B),
            items: [
              _HelpItem(
                q: 'What is a Budget?',
                a: 'A budget is a spending limit you set for a category. '
                    'For example: "I want to spend only ₹3,000 on Food this month." '
                    'SpendLens then tracks if you are staying within that limit.',
              ),
              _HelpItem(
                q: 'How do I create a budget?',
                a: 'Go to the Budget tab → tap "Add Budget" → choose a category (like Food, Travel) '
                    '→ enter your limit amount. That\'s it! You\'ll see a ring showing how much you\'ve used.',
              ),
              _HelpItem(
                q: 'What happens when I cross a budget?',
                a: 'The ring turns red and you get a notification. This helps you slow down spending '
                    'in that category before the month ends.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            emoji: '📊',
            title: 'Insights',
            color: const Color(0xFF8B5CF6),
            items: [
              _HelpItem(
                q: 'What does the Insights screen show?',
                a: 'It shows patterns in your spending:\n'
                    '• A bar chart of daily spending for this month\n'
                    '• Which day of the week you spend the most\n'
                    '• Your spending streak (how many days you kept spending low)\n'
                    '• Your top merchants (where you spend the most)',
              ),
              _HelpItem(
                q: 'Can I see details for a specific day?',
                a: 'Yes — tap any bar in the chart to see all transactions for that day in a popup.',
              ),
              _HelpItem(
                q: 'What is the "Day Spending Rank"?',
                a: 'It ranks the days of the week (Monday to Sunday) by how much you typically spend. '
                    '🥇 means that\'s your highest spending day. Knowing this helps you plan and cut back.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            emoji: '❤️',
            title: 'Financial Health',
            color: const Color(0xFFEF4444),
            items: [
              _HelpItem(
                q: 'What is Financial Health?',
                a: 'Financial Health is a score (0 to 100) that tells you how well you are managing '
                    'your money. Think of it like your report card for money habits:\n\n'
                    '85–100 → Excellent 🏆 You are saving well and staying within limits\n'
                    '70–84  → Good 👍 You are on the right track\n'
                    '55–69  → Fair 🙂 Some areas need attention\n'
                    '40–54  → Needs Work ⚠️ Set budgets to gain control\n'
                    '0–39   → Critical 🚨 Spending is more than income',
              ),
              _HelpItem(
                q: 'How is the score calculated?',
                a: '3 things affect your score:\n'
                    '1. Savings Rate (50 pts) — what % of your income you save\n'
                    '2. Budget Adherence (30 pts) — how many budgets you stay within\n'
                    '3. Income Tracking (20 pts) — whether income is being detected\n\n'
                    'The higher each is, the better your score.',
              ),
              _HelpItem(
                q: 'How do I improve my score?',
                a: '• Set category budgets and stay within them\n'
                    '• Make sure your salary SMS is being detected (check Transactions → Credits)\n'
                    '• Reduce spending in your top expense category each month',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            emoji: '⚙️',
            title: 'Settings',
            color: const Color(0xFF64748B),
            items: [
              _HelpItem(
                q: 'What is "Salary Payday"?',
                a: 'This is the day of the month your salary arrives. '
                    'For example, if you get paid on the 27th, enter 27. '
                    'SpendLens uses this to calculate your spending cycle and Safe-to-Spend.',
              ),
              _HelpItem(
                q: 'What are Daily Limits?',
                a: 'You can set how much you want to spend in a day during weekdays (Mon–Fri) '
                    'and weekends (Sat–Sun). If you cross that amount, you get a notification. '
                    'This is great for controlling daily small expenses like chai, snacks, delivery, etc.',
              ),
              _HelpItem(
                q: 'Is my data safe? Does it go to the internet?',
                a: 'Your data NEVER leaves your phone. SpendLens stores everything locally '
                    'using AES-256 encryption — the same standard used by banks. '
                    'No account, no cloud sync, no ads. Your SMS are only read on-device.',
              ),
              _HelpItem(
                q: 'How do I re-scan SMS if transactions are missing?',
                a: 'Go to Settings → Data → Re-scan SMS Inbox. '
                    'This re-reads the last 6 months of bank SMS and adds any transactions that were missed.',
              ),
              _HelpItem(
                q: 'How do I export my data?',
                a: 'Settings → Data → Export to CSV. This creates a spreadsheet-compatible file '
                    'you can open in Excel or Google Sheets.',
              ),
              _HelpItem(
                q: 'Can I set a password / PIN lock?',
                a: 'Yes — Settings → Security → App Password. '
                    'Set a password so that every time you open SpendLens, it asks for the password first. '
                    'This protects your financial data if someone else picks up your phone.',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SupportCard(),
        ],
      ),
    );
  }
}

// ── Welcome Banner ────────────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('👋', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Welcome to SpendLens!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'SpendLens automatically reads your bank SMS and tracks expenses — '
                  'no manual entry needed. This guide explains everything in simple language.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section ───────────────────────────────────────────────────────────────────

class _Section extends StatefulWidget {
  final String emoji;
  final String title;
  final Color color;
  final List<_HelpItem> items;

  const _Section({
    required this.emoji,
    required this.title,
    required this.color,
    required this.items,
  });

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(widget.emoji,
                          style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: context.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(
              height: 1,
              color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight,
            ),
            ...widget.items.map((item) => _HelpItemTile(item: item)),
          ],
        ],
      ),
    );
  }
}

// ── Help Item (question/answer pair) ─────────────────────────────────────────

class _HelpItem {
  final String q;
  final String a;
  const _HelpItem({required this.q, required this.a});
}

class _HelpItemTile extends StatefulWidget {
  final _HelpItem item;
  const _HelpItemTile({required this.item});

  @override
  State<_HelpItemTile> createState() => _HelpItemTileState();
}

class _HelpItemTileState extends State<_HelpItemTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    _open
                        ? Icons.remove_circle_outline_rounded
                        : Icons.add_circle_outline_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.item.q,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.fromLTRB(44, 0, 16, 14),
            child: Text(
              widget.item.a,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.textMuted,
                    height: 1.6,
                  ),
            ),
          ),
        Divider(
          height: 1,
          indent: 16,
          color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight,
        ),
      ],
    );
  }
}

// ── Support Card ──────────────────────────────────────────────────────────────

class _SupportCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text('💬', style: TextStyle(fontSize: 30)),
          const SizedBox(height: 8),
          Text(
            'Still have questions?',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Email us at tshreyash2002@gmail.com\nWe reply within 24 hours.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.textMuted,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
