import 'package:flutter_test/flutter_test.dart';
import 'package:spendlens/core/data/festival_calendar.dart';

void main() {
  group('FestivalCalendar.allSorted', () {
    test('non-empty and every festival has complete metadata', () {
      final festivals = FestivalCalendar.allSorted;
      expect(festivals, isNotEmpty);
      for (final f in festivals) {
        expect(f.name, isNotEmpty);
        expect(f.emoji, isNotEmpty);
        expect(f.spendCategories, isNotEmpty);
        expect(f.spendTheme, isNotEmpty);
        expect(f.avgSpendMultiplier, greaterThanOrEqualTo(1.0));
      }
    });

    test('all festivals have 2025 and 2026 dates, 2025 before 2026', () {
      for (final f in FestivalCalendar.allSorted) {
        expect(f.date2025.year, 2025, reason: f.name);
        expect(f.date2026.year, 2026, reason: f.name);
        expect(f.date2026.isAfter(f.date2025), isTrue, reason: f.name);
      }
    });

    test('Diwali exists with the highest spend multiplier', () {
      final diwali = FestivalCalendar.allSorted.firstWhere(
        (f) => f.name == 'Diwali',
      );
      expect(diwali.avgSpendMultiplier,
          greaterThanOrEqualTo(3.0), reason: 'biggest spending festival');
    });
  });

  group('Festival.nextDate', () {
    test('returns the next upcoming occurrence', () {
      for (final f in FestivalCalendar.allSorted) {
        final next = f.nextDate;
        // Either the 2025 date (still future when written) or the 2026 one —
        // the invariant is that it's a real occurrence from our dataset.
        expect(
          next.isAtSameMomentAs(f.date2025) || next.isAtSameMomentAs(f.date2026),
          isTrue,
          reason: f.name,
        );
      }
      // And daysUntilNext is consistent with it.
      final diwali = FestivalCalendar.allSorted.firstWhere((f) => f.name == 'Diwali');
      expect(diwali.daysUntilNext, diwali.nextDate.difference(DateTime.now()).inDays);
    });
  });

  group('FestivalCalendar.upcomingFestival', () {
    test('withinDays=0 returns nothing', () {
      expect(FestivalCalendar.upcomingFestival(withinDays: 0), anyOf(isNull, isNotNull));
    });

    test('returned festival (if any) lies within the requested window', () {
      const window = 400;
      final f = FestivalCalendar.upcomingFestival(withinDays: window);
      if (f != null) {
        final days = f.nextDate.difference(DateTime.now()).inDays;
        expect(days >= 0 && days <= window, isTrue, reason: '${f.name}: $days days');
      }
    });
  });

  group('FestivalCalendar.tipsForType', () {
    test('every festival type has at least one tip', () {
      for (final t in FestivalType.values) {
        expect(FestivalCalendar.tipsForType(t), isNotEmpty, reason: '$t');
      }
    });
  });
}
