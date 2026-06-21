import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/local/hive_service.dart';
import '../domain/models/transaction.dart';
import '../domain/models/budget.dart';
import '../domain/models/user_profile.dart';
import '../core/utils/sms_parser.dart';

/// Seeds Hive with realistic Indian finance data covering every app feature.
/// Only runs once (version-gated). Re-seed: delete app data or call [reset].
///
/// Two seeding paths:
///   • [seed] — direct Transaction objects (full feature coverage; auto-runs
///     on macOS/web at startup).
///   • [seedViaSmsParser] — pushes raw bank SMS through the REAL [SmsParser]
///     pipeline, so the demo proves the exact parsing logic that runs on a
///     real Android device. Used by the in-app "Try Demo" button.
class DemoDataService {
  static const _version = 'demo_v3';
  static const _uuid = Uuid();

  /// True when the user has explicitly activated demo (any platform, incl.
  /// Android) — drives the persistent DEMO chip + splash auto-skip.
  static bool get isActive =>
      HiveService.settings.get('demo_session', defaultValue: false) as bool;

  // ── Public API ─────────────────────────────────────────────────────────────

  static Future<void> seed() async {
    final ver = HiveService.settings.get('demo_version', defaultValue: '');
    if (ver == _version) return;

    await _seedSettings();
    await _seedUserProfile();
    await _seedTransactions();
    await _seedBudgets();

    await HiveService.settings.put('demo_version', _version);
    debugPrint('[DemoDataService] Seeded all demo data ($ver → $_version)');
  }

  /// Full demo activation from the in-app button — works on every platform
  /// including Android. Runs the SMS-parser pipeline first (proving real
  /// parsing), then layers the rich direct data for complete feature coverage.
  static Future<void> activateDemo() async {
    await HiveService.settings.put('demo_session', true);
    final parsed = await seedViaSmsParser();
    await seed(); // settings + budgets + profile + direct rich txns
    debugPrint('[DemoDataService] Demo activated ($parsed via SMS parser)');
  }

  /// Runs ~45 realistic bank SMS through the production [SmsParser] and saves
  /// whatever it successfully parses. Returns the count parsed — this is the
  /// end-to-end proof that the parser handles real-world SMS formats.
  static Future<int> seedViaSmsParser() async {
    final box = HiveService.transactions;
    final seen = box.values.map(_sig).toSet();
    int added = 0;
    for (final (sms, date) in _smsCorpus()) {
      final p = SmsParser.parse(sms, date, senderAddress: _senderFor(sms));
      if (p == null) continue;
      final tx = SmsParser.toTransaction(p);
      // Anchor to the relative demo date (ignore the 2026 date in the SMS text)
      // so the demo always populates the *current* month.
      tx.transactionDate = date;
      final sig = _sig(tx);
      if (seen.contains(sig)) continue; // content-level dedup across seed paths
      seen.add(sig);
      await box.put(tx.id, tx);
      added++;
    }
    debugPrint('[DemoDataService] Parsed $added/${_smsCorpus().length} SMS');
    return added;
  }

  /// Content signature for cross-path dedup (random v4 ids and deterministic v5
  /// ids never collide, so we dedup on what a transaction actually *is*).
  static String _sig(Transaction t) =>
      '${t.merchant.toLowerCase()}|${t.amount}|'
      '${t.transactionDate.year}-${t.transactionDate.month}-${t.transactionDate.day}|'
      '${t.isCredit}';

  static Future<void> reset() async {
    await HiveService.settings.delete('demo_version');
    await HiveService.settings.delete('demo_session');
    await HiveService.transactions.clear();
    await HiveService.budgets.clear();
    await HiveService.user.clear();
    debugPrint('[DemoDataService] Reset — will re-seed on next launch');
  }

  /// Called when a user authenticates to a REAL account. If they had been in a
  /// demo session, wipe all sample data + demo flags so the real account starts
  /// completely clean (no mixed dummy transactions/budgets/Pro tier). No-op for
  /// genuine returning users (demo_session is false), so their data is safe.
  static Future<void> clearForRealAccount() async {
    if (!isActive) return;
    final s = HiveService.settings;
    await HiveService.transactions.clear();
    await HiveService.budgets.clear();
    await HiveService.user.clear();
    await s.delete('demo_session');
    await s.delete('demo_version');
    // Reset demo-granted Pro + billing + festival budgets to a clean slate.
    await s.put('subscriptionTier', 'free');
    await s.put('tierExpiry', '');
    await s.put('pro_auto_renew', false);
    await s.put('pro_first_charge', '');
    await s.put('pro_trial_start', '');
    await s.put('pro_upi_id', '');
    for (final k in s.keys.where((k) => k.toString().startsWith('festivalBudget_')).toList()) {
      await s.delete(k);
    }
    debugPrint('[DemoDataService] Cleared demo data for real account');
  }

  // ── Settings ───────────────────────────────────────────────────────────────

