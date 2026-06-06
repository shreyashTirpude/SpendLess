import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
// import '../../widgets/common/loading_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spent = ref.watch(totalSpentProvider);
    final income = ref.watch(totalIncomeProvider);
    final dailyData = ref.watch(dailySpendProvider);
    final categoryTotals = ref.watch(categoryTotalsProvider);
    final transactions = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
      ),
      body: spent.when(
        loading: () => const CircularProgressIndicator(),
        error: (_, __) => Center(child: Text('Error loading data')),
        data: (spentAmount) {
          return income.when(
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => Center(child: Text('Error')),
            data: (incomeAmount) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Spent/Income cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildCard(
                          title: 'SPENT',
                          amount: '₹${spentAmount.toStringAsFixed(0)}',
                          subtitle: 'this month',
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCard(
                          title: 'INCOME',
                          amount: '₹${incomeAmount.toStringAsFixed(0)}',
                          subtitle: 'this month',
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recent transactions
                  Text('Recent Transactions', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 12),
                  transactions.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Error'),
                    data: (txns) {
                      return Column(
                        children: txns.take(5).map((t) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Text('💳', style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(t.merchant, style: AppTextStyles.labelMedium),
                                        Text(t.category, style: AppTextStyles.caption),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${t.isCredit ? '+' : '-'}₹${t.amount}',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: t.isCredit ? AppColors.success : AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String amount,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Text(amount, style: AppTextStyles.headingMedium.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
