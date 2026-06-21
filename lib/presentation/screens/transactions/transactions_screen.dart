import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/category_engine.dart';
import '../../../data/local/hive_service.dart';
import '../../../domain/models/transaction.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedPayee;
  // 'all' | 'income' | 'expense'
  String _typeFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showPeopleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (ctx, controller) {
          final peopleAsync = ref.watch(peopleSummaryProvider);
          return Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: context.cardBorderColor,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text('👥', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Text('People',
                        style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('sent / received',
                        style: TextStyle(
                            color: context.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: peopleAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('—')),
                  data: (people) {
                    if (people.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text(
                            'No person-to-person transfers yet.\nUPI payments to '
                            'friends & family will show up here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: context.textSecondary, height: 1.5),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: people.length,
                      itemBuilder: (_, i) {
                        final p = people[i];
                        final net = p.received - p.sent;
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            _searchController.text = p.name;
                            setState(() => _searchQuery = p.name);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: context.cardBorderColor),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.15),
                                  child: Text(
                                    p.name.isNotEmpty
                                        ? p.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: context.textPrimary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 3),
                                      Text(
                                        '↑ ₹${_fmtAmt(p.sent)}  ·  ↓ ₹${_fmtAmt(p.received)}  ·  ${p.count} txns',
                                        style: TextStyle(
                                            color: context.textSecondary,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      net >= 0
                                          ? '+₹${_fmtAmt(net)}'
                                          : '-₹${_fmtAmt(-net)}',
                                      style: TextStyle(
                                          color: net >= 0
                                              ? AppColors.success
                                              : AppColors.error,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14),
                                    ),
                                    Text('net',
                                        style: TextStyle(
                                            color: context.textMuted,
                                            fontSize: 10)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _fmtAmt(double a) {
    if (a >= 100000) return '${(a / 100000).toStringAsFixed(1)}L';
    if (a >= 1000) return '${(a / 1000).toStringAsFixed(1)}K';
    return a.toStringAsFixed(0);
  }

  List<Transaction> _applyFilters(List<Transaction> txns) {
    return txns.where((t) {
      if (t.isIgnored) return false;
      final q = _searchQuery.toLowerCase();
      if (q.isNotEmpty &&
          !t.merchant.toLowerCase().contains(q) &&
          !t.category.toLowerCase().contains(q)) { return false; }
      if (_selectedCategory != null && t.category != _selectedCategory) { return false; }
      if (_selectedPayee != null && t.merchant != _selectedPayee) { return false; }
      if (_typeFilter == 'income' && !t.isCredit) return false;
      if (_typeFilter == 'expense' && t.isCredit) return false;
      return true;
    }).toList();
  }

  void _previousMonth() {
    final (year, month) = ref.read(selectedMonthProvider);
    if (month == 1) {
      ref.read(selectedMonthProvider.notifier).state = (year - 1, 12);
    } else {
      ref.read(selectedMonthProvider.notifier).state = (year, month - 1);
    }
  }

  void _nextMonth() {
    final now = DateTime.now();
    final (year, month) = ref.read(selectedMonthProvider);
    if (year == now.year && month == now.month) return;
    if (month == 12) {
      ref.read(selectedMonthProvider.notifier).state = (year + 1, 1);
    } else {
      ref.read(selectedMonthProvider.notifier).state = (year, month + 1);
    }
  }

  // ── Impulse safeguard: count today's transactions ─────────────────────────

  int _todayTransactionCount() {
    final today = DateTime.now();
    return HiveService.transactions.values.where((t) {
      final d = t.transactionDate;
      return d.year == today.year && d.month == today.month && d.day == today.day;
    }).length;
  }

  Future<bool> _passImpulseCheck() async {
    final count = _todayTransactionCount();
    if (count < 3) return true;
    final approved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ImpulseCountdownDialog(txnCount: count),
    );
    return approved == true;
  }

  // ── Quick-Add manual transaction ──────────────────────────────────────────

  Future<void> _showAddTransaction() async {
    final canProceed = await _passImpulseCheck();
    if (!canProceed || !mounted) return;
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final merchantCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String? selectedCategory;
    bool isCredit = false;
    DateTime selectedDate = DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Form(
              key: formKey,
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
                    Text('Add Transaction', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),

                    // Credit / Debit toggle
                    Row(
                      children: [
                        _TypeChip(
                          label: 'Expense',
                          icon: '↑',
                          selected: !isCredit,
                          color: AppColors.error,
                          onTap: () => setModal(() {
                            isCredit = false;
                            selectedCategory = null;
                          }),
                        ),
                        const SizedBox(width: 10),
                        _TypeChip(
                          label: 'Income',
                          icon: '↓',
                          selected: isCredit,
                          color: AppColors.success,
                          onTap: () => setModal(() {
                            isCredit = true;
                            selectedCategory = null;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Amount
                    TextFormField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                      decoration: const InputDecoration(prefixText: '₹  ', hintText: '0'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter amount';
                        if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Invalid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Merchant
                    TextFormField(
                      controller: merchantCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(hintText: 'Merchant or person name'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter a name' : null,
                    ),
                    const SizedBox(height: 12),

                    // Category dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.cardBorderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          hint: Text('Select category', style: TextStyle(color: context.textMuted)),
                          dropdownColor: context.cardColor,
                          items: (isCredit
                                  ? ['Income', 'Salary', 'Refund']
                                  : CategoryEngine.expenseCategories)
                              .map((cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Row(children: [
                                      Text(CategoryEngine.getCategoryIcon(cat)),
                                      const SizedBox(width: 8),
                                      Text(cat, style: Theme.of(context).textTheme.bodyMedium),
                                    ]),
                                  ))
                              .toList(),
                          onChanged: (v) => setModal(() => selectedCategory = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date picker
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setModal(() => selectedDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.cardBorderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 16, color: context.textMuted),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat('MMM d, yyyy').format(selectedDate),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Note (optional)
                    TextField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(hintText: 'Note (optional)'),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final merchant = merchantCtrl.text.trim();
                          final cat = selectedCategory ??
                              CategoryEngine.categorize(merchant, isCredit);

                          final tx = Transaction(
                            id: const Uuid().v4(),
                            amount: double.parse(amountCtrl.text),
                            merchant: merchant,
                            category: cat,
                            isCredit: isCredit,
                            transactionDate: selectedDate,
                            source: 'manual',
                            note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                            isSynced: false,
                            createdAt: DateTime.now(),
                          );
                          await HiveService.transactions.put(tx.id, tx);
                          HapticFeedback.heavyImpact();
                          ref.invalidate(transactionsProvider);
                          ref.invalidate(homeStatsProvider);
                          ref.invalidate(allTransactionsProvider);
                          ref.invalidate(selectedMonthTransactionsProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: const Text('Add Transaction'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Long-press: recategorize + add/edit note ──────────────────────────────

  Future<void> _showTransactionOptions(Transaction t) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TransactionOptionsSheet(
        transaction: t,
        onSaved: () {
          ref.invalidate(transactionsProvider);
          ref.invalidate(homeStatsProvider);
          ref.invalidate(allTransactionsProvider);
          ref.invalidate(allCategoriesSpendingProvider);
          ref.invalidate(selectedMonthTransactionsProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txnsAsync = ref.watch(selectedMonthTransactionsProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final now = DateTime.now();
    final isCurrentMonth = selectedMonth.$1 == now.year && selectedMonth.$2 == now.month;
    final monthLabel = DateFormat('MMMM yyyy').format(
        DateTime(selectedMonth.$1, selectedMonth.$2));

    final categories = txnsAsync.maybeWhen(
      data: (txns) => txns.map((t) => t.category).toSet().toList()..sort(),
      orElse: () => <String>[],
    );

    return Scaffold(
      backgroundColor: context.bgColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTransaction,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header + month switcher
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Text('Transactions', style: Theme.of(context).textTheme.headlineMedium),
                ],
              ),
            ),

            // Month navigation
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: _previousMonth,
                    color: context.textSecondary,
                    iconSize: 22,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        monthLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: isCurrentMonth ? null : _nextMonth,
                    color: isCurrentMonth ? context.cardBorderColor : context.textSecondary,
                    iconSize: 22,
                  ),
                ],
              ),
            ),

            // Type filter (All / Income / Expenses)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _typeFilter == 'all',
                    onTap: () => setState(() => _typeFilter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '↓ Income',
                    selected: _typeFilter == 'income',
                    onTap: () => setState(() => _typeFilter = 'income'),
                    selectedColor: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '↑ Expenses',
                    selected: _typeFilter == 'expense',
                    onTap: () => setState(() => _typeFilter = 'expense'),
                    selectedColor: AppColors.error,
                  ),
                ],
              ),
            ),

            // Search + People
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search people, merchants or categories…',
                        prefixIcon: Icon(Icons.search_rounded, color: context.textMuted, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded, color: context.textMuted, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // People view — net sent/received per person
                  GestureDetector(
                    onTap: _showPeopleSheet,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.cardBorderColor),
                      ),
                      child: Icon(Icons.people_alt_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                  ),
                ],
              ),
            ),

            // Category filter chips
            if (categories.isNotEmpty)
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                    ),
                    ...categories.map((cat) => _FilterChip(
                          label: '${CategoryEngine.getCategoryIcon(cat)} $cat',
                          selected: _selectedCategory == cat,
                          onTap: () => setState(() {
                            _selectedCategory = _selectedCategory == cat ? null : cat;
                          }),
                        )),
                  ],
                ),
              ),

            const SizedBox(height: 6),

            // Transaction list
            Expanded(
              child: txnsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text('Error loading', style: Theme.of(context).textTheme.bodyMedium),
                ),
                data: (txns) {
                  final filtered = _applyFilters(txns);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🔍', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty || _selectedCategory != null || _typeFilter != 'all'
                                ? 'No transactions match your filter'
                                : 'No transactions for this month',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: context.textSecondary,
                                ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _showAddTransaction,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add manually'),
                          ),
                        ],
                      ),
                    );
                  }

                  // Group by date
                  final grouped = <DateTime, List<Transaction>>{};
                  for (final t in filtered) {
                    final date = DateTime(t.transactionDate.year, t.transactionDate.month, t.transactionDate.day);
                    grouped.putIfAbsent(date, () => []).add(t);
                  }
                  final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
                  final today = DateTime.now();
                  final yesterday = today.subtract(const Duration(days: 1));

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                    itemCount: dates.length,
                    itemBuilder: (context, index) {
                      final date = dates[index];
                      final dayTxns = grouped[date]!;

                      String label;
                      if (date.year == today.year && date.month == today.month && date.day == today.day) {
                        label = 'Today';
                      } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
                        label = 'Yesterday';
                      } else {
                        label = DateFormat('MMM d, yyyy').format(date);
                      }

                      final dayDebit = dayTxns.where((t) => !t.isCredit).fold(0.0, (s, t) => s + t.amount);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(label,
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: context.textMuted)),
                                if (dayDebit > 0)
                                  Text('-₹${_fmt(dayDebit)}',
                                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: context.textMuted)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: context.cardBorderColor),
                              ),
                              child: Column(
                                children: dayTxns.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final t = entry.value;
                                  final color = CategoryEngine.getCategoryFlutterColor(t.category);
                                  final icon = CategoryEngine.getCategoryIcon(t.category);
                                  return Column(
                                    key: ValueKey(t.id),
                                    children: [
                                      Dismissible(
                                        key: Key('dismiss_${t.id}'),
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.only(right: 20),
                                          decoration: BoxDecoration(
                                            color: AppColors.error.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.not_interested_rounded,
                                                  color: AppColors.error, size: 20),
                                              const SizedBox(height: 2),
                                              const Text('Ignore',
                                                  style: TextStyle(
                                                      color: AppColors.error,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w700)),
                                            ],
                                          ),
                                        ),
                                        confirmDismiss: (_) async {
                                          return await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              backgroundColor: context.cardColor,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20)),
                                              title: Text('Ignore Transaction?',
                                                  style: Theme.of(context).textTheme.headlineSmall),
                                              content: Text(
                                                'This transaction won\'t affect your totals or budgets.',
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                      backgroundColor: AppColors.error),
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  child: const Text('Ignore'),
                                                ),
                                              ],
                                            ),
                                          ) ??
                                              false;
                                        },
                                        onDismissed: (_) async {
                                          t.isIgnored = true;
                                          await t.save();
                                          if (!context.mounted) return;
                                          ref.invalidate(transactionsProvider);
                                          ref.invalidate(homeStatsProvider);
                                          ref.invalidate(allTransactionsProvider);
                                          ref.invalidate(selectedMonthTransactionsProvider);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('${t.merchant} ignored'),
                                                action: SnackBarAction(
                                                  label: 'Undo',
                                                  onPressed: () async {
                                                    t.isIgnored = false;
                                                    await t.save();
                                                    ref.invalidate(transactionsProvider);
                                                    ref.invalidate(homeStatsProvider);
                                                    ref.invalidate(allTransactionsProvider);
                                                    ref.invalidate(selectedMonthTransactionsProvider);
                                                  },
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: InkWell(
                                        onLongPress: () => _showTransactionOptions(t),
                                        borderRadius: BorderRadius.circular(16),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 42,
                                                height: 42,
                                                decoration: BoxDecoration(
                                                  color: color.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(t.merchant,
                                                        style: Theme.of(context).textTheme.labelLarge,
                                                        overflow: TextOverflow.ellipsis),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: color.withValues(alpha: 0.12),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            t.category,
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w600,
                                                              color: color,
                                                            ),
                                                          ),
                                                        ),
                                                        if (t.note != null && t.note!.isNotEmpty) ...[
                                                          const SizedBox(width: 6),
                                                          Expanded(
                                                            child: Text(
                                                              t.note!,
                                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                                    color: context.textMuted,
                                                                    fontStyle: FontStyle.italic,
                                                                  ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        t.isCredit
                                                            ? Icons.arrow_downward_rounded
                                                            : Icons.arrow_upward_rounded,
                                                        size: 10,
                                                        color: t.isCredit ? AppColors.success : AppColors.error,
                                                      ),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        '₹${_fmt(t.amount)}',
                                                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                                              color: t.isCredit ? AppColors.success : AppColors.error,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    DateFormat('h:mm a').format(t.transactionDate),
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                          color: context.textMuted,
                                                          fontSize: 10,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      ), // end Dismissible
                                      if (i < dayTxns.length - 1)
                                        Divider(height: 1, color: context.cardBorderColor, indent: 70),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transaction options bottom sheet (recategorize + note) ───────────────────

class _TransactionOptionsSheet extends ConsumerStatefulWidget {
  final Transaction transaction;
  final VoidCallback onSaved;
  const _TransactionOptionsSheet({required this.transaction, required this.onSaved});

  @override
  ConsumerState<_TransactionOptionsSheet> createState() => _TransactionOptionsSheetState();
}

class _TransactionOptionsSheetState extends ConsumerState<_TransactionOptionsSheet> {
  late String _selectedCategory;
  late TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.transaction.category;
    _noteCtrl = TextEditingController(text: widget.transaction.note ?? '');
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = CategoryEngine.getCategoryFlutterColor(_selectedCategory);

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: context.cardBorderColor, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    CategoryEngine.getCategoryIcon(_selectedCategory),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.transaction.merchant, style: Theme.of(context).textTheme.labelLarge),
                    Text(
                      '${widget.transaction.isCredit ? 'Received' : 'Spent'} ₹${widget.transaction.amount.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: widget.transaction.isCredit ? AppColors.success : AppColors.error,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Change Category', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.cardBorderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                dropdownColor: context.cardColor,
                items: (widget.transaction.isCredit
                        ? ['Income', 'Salary', 'Refund']
                        : CategoryEngine.expenseCategories)
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Row(children: [
                            Text(CategoryEngine.getCategoryIcon(cat)),
                            const SizedBox(width: 8),
                            Text(cat, style: Theme.of(context).textTheme.bodyMedium),
                          ]),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Note', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(hintText: 'Add a note…'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    widget.transaction.category = _selectedCategory;
                    widget.transaction.note = _noteCtrl.text.trim().isEmpty
                        ? null
                        : _noteCtrl.text.trim();
                    await widget.transaction.save();
                    widget.onSaved();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Impulse Check Countdown Dialog ───────────────────────────────────────────

class _ImpulseCountdownDialog extends StatefulWidget {
  final int txnCount;
  const _ImpulseCountdownDialog({required this.txnCount});
  @override
  State<_ImpulseCountdownDialog> createState() => _ImpulseCountdownDialogState();
}

class _ImpulseCountdownDialogState extends State<_ImpulseCountdownDialog> {
  int _remaining = 5;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_remaining <= 1) {
        t.cancel();
        Navigator.of(context).pop(true);
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Spending Check'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'You\'ve already logged ${widget.txnCount} transactions today.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Take a moment — continuing in',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_remaining',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label, icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : context.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : context.cardBorderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              icon,
              style: TextStyle(
                color: selected ? color : context.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : context.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isAction;
  final Color? selectedColor;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isAction = false,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = selectedColor ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? activeColor
              : isAction
                  ? AppColors.error.withValues(alpha: 0.1)
                  : context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? activeColor
                : isAction
                    ? AppColors.error.withValues(alpha: 0.3)
                    : context.cardBorderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected
                ? Colors.white
                : isAction
                    ? AppColors.error
                    : context.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

String _fmt(double amount) {
  if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
  return amount.toStringAsFixed(0);
}