  static Future<void> _seedSettings() async {
    final s = HiveService.settings;
    await s.put('isOnboarded', true);
    await s.put('termsAccepted', true);
    await s.put('subscriptionTier', 'pro');      // unlock all Pro features
    await s.put('isDarkMode', true);
    await s.put('salaryDay', 1);
    await s.put('weekdayDailyBudget', 1500.0);
    await s.put('weekendDailyBudget', 2500.0);
    await s.put('monthlySavingsGoal', 12000.0);
    await s.put('appLockEnabled', false);
    // Festival budgets (upcoming 2026 festivals)
    await s.put('festivalBudget_Diwali', 8000.0);
    await s.put('festivalBudget_Dussehra', 3000.0);
    await s.put('festivalBudget_Holi', 2000.0);
    await s.put('festivalBudget_Eid', 5000.0);
    await s.put('festivalBudget_Christmas', 4000.0);
  }

  // ── User Profile ───────────────────────────────────────────────────────────

  static Future<void> _seedUserProfile() async {
    if (HiveService.user.isNotEmpty) return;
    final profile = UserProfile(
      id: 'demo-user-001',
      phone: '+91-9876543210',
      name: 'Shreyash',
      monthlyBudget: 60000,
      adsRemoved: true,
      biometricEnabled: false,
      createdAt: DateTime(2026, 1, 1),
    );
    await HiveService.user.put('demo-user-001', profile);
  }

  // ── Transactions ───────────────────────────────────────────────────────────

  static Future<void> _seedTransactions() async {
    final box = HiveService.transactions;
    final seen = box.values.map(_sig).toSet();
    final txns = _buildTransactions();
    for (final t in txns) {
      final sig = _sig(t);
      if (box.containsKey(t.id) || seen.contains(sig)) continue;
      seen.add(sig);
      await box.put(t.id, t);
    }
    debugPrint('[DemoDataService] Added ${txns.length} transactions');
  }

  static List<Transaction> _buildTransactions() {
    // Jun 2026 = current month (partial: days 1–19)
    // May 2026 = last full month
    // Apr 2026 = 2 months ago
    // Mar 2026 = 3 months ago (for recurring detector + insights trends)
    final List<Transaction> all = [];
    all.addAll(_june());
    all.addAll(_may());
    all.addAll(_april());
    all.addAll(_march());
    return all;
  }

  // ── JUNE 2026 (current month, partial) ─────────────────────────────────────

