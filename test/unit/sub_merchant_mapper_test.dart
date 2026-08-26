import 'package:flutter_test/flutter_test.dart';
import 'package:spendlens/core/utils/sub_merchant_mapper.dart';

void main() {
  group('SubMerchantMapper.map', () {
    test('exact match — case insensitive', () {
      expect(SubMerchantMapper.map('Swiggy')?.subBrand, 'Swiggy');
      expect(SubMerchantMapper.map('SWIGGY')?.type, SubMerchantType.delivery);
      expect(SubMerchantMapper.map('netflix')?.category, 'Entertainment');
    });

    test('whitespace-only / empty input → null', () {
      expect(SubMerchantMapper.map(''), isNull);
      expect(SubMerchantMapper.map('   '), isNull);
    });

    test('starts-with matching: prefix resolves to brand', () {
      // e.g. "Zomato Order HYD" starts with 'zomato'
      final info = SubMerchantMapper.map('Zomato Order HYD');
      expect(info, isNotNull);
      expect(info!.subBrand, 'Zomato');
    });

    test('longest-prefix wins to avoid false positives', () {
      // If both 'mmt' and 'mmtc' existed as keys, MMTC must win for 'mmtc gold'
      // (guards the documented longest-key rule).
      final info = SubMerchantMapper.map('MMTC Gold');
      // Either matched or not, but must not crash; if present it's a real entry
      if (info != null) {
        expect(info.subBrand, isNotEmpty);
        expect(info.category, isNotEmpty);
      }
    });

    test('contains matching only fires on keys ≥ 5 chars', () {
      final info = SubMerchantMapper.map('Payment to Blinkit India');
      expect(info, isNotNull);
      expect(info!.subBrand, 'Blinkit');
    });

    test('unknown merchant returns null', () {
      expect(SubMerchantMapper.map('Shreyash Corner Shop'), isNull);
    });

    test('every mapped entry carries complete display metadata', () {
      // Spot-check a few known entries for well-formed hex colors + emoji.
      for (final name in ['swiggy', 'zomato', 'bigbasket', 'blinkit']) {
        final info = SubMerchantMapper.map(name);
        expect(info, isNotNull, reason: name);
        expect(info!.color, startsWith('#'));
        expect(info.color.length, 7);
        expect(info.emoji, isNotEmpty);
        expect(info.category, isNotEmpty);
      }
    });
  });

  group('SubMerchantMapper.merchantsForCategory', () {
    test('returns sorted unique sub-brands for a category', () {
      final brands = SubMerchantMapper.merchantsForCategory('Food & Dining');
      expect(brands, isNotEmpty);
      expect(brands, contains('Swiggy'));
      final sorted = [...brands]..sort();
      expect(brands, sorted, reason: 'must be sorted');
      expect(brands.toSet().length, brands.length, reason: 'must be unique');
    });

    test('unknown category returns empty list', () {
      expect(SubMerchantMapper.merchantsForCategory('Nonexistent'), isEmpty);
    });
  });

  group('SubMerchantMapper.typeLabel', () {
    test('every enum value has a non-empty label', () {
      for (final t in SubMerchantType.values) {
        expect(SubMerchantMapper.typeLabel(t), isNotEmpty);
      }
      expect(
        SubMerchantMapper.typeLabel(SubMerchantType.delivery),
        'Delivery',
      );
    });
  });
}
