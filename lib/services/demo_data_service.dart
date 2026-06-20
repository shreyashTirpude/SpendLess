import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/local/hive_service.dart';
import '../domain/models/transaction.dart';
import '../domain/models/budget.dart';
import '../domain/models/user_profile.dart';

/// Seeds Hive with realistic Indian finance data covering every app feature.
/// Only runs once (version-gated). Re-seed: delete app data or call [reset].
class DemoDataService {
  static const _version = 'demo_v3';
  static const _uuid = Uuid();

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

  static Future<void> reset() async {
    await HiveService.settings.delete('demo_version');
    await HiveService.transactions.clear();
    await HiveService.budgets.clear();
    await HiveService.user.clear();
    debugPrint('[DemoDataService] Reset — will re-seed on next launch');
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
    final txns = _buildTransactions();
    for (final t in txns) {
      if (!box.containsKey(t.id)) {
        await box.put(t.id, t);
      }
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

  /// Shorthand: DateTime for a day in 2026
  static DateTime d(int month, int day) =>
      DateTime(2026, month, day, 10 + (day % 12), (day * 7) % 60);
}