  static List<Transaction> _june() => [
        // ── Salary ─────────────────────────────────────────────────────────
        _tx('Salary', 'Salary', 75000, true,  d(6, 1),  '0987', note: 'TECHCORP SAL JUN26'),
        _tx('Interest', 'Income', 843, true,  d(6, 1),  '4821', note: 'SB INT JUN26'),

        // ── Loan EMI (NACH - recurring day 5) ──────────────────────────────
        _tx('HDFC Home Loan', 'Loan EMI', 22450, false, d(6, 5), '4821', note: 'NACH HOME LOAN EMI'),

        // ── Insurance (NACH - recurring day 8) ─────────────────────────────
        _tx('LIC', 'Insurance', 8500, false, d(6, 8), '4821', note: 'NACH LIC PREMIUM'),

        // ── Investment SIP (NACH - recurring days 10, 12) ──────────────────
        _tx('Groww', 'Investment', 10000, false, d(6, 10), '4821', note: 'NACH SIP GROWW MF'),
        _tx('Axis Mutual Fund', 'Investment', 5000, false, d(6, 12), '4821', note: 'NACH SIP AXIS MF'),

        // ── Subscriptions (same day each month) ────────────────────────────
        _tx('Netflix', 'Subscriptions', 649, false, d(6, 1),  '4821'),
        _tx('Hotstar', 'Subscriptions', 899, false, d(6, 3),  '4821'),
        _tx('Spotify', 'Subscriptions', 149, false, d(6, 5),  '4821'),
        _tx('YouTube Premium', 'Subscriptions', 189, false, d(6, 10), '4821'),
        _tx('Amazon Prime', 'Subscriptions', 299, false, d(6, 15), '4821'),

        // ── Bills & Utilities ───────────────────────────────────────────────
        _tx('Airtel', 'Bills & Utilities', 599, false, d(6, 4),  '4821'),
        _tx('BESCOM', 'Bills & Utilities', 1250, false, d(6, 12), '4821', note: 'Electricity June'),
        _tx('Indane Gas', 'Bills & Utilities', 940, false, d(6, 7),  '4821'),
        _tx('Tata Play', 'Bills & Utilities', 349, false, d(6, 6),  '4821'),

        // ── Food & Dining ───────────────────────────────────────────────────
        _tx('Zomato', 'Food & Dining', 650,  false, d(6, 2),  '4821'),
        _tx("Domino's", 'Food & Dining', 850, false, d(6, 4),  '5678'),
        _tx('Swiggy', 'Food & Dining', 450,  false, d(6, 7),  '4821'),
        _tx('Starbucks', 'Food & Dining', 590, false, d(6, 9),  '5678'),
        _tx('Zomato', 'Food & Dining', 340,  false, d(6, 11), '4821'),
        _tx('McDonald\'s', 'Food & Dining', 480, false, d(6, 13), '5678'),
        _tx('Swiggy', 'Food & Dining', 620,  false, d(6, 16), '4821'),
        _tx('Zomato', 'Food & Dining', 550,  false, d(6, 19), '4821'),
        _tx('KFC', 'Food & Dining', 420,     false, d(6, 18), '5678'),

        // ── Groceries ───────────────────────────────────────────────────────
        _tx('Bigbasket', 'Groceries', 2200, false, d(6, 3),  '4821'),
        _tx('Zepto', 'Groceries', 1100,     false, d(6, 9),  '4821'),
        _tx('Blinkit', 'Groceries', 750,    false, d(6, 14), '4821'),
        _tx('DMart', 'Groceries', 3200,     false, d(6, 8),  '5678'),
        _tx('Nature\'s Basket', 'Groceries', 1850, false, d(6, 17), '5678'),

        // ── Shopping ────────────────────────────────────────────────────────
        _tx('Amazon', 'Shopping', 4299, false, d(6, 5),  '5678'),
        _tx('Myntra', 'Shopping', 1799, false, d(6, 11), '5678'),
        _tx('Nykaa', 'Shopping', 1350, false, d(6, 15), '5678'),

        // ── Transport ───────────────────────────────────────────────────────
        _tx('Uber', 'Transport', 280,  false, d(6, 2),  '4821'),
        _tx('Ola', 'Transport', 350,   false, d(6, 6),  '4821'),
        _tx('Rapido', 'Transport', 90, false, d(6, 9),  '4821'),
        _tx('IRCTC', 'Transport', 1450, false, d(6, 13), '4821'),
        _tx('Uber', 'Transport', 310,  false, d(6, 17), '4821'),
        _tx('Rapido', 'Transport', 75, false, d(6, 19), '4821'),

        // ── Fuel ────────────────────────────────────────────────────────────
        _tx('HPCL', 'Fuel', 2000, false, d(6, 7),  '4821'),

        // ── Health ──────────────────────────────────────────────────────────
        _tx('Apollo Pharmacy', 'Health', 450, false, d(6, 11), '4821'),
        _tx('Practo', 'Health', 499, false, d(6, 16), '4821'),

        // ── Entertainment ───────────────────────────────────────────────────
        _tx('BookMyShow', 'Entertainment', 640, false, d(6, 8),  '5678'),
        _tx('PVR Cinemas', 'Entertainment', 520, false, d(6, 15), '5678'),

        // ── Education ───────────────────────────────────────────────────────
        _tx('Udemy', 'Education', 499, false, d(6, 3), '4821'),

        // ── Travel ──────────────────────────────────────────────────────────
        _tx('OYO', 'Travel & Hotels', 3500, false, d(6, 14), '4821'),

        // ── Government ──────────────────────────────────────────────────────
        _tx('EPFO', 'Government', 2400, false, d(6, 1), '0987', note: 'PF contribution'),

        // ── ATM ─────────────────────────────────────────────────────────────
        _tx('ATM Withdrawal', 'ATM & Cash', 10000, false, d(6, 10), '4821'),

        // ── Send Money (P2P) ─────────────────────────────────────────────────
        _tx('Rahul Sharma', 'Send Money', 2000, false, d(6, 6),  '4821', note: 'vpa:rahul.sharma@ybl'),
        _tx('Priya Mehta', 'Send Money', 1500, false, d(6, 13), '4821', note: 'vpa:priya.mehta@oksbi'),
        _tx('9876543210', 'Send Money', 5000, false, d(6, 19), '4821', note: 'vpa:9876543210@okicici'),

        // ── Refunds (credits) ────────────────────────────────────────────────
        _tx('Flipkart', 'Refund', 799, true, d(6, 12), '4821', note: 'Order refund'),
        _tx('Myntra', 'Refund', 599, true, d(6, 18), '5678', note: 'Return refund'),
      ];

  // ── MAY 2026 (last full month) ──────────────────────────────────────────────

