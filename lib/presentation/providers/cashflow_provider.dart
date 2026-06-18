import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/hive_service.dart';
import '../../domain/models/transaction.dart';
import 'cache_provider.dart';

// ── Payee type enum ────────────────────────────────────────────────────────────

enum PayeeType {
  salary,
  rent,
  friends,
  family,
  loanEmi,
  utilities,
  merchant,
}

extension PayeeTypeX on PayeeType {
  String get label => switch (this) {
        PayeeType.salary => 'Salary',
        PayeeType.rent => 'Rent',
        PayeeType.friends => 'Friends',
        PayeeType.family => 'Family',
        PayeeType.loanEmi => 'Loan / EMI',
        PayeeType.utilities => 'Utilities',
        PayeeType.merchant => 'Merchants',
      };

  String get icon => switch (this) {
        PayeeType.salary => '💼',
        PayeeType.rent => '🏠',
        PayeeType.friends => '👥',
        PayeeType.family => '👨‍👩‍👧',
        PayeeType.loanEmi => '🏦',
        PayeeType.utilities => '⚡',
        PayeeType.merchant => '🛍️',
      };
}

// ── Cashflow summary model ─────────────────────────────────────────────────────

class CashflowSummary {
  final PayeeType type;
  final double totalIn;
  final double totalOut;
  final int transactionCount;
  final String icon;
  final String label;

  const CashflowSummary({
    required this.type,
    required this.totalIn,
    required this.totalOut,
    required this.transactionCount,
    required this.icon,
    required this.label,
  });
}

// ── Payee type classifier ──────────────────────────────────────────────────────

PayeeType _classify(Transaction t) {
  final text = '${t.merchant} ${t.note ?? ''}'.toLowerCase();

  // Salary / payroll
  if (_anyMatch(text, ['salary', 'payroll', 'employer', 'ctc', 'stipend', 'wages'])) {
    return PayeeType.salary;
  }

  // Rent / housing
  if (_anyMatch(text, ['rent', 'landlord', 'housing', 'house rent', 'pg ', 'hostel', 'maintenance society'])) {
    return PayeeType.rent;
  }

  // Loan / EMI
  if (_anyMatch(text, ['emi', 'loan', 'lender', 'home loan', 'car loan', 'personal loan', 'repayment', 'bajaj finserv', 'hdfc loan', 'icici loan'])) {
    return PayeeType.loanEmi;
  }

  // Utilities
  if (_anyMatch(text, ['electricity', 'electric board', 'water bill', 'gas', 'broadband', 'internet bill', 'bsnl', 'jio fiber', 'airtel broadband', 'tata power', 'msedcl', 'bescom', 'piped gas', 'lpg'])) {
    return PayeeType.utilities;
  }

  // Family (Indian-specific keywords included)
  if (_anyMatch(text, ['mom', 'dad', 'papa', 'mummy', 'mother', 'father', 'brother', 'sister', 'bhai', 'didi', 'nana', 'nani', 'dada', 'dadi', 'uncle', 'aunty', 'chacha', 'chachi', 'mama', 'maasi', 'bhabhi', 'jiju', 'sasural', 'family'])) {
    return PayeeType.family;
  }

  // Friends / P2P (UPI person transfers)
  // Round amounts + P2P transfer keywords strongly suggest person transfer
  final isRoundAmount = t.amount % 10 == 0;
  final hasP2PKeyword = _anyMatch(text, ['sent to', 'paid to', 'transfer to', 'upi/', '@okaxis', '@oksbi', '@okicici', '@okhdfcbank', '@ybl', '@ibl', '@paytm', '@apl', '@fam', 'phonepe', 'gpay', 'google pay', 'paytm']);

  if (hasP2PKeyword && isRoundAmount && t.amount < 50000) {
    return PayeeType.friends;
  }

  // Personal name heuristic — short single-word merchants that don't match
  // known business patterns may be person UPI IDs
  final merchantWords = t.merchant.trim().split(RegExp(r'\s+')).length;
  final looksLikePersonName = merchantWords <= 2 &&
      !_anyMatch(text, ['pvt', 'ltd', 'llp', 'inc', 'corp', 'store', 'shop', 'mart', 'cafe', 'restaurant', 'hotel', 'hospital', 'clinic', 'amazon', 'flipkart', 'swiggy', 'zomato', 'uber', 'ola', 'netflix', 'spotify', 'apple', 'google']);

  if (looksLikePersonName && hasP2PKeyword) {
    return PayeeType.friends;
  }

  return PayeeType.merchant;
}

bool _anyMatch(String text, List<String> keywords) =>
    keywords.any((k) => text.contains(k));

// ── Providers ─────────────────────────────────────────────────────────────────

/// All current-month transactions grouped into CashflowSummary per PayeeType,
/// sorted by totalOut descending.
final cashflowSummaryProvider = FutureProvider<List<CashflowSummary>>((ref) async {
  ref.watch(transactionCacheProvider);

  final now = DateTime.now();
  final txns = HiveService.transactions.values
      .where((t) =>
          !t.isIgnored &&
          t.transactionDate.year == now.year &&
          t.transactionDate.month == now.month)
      .toList();

  final bucketIn = <PayeeType, double>{};
  final bucketOut = <PayeeType, double>{};
  final bucketCount = <PayeeType, int>{};

  for (final type in PayeeType.values) {
    bucketIn[type] = 0;
    bucketOut[type] = 0;
    bucketCount[type] = 0;
  }

  for (final t in txns) {
    final type = _classify(t);
    bucketCount[type] = (bucketCount[type] ?? 0) + 1;
    if (t.isCredit) {
      bucketIn[type] = (bucketIn[type] ?? 0) + t.amount;
    } else {
      bucketOut[type] = (bucketOut[type] ?? 0) + t.amount;
    }
  }

  final result = PayeeType.values
      .where((type) => (bucketCount[type] ?? 0) > 0)
      .map((type) => CashflowSummary(
            type: type,
            totalIn: bucketIn[type] ?? 0,
            totalOut: bucketOut[type] ?? 0,
            transactionCount: bucketCount[type] ?? 0,
            icon: type.icon,
            label: type.label,
          ))
      .toList()
    ..sort((a, b) => b.totalOut.compareTo(a.totalOut));

  return result;
});

/// Filtered list of current-month transactions for a specific PayeeType.
final cashflowTransactionsProvider =
    FutureProvider.family<List<Transaction>, PayeeType>((ref, payeeType) async {
  ref.watch(transactionCacheProvider);

  final now = DateTime.now();
  return HiveService.transactions.values
      .where((t) =>
          !t.isIgnored &&
          t.transactionDate.year == now.year &&
          t.transactionDate.month == now.month &&
          _classify(t) == payeeType)
      .toList()
    ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
});
