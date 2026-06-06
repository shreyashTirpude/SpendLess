import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/insights_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(insightCardsProvider);
    final merchants = ref.watch(topMerchantsProvider);
    final totalSpent = ref.watch(totalSpentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Smart Insights', style: AppTextStyles.headingSmall),
          const SizedBox(height: 12),
          insights.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Error'),
            data: (insightList) {
              return Column(
                children: insightList.map((insight) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(insight, style: AppTextStyles.bodySmall),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Top Merchants', style: AppTextStyles.headingSmall),
          const SizedBox(height: 12),
          merchants.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Error'),
            data: (merchantList) {
              return Column(
                children: merchantList.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final (merchant, count) = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '$index',
                              style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(merchant, style: AppTextStyles.bodySmall),
                        ),
                        Text(
                          '$count txns',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          totalSpent.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (spent) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.success),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This Month Summary',
                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.success),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${spent.toStringAsFixed(0)} spent',
                      style: AppTextStyles.headingMedium,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