  static List<Transaction> _may() => [
        _tx('Salary', 'Salary', 75000, true,  d(5, 1),  '0987', note: 'TECHCORP SAL MAY26'),
        _tx('Interest', 'Income', 812, true,  d(5, 1),  '4821', note: 'SB INT MAY26'),

        _tx('HDFC Home Loan', 'Loan EMI', 22450, false, d(5, 5), '4821', note: 'NACH HOME LOAN EMI'),
        _tx('LIC', 'Insurance', 8500, false, d(5, 8), '4821', note: 'NACH LIC PREMIUM'),
        _tx('Groww', 'Investment', 10000, false, d(5, 10), '4821', note: 'NACH SIP GROWW MF'),
        _tx('Axis Mutual Fund', 'Investment', 5000, false, d(5, 12), '4821', note: 'NACH SIP AXIS MF'),

        _tx('Netflix', 'Subscriptions', 649, false, d(5, 1),  '4821'),
        _tx('Hotstar', 'Subscriptions', 899, false, d(5, 3),  '4821'),
        _tx('Spotify', 'Subscriptions', 149, false, d(5, 5),  '4821'),
        _tx('YouTube Premium', 'Subscriptions', 189, false, d(5, 10), '4821'),
        _tx('Amazon Prime', 'Subscriptions', 299, false, d(5, 15), '4821'),

        _tx('Airtel', 'Bills & Utilities', 599, false, d(5, 4),  '4821'),
        _tx('Jio', 'Bills & Utilities', 299, false, d(5, 7),  '4821'),
        _tx('BESCOM', 'Bills & Utilities', 1180, false, d(5, 12), '4821'),
        _tx('Indane Gas', 'Bills & Utilities', 940, false, d(5, 9),  '4821'),

        _tx('Zomato', 'Food & Dining', 780,  false, d(5, 3),  '4821'),
        _tx('Swiggy', 'Food & Dining', 520,  false, d(5, 5),  '4821'),
        _tx('Zomato', 'Food & Dining', 430,  false, d(5, 9),  '4821'),
        _tx("Domino's", 'Food & Dining', 960, false, d(5, 11), '5678'),
        _tx('KFC', 'Food & Dining', 680,     false, d(5, 14), '5678'),
        _tx('Zomato', 'Food & Dining', 540,  false, d(5, 17), '4821'),
        _tx('Swiggy', 'Food & Dining', 380,  false, d(5, 20), '4821'),
        _tx('McDonald\'s', 'Food & Dining', 560, false, d(5, 23), '5678'),
        _tx('Starbucks', 'Food & Dining', 620, false, d(5, 25), '5678'),
        _tx('Barbeque Nation', 'Food & Dining', 2400, false, d(5, 28), '5678'),
        _tx('Zomato', 'Food & Dining', 490,  false, d(5, 31), '4821'),

        _tx('Bigbasket', 'Groceries', 2800, false, d(5, 4),  '4821'),
        _tx('Zepto', 'Groceries', 950,     false, d(5, 11), '4821'),
        _tx('Blinkit', 'Groceries', 620,   false, d(5, 18), '4821'),
        _tx('DMart', 'Groceries', 4100,    false, d(5, 7),  '5678'),
        _tx('Zepto', 'Groceries', 840,     false, d(5, 25), '4821'),

        _tx('Flipkart', 'Shopping', 5500,  false, d(5, 6),  '5678'),
        _tx('Amazon', 'Shopping', 8999,    false, d(5, 13), '5678'),
        _tx('Myntra', 'Shopping', 2399,    false, d(5, 19), '5678'),
        _tx('Ajio', 'Shopping', 1299,      false, d(5, 26), '5678'),

        _tx('Uber', 'Transport', 320,  false, d(5, 2),  '4821'),
        _tx('Ola', 'Transport', 410,   false, d(5, 8),  '4821'),
        _tx('IndiGo', 'Transport', 4850, false, d(5, 14), '5678'),
        _tx('IRCTC', 'Transport', 875, false, d(5, 22), '4821'),
        _tx('Uber', 'Transport', 290,  false, d(5, 28), '4821'),
        _tx('Rapido', 'Transport', 80, false, d(5, 30), '4821'),

        _tx('HPCL', 'Fuel', 2000, false, d(5, 10), '4821'),
        _tx('BPCL', 'Fuel', 1800, false, d(5, 24), '4821'),

        _tx('Apollo Pharmacy', 'Health', 820, false, d(5, 7),  '4821'),
        _tx('Star Health', 'Insurance', 3500, false, d(5, 15), '4821', note: 'Health insurance premium'),

        _tx('BookMyShow', 'Entertainment', 1280, false, d(5, 10), '5678'),
        _tx('Dream11', 'Entertainment', 500, false, d(5, 21), '5678'),

        _tx('Coursera', 'Education', 3000, false, d(5, 5), '5678'),

        _tx('MakeMyTrip', 'Travel & Hotels', 12500, false, d(5, 13), '5678', note: 'Hotel booking Goa'),
        _tx('OYO', 'Travel & Hotels', 2800, false, d(5, 24), '4821'),

        _tx('EPFO', 'Government', 2400, false, d(5, 1), '0987', note: 'PF contribution'),

        _tx('ATM Withdrawal', 'ATM & Cash', 10000, false, d(5, 15), '4821'),
        _tx('ATM Withdrawal', 'ATM & Cash', 5000, false, d(5, 27), '4821'),

        _tx('Ankit Verma', 'Send Money', 3000, false, d(5, 9),  '4821', note: 'vpa:ankit.verma@ybl'),
        _tx('Sneha Kulkarni', 'Send Money', 500, false, d(5, 18), '4821', note: 'vpa:sneha.k@oksbi'),
        _tx('9845612300', 'Send Money', 8000, false, d(5, 22), '4821', note: 'vpa:9845612300@okhdfcbank'),

        _tx('Amazon', 'Refund', 1299, true, d(5, 16), '5678', note: 'Cancelled order refund'),
        _tx('Zomato', 'Refund', 350, true, d(5, 29), '4821', note: 'Order issue refund'),
      ];

  // ── APRIL 2026 ──────────────────────────────────────────────────────────────

