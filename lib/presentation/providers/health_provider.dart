import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'transaction_provider.dart';
import 'budget_provider.dart';

typedef HealthData = ({
  int score,
  String grade,
  String tip,
  double savingsRate,
  double budgetAdherence,
  double spentVsIncomeRatio,
});

final healthScoreProvider = FutureProvider<HealthData>((ref) async {
  final stats = await ref.watch(homeStatsProvider.future);
  final categoryData = await ref.watch(allCategoriesSpendingProvider.future);

  // Early return for new/empty users — no data means no score yet
  if (stats.totalSpent == 0 && stats.totalIncome == 0) {
    return (
      score: 0,
      grade: 'No Data',
      tip: 'SpendLens will score your finances once transactions are detected.',
      savingsRate: 0.0,
      budgetAdherence: 0.0,
      spentVsIncomeRatio: 0.0,
    );
  }

  // Component 1: Savings rate 0–50 pts
  // 0.0 when no income (honest — we don't know savings rate without income data)
  double savingsRate = 0.0;
  if (stats.totalIncome > 0) {
    savingsRate =
        ((stats.totalIncome - stats.totalSpent) / stats.totalIncome)
            .clamp(0.0, 1.0);
  }
  final savingsScore = savingsRate * 50;

  // Component 2: Budget adherence 0–30 pts
  // 0.5 (neutral) when no budgets are set — not 1.0 which would falsely inflate the score
  double budgetAdherence = 0.5;
  int totalWithBudget = 0;
  int withinBudget = 0;
  for (final row in categoryData) {
    if (row.limit != null && row.limit! > 0) {
      totalWithBudget++;
      if (row.spent <= row.limit!) withinBudget++;
    }
  }
  if (totalWithBudget > 0) {
    budgetAdherence = withinBudget / totalWithBudget;
  }
  final budgetScore = budgetAdherence * 30;

  // Component 3: Income tracked bonus 0–20 pts
  final incomeScore = stats.totalIncome > 0 ? 20.0 : 0.0;

  final score =
      (savingsScore + budgetScore + incomeScore).round().clamp(0, 100);

  final spentVsIncomeRatio = stats.totalIncome > 0
      ? (stats.totalSpent / stats.totalIncome).clamp(0.0, 2.0)
      : 0.0;

  String grade;
  String tip;
  if (score >= 85) {
    grade = 'Excellent';
    tip = 'Outstanding! You\'re on track for financial freedom.';
  } else if (score >= 70) {
    grade = 'Good';
    tip = 'Solid! A 10% cut in your top category boosts your score.';
  } else if (score >= 55) {
    grade = 'Fair';
    tip = 'Review your biggest spending category this month.';
  } else if (score >= 40) {
    grade = 'Needs Work';
    tip = 'Set budgets per category to gain control of spending.';
  } else {
    grade = 'Critical';
    tip = 'Spending is exceeding income — act now.';
  }

  return (
    score: score,
    grade: grade,
    tip: tip,
    savingsRate: savingsRate,
    budgetAdherence: budgetAdherence,
    spentVsIncomeRatio: spentVsIncomeRatio,
  );
});
