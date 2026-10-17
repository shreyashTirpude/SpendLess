import 'package:flutter_test/flutter_test.dart';
import 'package:spendlens/core/utils/salary_cycle.dart';

// Value: protects=payday windows across short months and year transitions;
// fails_when=dates overflow or a clamped payday replaces the original day;
// why_new=no salary-cycle boundary tests existed; seam=none
void main() {
  final cases = [
    (DateTime(2025, 1, 31, 18), 31, DateTime(2025, 1, 31), DateTime(2025, 2, 27)),
    (DateTime(2024, 1, 31), 31, DateTime(2024, 1, 31), DateTime(2024, 2, 28)),
    (DateTime(2025, 3, 1), 31, DateTime(2025, 2, 28), DateTime(2025, 3, 30)),
    (DateTime(2025, 10, 18), 31, DateTime(2025, 9, 30), DateTime(2025, 10, 30)),
    (DateTime(2025, 12, 26), 25, DateTime(2025, 12, 25), DateTime(2026, 1, 24)),
    (DateTime(2026, 1, 1), 1, DateTime(2026, 1, 1), DateTime(2026, 1, 31)),
    (DateTime(2026, 1, 1), 0, DateTime(2026, 1, 1), DateTime(2026, 1, 31)),
    (DateTime(2025, 1, 31), 45, DateTime(2025, 1, 31), DateTime(2025, 2, 27)),
  ];
  for (final c in cases) {
    test('salary ${c.$2}, today ${c.$1}', () {
      final cycle = SalaryCycle.forDate(c.$1, c.$2);
      expect(cycle.start, c.$3);
      expect(cycle.end, c.$4);
    });
  }
}