  static List<Transaction> _april() => [
        _tx('Salary', 'Salary', 75000, true,  d(4, 1),  '0987', note: 'TECHCORP SAL APR26'),
        _tx('Freelance', 'Salary', 15000, true, d(4, 10), '4821', note: 'Consulting payment'),
        _tx('Interest', 'Income', 780, true,  d(4, 1),  '4821'),

        _tx('HDFC Home Loan', 'Loan EMI', 22450, false, d(4, 5), '4821', note: 'NACH HOME LOAN EMI'),
        _tx('Bajaj Finance', 'Loan EMI', 4200, false, d(4, 7), '4821', note: 'NACH PERSONAL LOAN EMI'),
        _tx('LIC', 'Insurance', 8500, false, d(4, 8), '4821', note: 'NACH LIC PREMIUM'),
        _tx('Groww', 'Investment', 10000, false, d(4, 10), '4821', note: 'NACH SIP GROWW MF'),
        _tx('Axis Mutual Fund', 'Investment', 5000, false, d(4, 12), '4821', note: 'NACH SIP AXIS MF'),
        _tx('Zerodha', 'Investment', 25000, false, d(4, 17), '4821', note: 'Stock purchase'),

        _tx('Netflix', 'Subscriptions', 649, false, d(4, 1),  '4821'),
        _tx('Hotstar', 'Subscriptions', 299, false, d(4, 3),  '4821'),  // cheaper plan
        _tx('Spotify', 'Subscriptions', 149, false, d(4, 5),  '4821'),
        _tx('YouTube Premium', 'Subscriptions', 189, false, d(4, 10), '4821'),
        _tx('Amazon Prime', 'Subscriptions', 299, false, d(4, 15), '4821'),
        _tx('Notion', 'Subscriptions', 400, false, d(4, 20), '5678'),

        _tx('Airtel', 'Bills & Utilities', 599, false, d(4, 4),  '4821'),
        _tx('Jio', 'Bills & Utilities', 299, false, d(4, 7),  '4821'),
        _tx('BESCOM', 'Bills & Utilities', 1420, false, d(4, 12), '4821'),
        _tx('Indane Gas', 'Bills & Utilities', 940, false, d(4, 9),  '4821'),
        _tx('Society Maintenance', 'Bills & Utilities', 2500, false, d(4, 5), '4821'),

        // Rent (April — before user moved to owned house)
        _tx('Rent - Sharma Ji', 'Rent', 25000, false, d(4, 1), '4821', note: 'Monthly house rent'),

        _tx('Zomato', 'Food & Dining', 890,  false, d(4, 2),  '4821'),
        _tx('Swiggy', 'Food & Dining', 660,  false, d(4, 6),  '4821'),
        _tx("Domino's", 'Food & Dining', 780, false, d(4, 9),  '5678'),
        _tx('Zomato', 'Food & Dining', 510,  false, d(4, 13), '4821'),
        _tx('McDonald\'s', 'Food & Dining', 420, false, d(4, 16), '5678'),
        _tx('Swiggy', 'Food & Dining', 590,  false, d(4, 20), '4821'),
        _tx('Zomato', 'Food & Dining', 340,  false, d(4, 24), '4821'),
        _tx('Subway', 'Food & Dining', 320,  false, d(4, 27), '5678'),
        _tx('Swiggy', 'Food & Dining', 480,  false, d(4, 30), '4821'),

        _tx('Bigbasket', 'Groceries', 3100, false, d(4, 5),  '4821'),
        _tx('Zepto', 'Groceries', 780,     false, d(4, 13), '4821'),
        _tx('Blinkit', 'Groceries', 940,   false, d(4, 20), '4821'),
        _tx('DMart', 'Groceries', 2800,    false, d(4, 9),  '5678'),

        _tx('Amazon', 'Shopping', 12999,   false, d(4, 7),  '5678', note: 'Laptop stand + accessories'),
        _tx('Flipkart', 'Shopping', 3499,  false, d(4, 14), '5678'),
        _tx('Croma', 'Shopping', 6999,     false, d(4, 21), '5678'),

        _tx('Uber', 'Transport', 350,  false, d(4, 3),  '4821'),
        _tx('Ola', 'Transport', 290,   false, d(4, 8),  '4821'),
        _tx('IndiGo', 'Transport', 6200, false, d(4, 14), '5678', note: 'BLR-DEL flight'),
        _tx('IRCTC', 'Transport', 1120, false, d(4, 22), '4821'),
        _tx('Uber', 'Transport', 180,  false, d(4, 28), '4821'),

        _tx('HPCL', 'Fuel', 2500, false, d(4, 11), '4821'),

        _tx('Apollo Pharmacy', 'Health', 1250, false, d(4, 6),  '4821'),
        _tx('Practo', 'Health', 799,          false, d(4, 19), '4821', note: 'Doctor consultation'),
        _tx('PharmEasy', 'Health', 640,       false, d(4, 26), '4821'),

        _tx('INOX', 'Entertainment', 960, false, d(4, 8), '5678'),
        _tx('BookMyShow', 'Entertainment', 750, false, d(4, 22), '5678'),

        _tx('Unacademy', 'Education', 1800, false, d(4, 4), '5678'),
        _tx('Udemy', 'Education', 499, false, d(4, 18), '4821'),

        _tx('OYO', 'Travel & Hotels', 4200, false, d(4, 14), '4821'),

        _tx('Nykaa', 'Personal Care', 1650, false, d(4, 10), '5678'),

        _tx('EPFO', 'Government', 2400, false, d(4, 1), '0987', note: 'PF contribution'),

        _tx('ATM Withdrawal', 'ATM & Cash', 20000, false, d(4, 1), '4821'),

        _tx('Papa', 'Send Money', 10000, false, d(4, 5),  '4821', note: 'vpa:papa.tirpude@sbi'),
        _tx('Ravi Kumar', 'Send Money', 2000, false, d(4, 12), '4821', note: 'vpa:ravi.kumar@ybl'),
        _tx('9123456789', 'Send Money', 3000, false, d(4, 18), '4821', note: 'vpa:9123456789@oksbi'),
        _tx('Mummy', 'Send Money', 5000, false, d(4, 25), '4821', note: 'vpa:9000112233@okhdfcbank'),

        _tx('IndiGo', 'Refund', 2000, true, d(4, 20), '5678', note: 'Seat upgrade refund'),
      ];

