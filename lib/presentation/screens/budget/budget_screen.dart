import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/category_engine.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetsProvider);
    final categoryTotals = ref.watch(categoryTotalsProvider);
    final overBudget = ref.watch(overBudgetCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Budget')),
      body: budgets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error')),
        data: (budgetList) {
          return categoryTotals.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Error')),
            data: (totals) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  overBudget.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (over) {
                      if (over.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.errorBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.error),
                            ),
                            child: Row(
                              children: [
                                const Text('⚠️', style: TextStyle(fontSize: 20)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Over budget in ${over.length} categor${over.length == 1 ? 'y' : 'ies'}',
                                    style: AppTextStyles.labelMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  ...budgetList.map((budget) {
                    final spent = totals[budget.category] ?? 0;
                    final percent = budget.monthlyLimit > 0 ? spent / budget.monthlyLimit : 0;
                    final icon = CategoryEngine.getCategoryIcon(budget.category);
                    final color = Color(int.parse(
                      CategoryEngine.getCategoryColor(budget.category).replaceFirst('#', '0xFF'),
                    ));

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(icon, style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(budget.category, style: AppTextStyles.labelMedium),
                                ),
                                Text(
                                  '₹${spent.toStringAsFixed(0)}',
                                  style: AppTextStyles.labelMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percent.clamp(0.0, 1.0),
                                backgroundColor: AppColors.cardBorder,
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'of ₹${budget.monthlyLimit.toStringAsFixed(0)} limit',
                                  style: AppTextStyles.caption,
                                ),
                                Text(
                                  '₹${(budget.monthlyLimit - spent).clamp(0, double.infinity).toStringAsFixed(0)} remaining',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.success),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
