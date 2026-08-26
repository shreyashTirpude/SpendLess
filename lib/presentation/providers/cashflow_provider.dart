import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/hive_service.dart';
import '../../domain/models/transaction.dart';
import '../../core/utils/contact_classifier.dart';
import 'cache_provider.dart';

// ── Payee type enum ────────────────────────────────────────────────────────────

enum PayeeType {
  salary,
  rent,
  friends,
  family,
  loanEmi,
  utilities,
  subscriptions,
  merchant,
}

extension PayeeTypeX on PayeeType {
  String get label => switch (this) {
        PayeeType.salary        => 'Salary',
        PayeeType.rent          => 'Rent',
        PayeeType.friends       => 'Friends',
        PayeeType.family        => 'Family',
        PayeeType.loanEmi       => 'Loan / EMI',
        PayeeType.utilities     => 'Utilities',
        PayeeType.subscriptions => 'Subscriptions',
        PayeeType.merchant      => 'Merchants',
      };

  String get icon => switch (this) {
        PayeeType.salary        => '💼',
        PayeeType.rent          => '🏠',
        PayeeType.friends       => '👥',
        PayeeType.family        => '👨‍👩‍👧',
        PayeeType.loanEmi       => '🏦',
        PayeeType.utilities     => '⚡',
        PayeeType.subscriptions => '📺',
        PayeeType.merchant      => '🛍️',
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
  final text = '${t.merchant} ${t.note ?? ''} ${t.category}'.toLowerCase();

  // ── Salary / payroll (credit only) ────────────────────────────────────────
  if (t.isCredit) {
    if (_anyMatch(text, [
      'salary', 'payroll', 'employer', 'ctc', 'stipend', 'wages',
      'sal/', '/sal', 'sal-', 'sal credit', 'monthly pay',
    ])) {
      return PayeeType.salary;
    }
  }

  // ── Rent ─────────────────────────────────────────────────────────────────
  if (_anyMatch(text, [
    'rent', 'landlord', 'housing', 'house rent', 'pg ', 'hostel',
    'flat rent', 'room rent', 'society maintenance',
  ])) {
    return PayeeType.rent;
  }

  // ── Loan / EMI ────────────────────────────────────────────────────────────
  if (_anyMatch(text, [
    'emi', 'loan', 'lender', 'home loan', 'car loan', 'personal loan',
    'repayment', 'bajaj finserv', 'hdfc loan', 'icici loan',
    'vehicle loan', 'education loan', 'loan emi', 'nach', 'ecs debit',
  ])) {
    return PayeeType.loanEmi;
  }

  // ── Subscriptions ─────────────────────────────────────────────────────────
  if (t.category == 'Subscriptions' ||
      _anyMatch(text, [
        'netflix', 'spotify', 'hotstar', 'amazon prime', 'zee5', 'sonyliv',
        'youtube premium', 'apple music', 'icloud', 'google one', 'notion',
        'adobe', 'microsoft 365', 'membership', 'subscription',
      ])) {
    return PayeeType.subscriptions;
  }

  // ── Utilities ─────────────────────────────────────────────────────────────
  if (t.category == 'Bills & Utilities' ||
      _anyMatch(text, [
        'electricity', 'bescom', 'msedcl', 'tata power', 'water bill',
        'gas cylinder', 'indane', 'hp gas', 'bharat gas', 'piped gas',
        'airtel', 'jio', 'vi ', 'vodafone', 'bsnl',
        'broadband', 'internet bill', 'mobile bill', 'recharge',
        'dish tv', 'tata play', 'd2h ', 'sun direct', 'cable tv',
        'maintenance', 'society fee',
      ])) {
    return PayeeType.utilities;
  }

  // ── Family (Indian relationship keywords + contact-based) ─────────────────
  if (_anyMatch(text, [
    'mom', 'dad', 'papa', 'mummy', 'mother', 'father',
    'brother', 'sister', 'bhai', 'didi', 'dada', 'dadi',
    'nana', 'nani', 'uncle', 'aunty', 'chacha', 'chachi',
    'mama ', 'maasi', 'bhabhi', 'jiju', 'sasural',
  ])) {
    return PayeeType.family;
  }

  // Contact-based classification (lazy — only if ContactClassifier is loaded)
  if (ContactClassifier().isLoaded) {
    final relation = _contactRelationFor(t);
    if (relation == ContactRelation.family) return PayeeType.family;
    if (relation == ContactRelation.friends) {
      // Only promote to "friends" if this is a P2P transaction
      if (_isP2P(t)) return PayeeType.friends;
    }
  }

  // ── Friends / P2P transfer (VPA + heuristic) ─────────────────────────────
  if (_isP2P(t)) return PayeeType.friends;

  // ── Merchant fallback ─────────────────────────────────────────────────────
  return PayeeType.merchant;
}

/// Extracts VPA from note field ("vpa:rahul.sharma@ybl") and classifies.
ContactRelation _contactRelationFor(Transaction t) {
  final classifier = ContactClassifier();

  // Try merchant name directly
  final rel = classifier.classify(t.merchant);
  if (rel != ContactRelation.unknown) return rel;

  // Try VPA local-part (e.g. "rahul.sharma@ybl" → "rahul sharma")
  final vpa = _extractVpaFromNote(t.note);
  if (vpa != null) {
    final localPart = vpa.split('@').first
        .replaceAll(RegExp(r'[\d.\-_]'), ' ')
        .trim();
    return classifier.classify(localPart);
  }

  return ContactRelation.unknown;
}

String? _extractVpaFromNote(String? note) {
  if (note == null) return null;
  if (note.startsWith('vpa:')) return note.substring(4);
  return null;
}

bool _isP2P(Transaction t) {
  final text = '${t.merchant} ${t.note ?? ''} ${t.category}'.toLowerCase();

  // Category already flagged as Send Money
  if (t.category == 'Send Money' || t.category == 'Friends' || t.category == 'Family') {
    return true;
  }

  // VPA in note with personal suffix
  final vpa = _extractVpaFromNote(t.note);
  if (vpa != null) {
    final suffix = vpa.split('@').last.toLowerCase();
    const personalSuffixes = {
      'ybl', 'ibl', 'axl', 'oksbi', 'okaxis', 'okicici', 'okhdfcbank',
      'paytm', 'upi', 'apl', 'sbi', 'icici', 'hdfcbank', 'axisbank',
    };
    final prefix = vpa.split('@').first;
    // Mobile number prefix = definitely P2P
    if (RegExp(r'^\d{10}$').hasMatch(prefix)) return true;
    if (personalSuffixes.contains(suffix)) {
      // Exclude known merchant prefixes
      const merchantPrefixes = [
        'zomato', 'swiggy', 'uber', 'ola', 'amazon', 'flipkart', 'netflix',
        'spotify', 'hotstar', 'jio', 'airtel', 'blinkit', 'zepto', 'bigbasket',
        'irctc', 'dominos', 'kfc', 'mcdonalds', 'paytm', 'phonepe',
        'bookmyshow', 'pvr', 'inox', 'dream11', 'groww', 'zerodha',
      ];
      final alphaPrefix = prefix.replaceAll(RegExp(r'[\d.\-_]'), '');
      if (!merchantPrefixes.any((m) => alphaPrefix.startsWith(m))) return true;
    }
  }

  // P2P keyword + round amount heuristic
  final isRoundAmount = t.amount % 10 == 0 && t.amount < 100000;
  final hasP2PKeyword = _anyMatch(text, [
    'sent to', 'paid to', 'transfer to',
    'gpay', 'phonepe', 'google pay',
    '@okaxis', '@oksbi', '@okicici', '@okhdfcbank',
    '@ybl', '@ibl', '@axl', '@paytm',
  ]);

  if (hasP2PKeyword && isRoundAmount) return true;

  // Merchant looks like a person name (1-2 words, no business suffix)
  final merchantWords = t.merchant.trim().split(RegExp(r'\s+')).length;
  const businessTerms = [
    'pvt', 'ltd', 'llp', 'inc', 'corp', 'store', 'shop', 'mart',
    'cafe', 'restaurant', 'hotel', 'hospital', 'clinic',
    'amazon', 'flipkart', 'swiggy', 'zomato', 'uber', 'ola', 'netflix',
    'spotify', 'apple', 'google', 'hdfc', 'icici', 'sbi', 'axis',
  ];
  final looksLikePerson = merchantWords <= 2 && !_anyMatch(text, businessTerms);

  if (looksLikePerson && hasP2PKeyword) return true;

  return false;
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

  final bucketIn    = <PayeeType, double>{};
  final bucketOut   = <PayeeType, double>{};
  final bucketCount = <PayeeType, int>{};

  for (final type in PayeeType.values) {
    bucketIn[type]    = 0;
    bucketOut[type]   = 0;
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

  return PayeeType.values
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