  // ── MARCH 2026 (3 months ago — lightweight for trend data) ──────────────────

  static List<Transaction> _march() => [
        _tx('Salary', 'Salary', 70000, true, d(3, 1), '0987', note: 'TECHCORP SAL MAR26'),
        _tx('HDFC Home Loan', 'Loan EMI', 22450, false, d(3, 5), '4821', note: 'NACH HOME LOAN EMI'),
        _tx('LIC', 'Insurance', 8500, false, d(3, 8), '4821', note: 'NACH LIC PREMIUM'),
        _tx('Groww', 'Investment', 10000, false, d(3, 10), '4821', note: 'NACH SIP GROWW MF'),
        _tx('Netflix', 'Subscriptions', 649, false, d(3, 1), '4821'),
        _tx('Hotstar', 'Subscriptions', 299, false, d(3, 3), '4821'),
        _tx('Spotify', 'Subscriptions', 149, false, d(3, 5), '4821'),
        _tx('YouTube Premium', 'Subscriptions', 189, false, d(3, 10), '4821'),
        _tx('Amazon Prime', 'Subscriptions', 299, false, d(3, 15), '4821'),
        _tx('Airtel', 'Bills & Utilities', 599, false, d(3, 4), '4821'),
        _tx('BESCOM', 'Bills & Utilities', 980, false, d(3, 12), '4821'),
        _tx('Zomato', 'Food & Dining', 750,  false, d(3, 4),  '4821'),
        _tx('Swiggy', 'Food & Dining', 520,  false, d(3, 8),  '4821'),
        _tx('Zomato', 'Food & Dining', 410,  false, d(3, 14), '4821'),
        _tx("Domino's", 'Food & Dining', 650, false, d(3, 19), '5678'),
        _tx('Swiggy', 'Food & Dining', 460,  false, d(3, 25), '4821'),
        _tx('Zomato', 'Food & Dining', 380,  false, d(3, 29), '4821'),
        _tx('Bigbasket', 'Groceries', 2400, false, d(3, 6),  '4821'),
        _tx('Zepto', 'Groceries', 880,     false, d(3, 16), '4821'),
        _tx('DMart', 'Groceries', 3500,    false, d(3, 10), '5678'),
        _tx('Amazon', 'Shopping', 5499,    false, d(3, 9),  '5678'),
        _tx('Flipkart', 'Shopping', 2999,  false, d(3, 22), '5678'),
        _tx('Uber', 'Transport', 290,  false, d(3, 5),  '4821'),
        _tx('Ola', 'Transport', 350,   false, d(3, 14), '4821'),
        _tx('IRCTC', 'Transport', 960, false, d(3, 20), '4821'),
        _tx('HPCL', 'Fuel', 2000, false, d(3, 8), '4821'),
        _tx('Apollo Pharmacy', 'Health', 560, false, d(3, 12), '4821'),
        _tx('EPFO', 'Government', 2400, false, d(3, 1), '0987'),
        _tx('ATM Withdrawal', 'ATM & Cash', 10000, false, d(3, 14), '4821'),
        _tx('Rent - Sharma Ji', 'Rent', 25000, false, d(3, 1), '4821'),
        _tx('Arjun Singh', 'Send Money', 1500, false, d(3, 10), '4821', note: 'vpa:arjun.s@ybl'),
        _tx('BookMyShow', 'Entertainment', 890, false, d(3, 16), '5678'),
      ];

  // ── Budgets ────────────────────────────────────────────────────────────────

  static Future<void> _seedBudgets() async {
    final box = HiveService.budgets;
    if (box.isNotEmpty) return;

    final monthYear = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

    final budgets = [
      _budget('Food & Dining',    5000,  monthYear),
      _budget('Groceries',        4500,  monthYear),
      _budget('Shopping',         7000,  monthYear),
      _budget('Transport',        2500,  monthYear),
      _budget('Bills & Utilities',3500,  monthYear),
      _budget('Subscriptions',    2500,  monthYear),
      _budget('Investment',       20000, monthYear),
      _budget('Loan EMI',         25000, monthYear),
      _budget('Insurance',        10000, monthYear),
      _budget('Entertainment',    1500,  monthYear),
      _budget('Health',           3000,  monthYear),
      _budget('Education',        3000,  monthYear),
      _budget('Travel & Hotels',  10000, monthYear),
      _budget('Fuel',             3000,  monthYear),
      _budget('Personal Care',    2000,  monthYear),
      _budget('Send Money',       15000, monthYear),
      _budget('ATM & Cash',       10000, monthYear),
      _budget('Government',       5000,  monthYear),
    ];

    for (final b in budgets) {
      await box.put(b.id, b);
    }
    debugPrint('[DemoDataService] Seeded ${budgets.length} budgets');
  }

  // ── Raw SMS corpus (exercises the real SmsParser pipeline) ──────────────────

