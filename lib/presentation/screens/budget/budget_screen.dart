import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../providers/budget_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/category_engine.dart';
import '../../../data/local/hive_service.dart';
import '../../../domain/models/budget.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  Future<void> _showSetBudgetDialog({String? prefillCategory, double? currentLimit}) async {
    final formKey = GlobalKey<FormState>();
    String? selectedCategory = prefillCategory;
    bool _saving = false; // prevents double-tap race on Save
    final amountController = TextEditingController(
      text: currentLimit != null && currentLimit > 0 ? currentLimit.toStringAsFixed(0) : '',
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.cardBorderColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      prefillCategory != null ? 'Edit Budget' : 'Set Budget',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Set a monthly spending limit for a category',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted),
                    ),
                    const SizedBox(height: 20),

                    // Category selector
                    if (prefillCategory == null) ...[
                      Text('Category', style: Theme.of(context).textTheme.labelLarge),
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
                            value: selectedCategory,
                            isExpanded: true,
                            hint: Text('Select category', style: TextStyle(color: context.textMuted)),
                            dropdownColor: context.cardColor,
                            items: CategoryEngine.expenseCategories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Row(
                                  children: [
                                    Text(CategoryEngine.getCategoryIcon(cat)),
                                    const SizedBox(width: 8),
                                    Text(cat, style: Theme.of(context).textTheme.bodyMedium),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setModalState(() => selectedCategory = val),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      Row(
                        children: [
                          Text(CategoryEngine.getCategoryIcon(prefillCategory), style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(prefillCategory, style: Theme.of(context).textTheme.labelLarge),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Amount input
                    Text('Monthly Limit (₹)', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      autofocus: prefillCategory != null,
                      decoration: const InputDecoration(
                        prefixText: '₹ ',
                        hintText: '5000',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter an amount';
                        if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Enter a valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : () async {
                          if (!formKey.currentState!.validate()) return;
                          if (selectedCategory == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select a category')),
                            );
                            return;
                          }

                          setModalState(() => _saving = true);

                          final now = DateTime.now();
                          final monthYear = '${now.year}-${now.month.toString().padLeft(2, '0')}';
                          final amount = double.parse(amountController.text);

                          // Overwrite existing or create new
                          final existing = HiveService.budgets.values
                              .where((b) => b.category == selectedCategory && b.monthYear == monthYear)
                              .toList();

                          if (existing.isNotEmpty) {
                            existing.first.monthlyLimit = amount;
                            await existing.first.save();
                          } else {
                            final budget = Budget(
                              id: const Uuid().v4(),
                              category: selectedCategory!,
                              monthlyLimit: amount,
                              monthYear: monthYear,
                              isSynced: false,
                            );
                            await HiveService.budgets.put(budget.id, budget);
                          }

                          ref.invalidate(budgetsProvider);
                          ref.invalidate(allCategoriesSpendingProvider);

                          if (context.mounted) Navigator.pop(ctx);
                        },
                        child: _saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save Budget'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allCatsAsync = ref.watch(allCategoriesSpendingProvider);
    final overBudgetAsync = ref.watch(overBudgetCategoriesProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Budget', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 2),
                  Text(
                    'Monthly spending limits',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: allCatsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Error loading')),
                data: (categories) {
                  if (categories.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('📊', style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions yet',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your spending will appear here once transactions are tracked. Tap + to set a budget manually.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: context.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    children: [
                      // Over budget banner
                      overBudgetAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (over) {
                          if (over.isEmpty) return const SizedBox.shrink();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: context.errorBgColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Text('⚠️', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Over budget in ${over.length} categor${over.length == 1 ? 'y' : 'ies'}: ${over.join(', ')}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      ...categories.map((item) => _BudgetCard(
                            category: item.category,
                            spent: item.spent,
                            limit: item.limit,
                            onEdit: () => _showSetBudgetDialog(
                              prefillCategory: item.category,
                              currentLimit: item.limit,
                            ),
                          )),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSetBudgetDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Set Budget'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final String category;
  final double spent;
  final double? limit;
  final VoidCallback onEdit;
  const _BudgetCard({
    required this.category,
    required this.spent,
    required this.limit,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final color = CategoryEngine.getCategoryFlutterColor(category);
    final icon = CategoryEngine.getCategoryIcon(category);
    final hasLimit = limit != null && limit! > 0;
    final percent = hasLimit ? (spent / limit!).clamp(0.0, 1.0) : 0.0;
    final isOver = hasLimit && spent > limit!;
    final remaining = hasLimit ? (limit! - spent).clamp(0.0, double.infinity) : 0.0;
    final ringColor = isOver ? AppColors.error : color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOver ? AppColors.error.withValues(alpha: 0.4) : context.cardBorderColor,
        ),
      ),
      child: Row(
        children: [
          // Circular ring with category icon
          SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(68, 68),
                  painter: _RingPainter(
                    progress: hasLimit ? percent : 0.0,
                    color: ringColor,
                    backgroundColor: context.cardBorderColor,
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Details column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(category, style: Theme.of(context).textTheme.labelLarge),
                    ),
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.cardBorderColor),
                        ),
                        child: Icon(Icons.edit_rounded, size: 13, color: context.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                if (hasLimit) ...[
                  Text(
                    '₹${_fmt(spent)} of ₹${_fmt(limit!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        '${(percent * 100).toStringAsFixed(0)}% used',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isOver ? AppColors.error : context.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        isOver
                            ? '₹${_fmt(spent - limit!)} over'
                            : '₹${_fmt(remaining)} left',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isOver ? AppColors.error : AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    'No limit set',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted),
                  ),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: onEdit,
                    child: Text(
                      '+ Tap to set a limit',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..color = color
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress.clamp(0.0, 1.0),
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

String _fmt(double amount) {
  if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
  return amount.toStringAsFixed(0);
}
