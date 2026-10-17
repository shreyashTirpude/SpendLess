/// Immutable boundaries of one salary cycle.
///
/// A cycle runs from a payday (inclusive, midnight) to the day before the
/// next payday (inclusive). The configured salary day is clamped to 1..31;
/// in months shorter than that day the payday lands on the month's last day.
///
/// The cycle end always derives from the *original* (clamped-to-31) salary
/// day, never from the clamped start day — a 31st salary that starts on
/// Feb 28 still ends on Mar 30, not Mar 27.
class SalaryCycle {
  /// First day of the cycle (midnight, inclusive).
  final DateTime start;

  /// Last day of the cycle (midnight, inclusive).
  final DateTime end;

  const SalaryCycle._(this.start, this.end);

  /// Payday of `[year, month]` for [day], clamped to the month's length.
  static DateTime _payday(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day < lastDay ? day : lastDay);
  }

  /// The cycle containing [now] for a salary paid on [salaryDay].
  ///
  /// [salaryDay] is clamped to 1..31 (values like 0 or 45 are normalized).
  /// Handles February/leap years, December→January rollover, and short
  /// months via per-month payday clamping.
  factory SalaryCycle.forDate(DateTime now, int salaryDay) {
    final day = salaryDay < 1 ? 1 : (salaryDay > 31 ? 31 : salaryDay);

    // Start: this month's payday if today is on/after it, else last month's.
    final thisMonthPayday = _payday(now.year, now.month, day);
    DateTime start;
    if (now.day >= thisMonthPayday.day) {
      start = thisMonthPayday;
    } else {
      final prev = DateTime(now.year, now.month - 1);
      start = _payday(prev.year, prev.month, day);
    }

    // End: day before the next payday, computed from the original salary day.
    final nextPayday = _payday(start.year, start.month + 1, day);
    final end =
        DateTime(nextPayday.year, nextPayday.month, nextPayday.day - 1);

    return SalaryCycle._(start, end);
  }
}