  /// 45 realistic Indian bank SMS spanning all banks + categories. Parsed by
  /// the production [SmsParser] — proves the exact logic a real device runs.
  static List<(String, DateTime)> _smsCorpus() => [
        // HDFC
        ('INR 2,450.00 debited from A/c XX4821 on 19-Jun-26 at 14:32. Info: ZOMATO*FOOD. UPI Ref: 512345678901. Avl Bal: INR 18,320.50. -HDFCBK', d(6, 19)),
        ('INR 4,299.00 spent on HDFC Bank Card XX5678 at AMAZON SELLER on 18-Jun-26. Avl Lmt: INR 82,300. -HDFCBK', d(6, 18)),
        ('INR 280.00 debited from A/c XX4821. Info: UBER*TRIP*BLR. Avl Bal: INR 24,590. -HDFCBK', d(6, 17)),
        ('INR 22,450.00 debited from A/c XX4821 for ECS/NACH HDFC HOME LOAN EMI on 05-Jun-26. Avl Bal: INR 8,550. -HDFCBK', d(6, 5)),
        ('INR 649.00 debited from A/c XX4821 via UPI to netflix1234@icici. Avl Bal INR 17,671. -HDFCBK', d(6, 1)),
        ('Refund of INR 799.00 from FLIPKART credited to your HDFC A/c XX4821. Avl Bal: INR 18,319. -HDFCBK', d(6, 12)),
        ('INR 2,000.00 debited from A/c XX4821. Info: HP PETROL PUMP*PUNE. Avl Bal: INR 16,441. -HDFCBK', d(6, 7)),
        ('INR 10,000.00 withdrawn at ATM from A/c XX4821 on 10-Jun-26. Avl Bal: INR 28,320. -HDFCBK', d(6, 10)),
        // SBI
        ('Your A/C XXXXX0987 Credited INR 75,000.00 on 01/06/2026. Salary credit from TECHCORP. Avl Bal: INR 81,250. -SBIBNK', d(6, 1)),
        ('Your a/c no. XXXX0987 is debited for Rs.1,450.00 on 13/06/2026 via UPI to irctc@sbi. UPI Ref 512345678902. -SBIBNK', d(6, 13)),
        ('Rs.1,250.00 debited from SBI A/c XX0987 via UPI to bescom@sbi for electricity. Avl Bal Rs.80,000. -SBIBNK', d(6, 12)),
        ('Rs.2,400.00 debited from SBI A/c XX0987 via UPI to epfo@sbi PF contribution. Avl Bal Rs.77,600. -SBIBNK', d(6, 1)),
        // ICICI
        ('ICICI Bank Acct XX5678 debited with INR 850.00 on 11-Jun-26; APOLLO PHARMACY credited. Avl Bal INR 9,150. -ICICIB', d(6, 11)),
        ('INR 2,200.00 debited from ICICI A/c XX5678 via UPI to bigbasket@icici. Avl Bal: INR 18,000. -ICICIB', d(6, 3)),
        ('INR 1,100.00 debited from ICICI A/c XX5678 via UPI to zepto@icici. Avl Bal: INR 16,900. -ICICIB', d(6, 9)),
        ('INR 899.00 debited from ICICI A/c XX5678 via UPI to hotstar@icici. Avl Bal: INR 16,001. -ICICIB', d(6, 3)),
        // Axis
        ('Rs.750.00 debited from Axis Bank A/c XX9012 on 18-Jun-26. Info: SWIGGY*DELIVERY. UPI Ref No: 512398000111. Avl Bal: Rs.9,250. -AXISBK', d(6, 18)),
        ('Rs.149.00 debited from Axis Bank A/c XX9012 via UPI to spotify@axis. Avl Bal: Rs.9,101. -AXISBK', d(6, 5)),
        ('Rs.2,000.00 sent to rahul.sharma@ybl via UPI from Axis A/c XX9012. Avl Bal: Rs.7,101. -AXISBK', d(6, 6)),
        ('Rs.5,000.00 sent to 9876543210@okicici via UPI from Axis A/c XX9012. Avl Bal: Rs.2,101. -AXISBK', d(6, 19)),
        // Kotak
        ('INR 5,000.00 debited from Kotak a/c XX3344 via UPI to groww@icici for SIP. Avl Bal INR 12,551. -KOTAKB', d(6, 10)),
        ('INR 8,500.00 debited from Kotak a/c XX3344 for ECS/NACH LIC PREMIUM. Avl Bal INR 4,051. -KOTAKB', d(6, 8)),
        // IDFC
        ('Your IDFC FIRST Bank A/c XX7788 debited for INR 599.00 on 04-Jun-26 via UPI to airtel@idfc. Avl Bal: INR 9,401. -IDFCFB', d(6, 4)),
        ('Your IDFC FIRST Bank A/c XX7788 debited for INR 3,500.00 via UPI to oyo@icici. Avl Bal: INR 5,901. -IDFCFB', d(6, 14)),
        // May
        ('INR 75,000.00 credited to Kotak a/c XX3344 on 01-May-26. Info: SAL/TECHCORP/MAY26. Avl Bal INR 82,100. -KOTAKB', d(5, 1)),
        ('INR 22,450.00 debited from A/c XX4821 for ECS/NACH HDFC HOME LOAN EMI on 05-May-26. Avl Bal: INR 43,200. -HDFCBK', d(5, 5)),
        ('INR 12,500.00 debited from ICICI Card XX5678 at MAKEMYTRIP on 13-May-26. Avl Lmt: INR 70,000. -ICICIB', d(5, 13)),
        ('INR 4,850.00 spent on HDFC Card XX5678 at INDIGO on 14-May-26. -HDFCBK', d(5, 14)),
        ('Rs.3,000.00 debited from Axis A/c XX9012 via UPI to coursera@axis. Avl Bal: Rs.20,000. -AXISBK', d(5, 5)),
        ('INR 8,999.00 spent on HDFC Card XX5678 at AMAZON on 13-May-26. Avl Lmt: INR 60,000. -HDFCBK', d(5, 13)),
        ('Rs.2,400.00 debited from SBI A/c XX0987 at BARBEQUE NATION on 28-May-26. Avl Bal Rs.50,000. -SBIBNK', d(5, 28)),
        ('Rs.500.00 sent to ankit.verma@ybl via UPI from Axis A/c XX9012. Avl Bal: Rs.49,500. -AXISBK', d(5, 9)),
        // April
        ('Your A/C XXXXX0987 Credited INR 75,000.00 on 01/04/2026. Salary credit from TECHCORP. Avl Bal: INR 79,000. -SBIBNK', d(4, 1)),
        ('INR 15,000.00 credited to A/c XX4821 on 10-Apr-26 via NEFT. Info: FREELANCE CONSULTING. Avl Bal: INR 50,000. -HDFCBK', d(4, 10)),
        ('INR 25,000.00 debited from A/c XX4821 via UPI to rent.landlord@oksbi. Avl Bal: INR 25,000. -HDFCBK', d(4, 1)),
        ('INR 25,000.00 debited from A/c XX4821 via NEFT to ZERODHA BROKING. Avl Bal: INR 30,000. -HDFCBK', d(4, 17)),
        ('INR 12,999.00 spent on HDFC Card XX5678 at AMAZON on 07-Apr-26. -HDFCBK', d(4, 7)),
        ('INR 6,999.00 spent on ICICI Card XX5678 at CROMA on 21-Apr-26. Avl Lmt: INR 55,000. -ICICIB', d(4, 21)),
        ('INR 1,800.00 debited from A/c XX4821 via UPI to unacademy@ybl. Avl Bal: INR 18,000. -HDFCBK', d(4, 4)),
        ('Rs.10,000.00 sent to papa.tirpude@sbi via UPI from SBI A/c XX0987. Avl Bal Rs.40,000. -SBIBNK', d(4, 5)),
        ('INR 4,200.00 debited from A/c XX4821 for ECS/NACH BAJAJ FINANCE PERSONAL LOAN EMI. Avl Bal: INR 35,000. -HDFCBK', d(4, 7)),
        ('INR 1,650.00 debited from ICICI Card XX5678 at NYKAA on 10-Apr-26. Avl Lmt: INR 60,000. -ICICIB', d(4, 10)),
        ('INR 3,500.00 debited from A/c XX4821 via UPI to starhealth@hdfc insurance premium. Avl Bal: INR 31,500. -HDFCBK', d(5, 15)),
        ('INR 960.00 debited from HDFC Card XX5678 at INOX on 08-Apr-26. -HDFCBK', d(4, 8)),
        ('Rs.1,500.00 sent to priya.mehta@oksbi via UPI from Axis A/c XX9012. Avl Bal: Rs.8,000. -AXISBK', d(6, 13)),
      ];

