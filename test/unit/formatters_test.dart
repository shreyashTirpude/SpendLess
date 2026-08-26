import 'package:flutter_test/flutter_test.dart';
import 'package:spendlens/core/utils/formatters.dart';

void main() {
  group('AppFormatters.formatCurrency', () {
    test('formats Indian lakh grouping', () {
      expect(AppFormatters.formatCurrency(123456), '₹1,23,456');
    });

    test('formats crore grouping', () {
      expect(AppFormatters.formatCurrency(12345678), '₹1,23,45,678');
    });

    test('simple thousands', () {
      expect(AppFormatters.formatCurrency(4500), '₹4,500');
    });

    test('small amounts get no separator', () {
      expect(AppFormatters.formatCurrency(999), '₹999');
    });

    test('zero', () {
      expect(AppFormatters.formatCurrency(0), '₹0');
    });
  });

  group('AppFormatters date helpers', () {
    test('formatDate uses MMM d, yyyy', () {
      expect(AppFormatters.formatDate(DateTime(2024, 6, 5)), 'Jun 5, 2024');
    });

    test('formatTime uses h:mm a', () {
      expect(AppFormatters.formatTime(DateTime(2024, 6, 5, 9, 5)), '9:05 AM');
      expect(AppFormatters.formatTime(DateTime(2024, 6, 5, 17, 30)), '5:30 PM');
    });

    test('formatDateShort — Today / Yesterday / fallback', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      expect(AppFormatters.formatDateShort(today), 'Today');
      expect(
        AppFormatters.formatDateShort(today.subtract(const Duration(days: 1))),
        'Yesterday',
      );
      // A date far in the past falls back to month-day formatting.
      final old = DateTime(2023, 12, 7);
      expect(AppFormatters.formatDateShort(old), 'Dec 7');
    });

    test('formatMonth uses MMMM yyyy', () {
      expect(AppFormatters.formatMonth(DateTime(2024, 6, 1)), 'June 2024');
    });

    test('formatMonthYear zero-pads the month', () {
      expect(AppFormatters.formatMonthYear(2024, 1), '2024-01');
      expect(AppFormatters.formatMonthYear(2024, 11), '2024-11');
    });
  });
}
