import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: transactions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading transactions')),
        data: (txns) {
          final grouped = <DateTime, List<dynamic>>{};
          for (final t in txns) {
            final date = DateTime(t.transactionDate.year, t.transactionDate.month, t.transactionDate.day);
            grouped.putIfAbsent(date, () => []).add(t);
          }

          final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final dayTxns = grouped[date]!;
              final dateLabel = DateFormat('MMM d, yyyy').format(date);
              final today = DateTime.now();
              final yesterday = today.subtract(const Duration(days: 1));

              String label;
              if (date.year == today.year && date.month == today.month && date.day == today.day) {
                label = 'Today';
              } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
                label = 'Yesterday';
              } else {
                label = dateLabel;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 12),
                  ...dayTxns.map((t) => _buildTransactionCard(t)),
                  const SizedBox(height: 24),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTransactionCard(dynamic t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('💳', style: TextStyle(fontSize: 18))),
          ),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${t.isCredit ? '+' : '-'}₹${t.amount}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: t.isCredit ? AppColors.success : AppColors.error,
                ),
              ),
              Text(
                DateFormat('h:mm a').format(t.transactionDate),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
