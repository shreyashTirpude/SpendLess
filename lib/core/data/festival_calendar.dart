// Indian festival calendar with spend multipliers and planning data.

enum FestivalType { shopping, travel, gifting, food, mixed }

class Festival {
  final String name;
  final String emoji;
  final DateTime date2025;
  final DateTime date2026;
  final List<String> spendCategories;
  final String spendTheme;
  final double avgSpendMultiplier;
  final FestivalType type;

  const Festival({
    required this.name,
    required this.emoji,
    required this.date2025,
    required this.date2026,
    required this.spendCategories,
    required this.spendTheme,
    required this.avgSpendMultiplier,
    required this.type,
  });

  /// Returns the upcoming occurrence of this festival (2025 or 2026).
  DateTime get nextDate {
    final now = DateTime.now();
    if (date2025.isAfter(now)) return date2025;
    return date2026;
  }

  int get daysUntilNext => nextDate.difference(DateTime.now()).inDays;
}

class FestivalCalendar {
  static final List<Festival> _all = [
    Festival(
      name: 'Diwali',
      emoji: '🪔',
      date2025: DateTime(2025, 10, 20),
      date2026: DateTime(2026, 11, 8),
      spendCategories: ['Shopping', 'Food & Dining', 'Travel & Hotels'],
      spendTheme: 'Gifts, new clothes, firecrackers, sweets',
      avgSpendMultiplier: 3.5,
      type: FestivalType.mixed,
    ),
    Festival(
      name: 'Holi',
      emoji: '🌈',
      date2025: DateTime(2025, 3, 14),
      date2026: DateTime(2026, 3, 2),
      spendCategories: ['Food & Dining', 'Shopping'],
      spendTheme: 'Colors, sweets, new clothes',
      avgSpendMultiplier: 1.8,
      type: FestivalType.food,
    ),
    Festival(
      name: 'Navratri / Durga Puja',
      emoji: '🕌',
      date2025: DateTime(2025, 10, 2),
      date2026: DateTime(2026, 9, 21),
      spendCategories: ['Shopping', 'Entertainment', 'Food & Dining'],
      spendTheme: 'Festive clothes, pandal visits, food stalls',
      avgSpendMultiplier: 2.0,
      type: FestivalType.mixed,
    ),
    Festival(
      name: 'Christmas & New Year',
      emoji: '🎄',
      date2025: DateTime(2025, 12, 25),
      date2026: DateTime(2026, 12, 25),
      spendCategories: ['Travel & Hotels', 'Food & Dining', 'Shopping'],
      spendTheme: 'Travel, parties, gifts, dining out',
      avgSpendMultiplier: 2.5,
      type: FestivalType.travel,
    ),
    Festival(
      name: 'Eid al-Fitr',
      emoji: '🌙',
      date2025: DateTime(2025, 3, 30),
      date2026: DateTime(2026, 3, 19),
      spendCategories: ['Shopping', 'Food & Dining', 'Charity & Gifts'],
      spendTheme: 'New clothes, biryani, gifts, charity (Zakat)',
      avgSpendMultiplier: 2.2,
      type: FestivalType.gifting,
    ),
    Festival(
      name: 'Ganesh Chaturthi',
      emoji: '🐘',
      date2025: DateTime(2025, 8, 27),
      date2026: DateTime(2026, 8, 15),
      spendCategories: ['Food & Dining', 'Shopping'],
      spendTheme: 'Modak, decorations, idol purchase',
      avgSpendMultiplier: 1.5,
      type: FestivalType.food,
    ),
    Festival(
      name: 'Raksha Bandhan',
      emoji: '🧵',
      date2025: DateTime(2025, 8, 9),
      date2026: DateTime(2026, 7, 30),
      spendCategories: ['Shopping', 'Food & Dining'],
      spendTheme: 'Rakhis, gifts for sisters, sweets',
      avgSpendMultiplier: 1.3,
      type: FestivalType.gifting,
    ),
    Festival(
      name: "Valentine's Day",
      emoji: '❤️',
      date2025: DateTime(2025, 2, 14),
      date2026: DateTime(2026, 2, 14),
      spendCategories: ['Food & Dining', 'Entertainment', 'Shopping'],
      spendTheme: 'Dinner dates, gifts, flowers, getaways',
      avgSpendMultiplier: 1.6,
      type: FestivalType.mixed,
    ),
    Festival(
      name: 'Onam',
      emoji: '🌸',
      date2025: DateTime(2025, 9, 4),
      date2026: DateTime(2026, 8, 25),
      spendCategories: ['Food & Dining', 'Shopping', 'Travel & Hotels'],
      spendTheme: 'Onasadya feast, new clothes (Kasavu saree), travel to Kerala',
      avgSpendMultiplier: 1.8,
      type: FestivalType.food,
    ),
  ];

  /// Returns the next upcoming festival within 60 days, or null if none.
  static Festival? upcomingFestival({int withinDays = 60}) {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: withinDays));

    Festival? soonest;
    for (final f in _all) {
      final d = f.nextDate;
      if (d.isAfter(now) && d.isBefore(cutoff)) {
        if (soonest == null || d.isBefore(soonest.nextDate)) {
          soonest = f;
        }
      }
    }
    return soonest;
  }

  /// Returns all festivals whose next date falls within [from, to].
  static List<Festival> allFestivalsInRange(DateTime from, DateTime to) {
    return _all.where((f) {
      final d = f.nextDate;
      return !d.isBefore(from) && !d.isAfter(to);
    }).toList()
      ..sort((a, b) => a.nextDate.compareTo(b.nextDate));
  }

  /// All festivals sorted by next occurrence.
  static List<Festival> get allSorted =>
      List.of(_all)..sort((a, b) => a.nextDate.compareTo(b.nextDate));

  /// Smart tips for a festival type.
  static List<String> tipsForType(FestivalType type) {
    switch (type) {
      case FestivalType.shopping:
        return [
          'Add items to cart 2 weeks early — prices drop closer to the festival.',
          'Compare across Amazon, Flipkart and Myntra before buying.',
          'Look for bank card offers — extra 10–15% cashback is common.',
          'Set a per-category cap: electronics, clothes, gifts separately.',
        ];
      case FestivalType.travel:
        return [
          'Book flights 6 weeks out to save 30–40% vs last-minute fares.',
          'Lock in hotel stays now — popular destinations sell out fast.',
          'Pack lightly to avoid checked-baggage fees on budget airlines.',
          'Use a travel credit card for 2–5x reward points on bookings.',
        ];
      case FestivalType.gifting:
        return [
          'Make a gift list early to avoid panic buying at inflated prices.',
          'Group gifting with friends lowers per-person cost by 30–50%.',
          'E-gift cards work well when you are unsure of preferences.',
          'Handmade gifts often mean more and cost less.',
        ];
      case FestivalType.food:
        return [
          'Cook at home for 50% of meals to stay well within budget.',
          'Order from apps during off-peak hours for better deals.',
          'Batch-cook sweets at home — 3× cheaper than store-bought.',
          'Pre-order restaurant meals to avoid surge pricing on the day.',
        ];
      case FestivalType.mixed:
        return [
          'Set a total festival budget before the first purchase.',
          'Split your budget: 40% shopping, 30% food, 30% experiences.',
          'Book travel and stays first — those prices move fastest.',
          'Save shopping for the last 2 weeks when discounts peak.',
        ];
    }
  }
}