  /// Infer the trusted bank sender ID from the SMS signature so the parser's
  /// sender-allowlist path is exercised (must start with a known prefix).
  static String _senderFor(String sms) {
    final m = RegExp(r'-([A-Z]{5,6})$').firstMatch(sms.trim());
    return m != null ? m.group(1)! : 'HDFCBK';
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static Transaction _tx(
    String merchant,
    String category,
    double amount,
    bool isCredit,
    DateTime date,
    String last4, {
    String? note,
  }) {
    final id = _uuid.v5('6ba7b811-9dad-11d1-80b4-00c04fd430c8',
        '$merchant-$category-$amount-${date.toIso8601String()}-$last4');
    return Transaction(
      id: id,
      amount: amount,
      merchant: merchant,
      category: category,
      isCredit: isCredit,
      accountLast4: last4,
      transactionDate: date,
      rawSmsHash: null,
      source: 'demo',
      note: note,
      isSynced: false,
      createdAt: date,
      isIgnored: false,
    );
  }

  static Budget _budget(String category, double limit, String monthYear) {
    return Budget(
      id: _uuid.v5('6ba7b811-9dad-11d1-80b4-00c04fd430c8', 'budget-$category-$monthYear'),
      category: category,
      monthlyLimit: limit,
      monthYear: monthYear,
      isSynced: false,
    );
  }

  /// Relative demo date. The data is authored with month 6 = "current month",
  /// 5 = last month, 4 = two months ago, 3 = three months ago. We map those to
  /// real months relative to today so the demo always populates the CURRENT
  /// month (no hardcoded-2026 time-bomb). Current-month days are clamped to
  /// today so there are never future-dated transactions.
  static DateTime d(int month, int day) {
    final now = DateTime.now();
    final monthsAgo = 6 - month; // 6->0 (this month), 5->1, 4->2, 3->3
    var y = now.year;
    var m = now.month - monthsAgo;
    while (m < 1) {
      m += 12;
      y -= 1;
    }
    final daysInMonth = DateTime(y, m + 1, 0).day;
    var dd = day.clamp(1, daysInMonth);
    if (monthsAgo == 0 && dd > now.day) dd = now.day;
    return DateTime(y, m, dd, 10 + (day % 12), (day * 7) % 60);
  }
}
