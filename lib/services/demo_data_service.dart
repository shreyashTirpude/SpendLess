import '../core/utils/sms_parser.dart';
import '../data/local/hive_service.dart';
import 'package:flutter/foundation.dart';

/// Seeds the Hive transaction box with realistic Indian bank SMS data.
/// Used on macOS / iOS where real SMS access is unavailable.
class DemoDataService {
  static const _seeded = 'demo_seeded_v2';

  static Future<int> seed() async {
    final already = HiveService.settings.get(_seeded, defaultValue: false) as bool;
    if (already) return 0;

    final now = DateTime.now();

    // 60 realistic Indian bank SMS messages spanning the last 3 months
    final List<(String sms, DateTime date)> corpus = [
      // ── June 2026 ─────────────────────────────────────────────────────────
      ('INR 2,450.00 debited from A/c XX4821 on 19-Jun-26 at 14:32. Info: ZOMATO*FOOD. UPI Ref: 512345678901. Avl Bal: INR 18,320.50. -HDFCBK', now.subtract(const Duration(days: 2))),
      ('Your A/C XXXXX0987 Credited INR 75,000.00 on 01/06/2026. Salary credit from TECHCORP. Avl Bal: INR 81,250.00. -SBIBNK', now.subtract(const Duration(days: 20))),
      ('ICICI Bank: INR 4,299.00 spent on Card XX5678 at AMAZON SELLER on 18-Jun-26. Avl Lmt: INR 82,300.00. -ICICIB', now.subtract(const Duration(days: 3))),
      ('Rs.750.00 debited from Axis Bank A/c XX9012 on 18-Jun-26. Info: SWIGGY*DELIVERY. UPI Ref: 512398000111. Avl Bal: Rs.9,250.00. -AXISBK', now.subtract(const Duration(days: 3))),
      ('INR 649.00 debited from A/c XX4821 on 17-Jun-26 via UPI to netflix1234@icici. Avl Bal INR 17,671.50. -HDFCBK', now.subtract(const Duration(days: 4))),
      ('INR 899.00 debited from Kotak a/c XX3344 on 17-Jun-26 via UPI to zepto@icici. Avl Bal INR 12,551.00. -KOTAKB', now.subtract(const Duration(days: 4))),
      ('INR 22,450.00 debited from A/c XX4821 for ECS/NACH HDFC HOME LOAN EMI on 05-Jun-26. Avl Bal: INR 18,320.50. -HDFCBK', now.subtract(const Duration(days: 16))),
      ('Rs.500.00 sent to priya.mehta@ybl via PhonePe on 15-Jun-26. UPI Ref: 512399001122. Avl Bal: Rs.8,750.00. -AXISBK', now.subtract(const Duration(days: 6))),
      ('INR 10,000.00 withdrawn at ATM from A/c XX4821 on 14-Jun-26. Avl Bal: INR 28,320.50. -HDFCBK', now.subtract(const Duration(days: 7))),
      ('INR 2,200.00 debited from A/c XX4821 on 13-Jun-26 via UPI to bigbasket@icici. Avl Bal: INR 26,120.50. -HDFCBK', now.subtract(const Duration(days: 8))),
      ('INR 1,250.00 debited from A/c XX4821 on 12-Jun-26 via UPI to bescom@sbi. Avl Bal: INR 24,870.50. -HDFCBK', now.subtract(const Duration(days: 9))),
      ('Rs.2,400.00 debited from Axis Bank A/c XX9012 on 11-Jun-26 via UPI to oyo@icici. Avl Bal: Rs.6,350.00. -AXISBK', now.subtract(const Duration(days: 10))),
      ('INR 280.00 debited from A/c XX4821. Info: UBER*TRIP*BLR12345. Avl Bal: INR 24,590.50. -HDFCBK', now.subtract(const Duration(days: 10))),
      ('INR 5,000.00 debited from A/c XX4821 for ECS/NACH SIP AXIS MUTUAL FUND. Avl Bal: INR 19,590.50. -HDFCBK', now.subtract(const Duration(days: 11))),
      ('Refund of INR 799.00 from FLIPKART credited to your HDFC A/c XX4821 on 10-Jun-26. Avl Bal: INR 20,389.50. -HDFCBK', now.subtract(const Duration(days: 11))),
      ('INR 8,500.00 debited from A/c XX4821 for ECS/NACH LIC PREMIUM. Avl Bal: INR 19,590.50. -HDFCBK', now.subtract(const Duration(days: 12))),
      ('ICICI Bank: INR 1,800.00 spent at MYNTRA on Card XX5678. Avl Lmt: INR 80,500.00. -ICICIB', now.subtract(const Duration(days: 12))),
      ('Rs.150.00 debited from Axis Bank A/c XX9012 for SPOTIFY via UPI spotify@hdfc. Avl Bal: Rs.6,200.00. -AXISBK', now.subtract(const Duration(days: 13))),
      ('INR 299.00 debited from A/c XX4821 via UPI to jio@icici for mobile recharge. Avl Bal: INR 19,291.50. -HDFCBK', now.subtract(const Duration(days: 13))),
      ('INR 850.00 debited from A/c XX4821 via UPI to apollopharmacy@icici. Avl Bal: INR 18,441.50. -HDFCBK', now.subtract(const Duration(days: 14))),
      ('Rs.3,500.00 debited from Axis Bank A/c XX9012 via UPI to 9876543210@oksbi. Avl Bal: Rs.2,700.00. -AXISBK', now.subtract(const Duration(days: 15))),
      ('INR 2,000.00 debited from A/c XX4821. Info: HP PETROL PUMP*BANGALORE. Avl Bal: INR 16,441.50. -HDFCBK', now.subtract(const Duration(days: 15))),
      ('INR 10,000.00 debited from A/c XX4821 via UPI to groww@icici for SIP. Avl Bal: INR 6,441.50. -HDFCBK', now.subtract(const Duration(days: 16))),
      ('Your a/c no. XXXX0987 is debited for Rs.1,450.00 on 04/06/2026 via UPI to irctc@sbi. UPI Ref no 512345678902. -SBMSMS', now.subtract(const Duration(days: 17))),
      ('INR 550.00 debited from A/c XX4821. Info: BLINKIT*GROCERY. UPI Ref: 512. Avl Bal: INR 5,891.50. -HDFCBK', now.subtract(const Duration(days: 17))),
      ('INR 1,299.00 spent at AJIO on ICICI Card XX5678 on 02-Jun-26. Avl Lmt: INR 78,701.00. -ICICIB', now.subtract(const Duration(days: 19))),
      ('Rs.350.00 debited from Axis Bank A/c XX9012 via UPI to dominos@icici. Avl Bal: Rs.2,350.00. -AXISBK', now.subtract(const Duration(days: 18))),
      ('INR 2,400.00 debited from A/c XX4821 via UPI to epfo@sbi PF CONTRIBUTION. Avl Bal: INR 3,491.50. -HDFCBK', now.subtract(const Duration(days: 19))),
      ('INR 999.00 debited from Kotak a/c XX3344 on 01-Jun-26 to hotstar@paytm. Avl Bal INR 11,552.00. -KOTAKB', now.subtract(const Duration(days: 20))),
      ('INR 5,000.00 debited from A/c XX4821 via UPI. Sent to rahul.sharma@ybl. UPI Ref: 512. Avl Bal: INR 13,491.50. -HDFCBK', now.subtract(const Duration(days: 20))),

      // ── May 2026 ──────────────────────────────────────────────────────────
      ('Your A/C XXXXX0987 Credited INR 75,000.00 on 01/05/2026. Salary credit from TECHCORP. Avl Bal: INR 78,200.00. -SBIBNK', now.subtract(const Duration(days: 51))),
      ('INR 22,450.00 debited from A/c XX4821 for ECS/NACH HDFC HOME LOAN EMI on 05-May-26. Avl Bal: INR 43,200.00. -HDFCBK', now.subtract(const Duration(days: 47))),
      ('INR 3,200.00 debited from A/c XX4821. Info: ZOMATO*FOOD. UPI Ref: 512. Avl Bal: INR 40,000.00. -HDFCBK', now.subtract(const Duration(days: 45))),
      ('ICICI Bank: INR 5,500.00 spent at FLIPKART on Card XX5678. Avl Lmt: INR 76,000.00. -ICICIB', now.subtract(const Duration(days: 44))),
      ('INR 1,500.00 debited from A/c XX4821 via UPI to swiggy@icici. Avl Bal: INR 38,500.00. -HDFCBK', now.subtract(const Duration(days: 43))),
      ('INR 649.00 debited from A/c XX4821 on 14-May-26 via UPI to netflix1234@icici. Avl Bal INR 37,851.00. -HDFCBK', now.subtract(const Duration(days: 38))),
      ('Rs.250.00 debited from Axis Bank A/c XX9012 via UPI to bookmyshow@icici. Avl Bal: Rs.4,250.00. -AXISBK', now.subtract(const Duration(days: 38))),
      ('INR 2,000.00 debited from A/c XX4821. Info: IOCL PETROL*PUNE. Avl Bal: INR 35,851.00. -HDFCBK', now.subtract(const Duration(days: 37))),
      ('INR 1,800.00 debited from A/c XX4821 via UPI to ola@ola for cab booking. Avl Bal: INR 34,051.00. -HDFCBK', now.subtract(const Duration(days: 36))),
      ('INR 5,000.00 debited for ECS/NACH SIP HDFC MUTUAL FUND from A/c XX4821. Avl Bal: INR 29,051.00. -HDFCBK', now.subtract(const Duration(days: 35))),
      ('INR 3,500.00 debited from A/c XX4821 via UPI to 9123456780@oksbi. Avl Bal: INR 25,551.00. -HDFCBK', now.subtract(const Duration(days: 34))),
      ('ICICI Bank: INR 12,999.00 spent at CROMA on Card XX5678 on 17-May-26. Avl Lmt: INR 63,001.00. -ICICIB', now.subtract(const Duration(days: 34))),
      ('Your a/c no. XXXX0987 is debited for Rs.2,200.00 on 18/05/2026 via UPI to bigbasket@icici. -SBMSMS', now.subtract(const Duration(days: 33))),
      ('INR 1,100.00 debited from A/c XX4821 via UPI to airtel@airtel for postpaid. Avl Bal: INR 22,251.00. -HDFCBK', now.subtract(const Duration(days: 32))),
      ('INR 8,500.00 debited from A/c XX4821 for ECS/NACH LIC PREMIUM. Avl Bal: INR 13,751.00. -HDFCBK', now.subtract(const Duration(days: 31))),
      ('Rs.600.00 debited from Axis Bank A/c XX9012 via UPI to kfc@icici. Avl Bal: Rs.3,650.00. -AXISBK', now.subtract(const Duration(days: 30))),
      ('INR 15,000.00 transferred from A/c XX4821 to A/c XXXXXX1234 via NEFT. UTR: HDFC225987654321. Avl Bal: INR 8,751.00. -HDFCBK', now.subtract(const Duration(days: 29))),
      ('Refund of INR 1,299.00 from MYNTRA credited to your A/c XX4821 on 23-May-26. Avl Bal: INR 10,050.00. -HDFCBK', now.subtract(const Duration(days: 28))),
      ('INR 3,000.00 debited from A/c XX4821 via UPI to zerodha@icici. Avl Bal: INR 7,050.00. -HDFCBK', now.subtract(const Duration(days: 27))),
      ('INR 850.00 debited from Kotak a/c XX3344 on 26-May-26 via UPI to practo@kotak. Avl Bal INR 10,702.00. -KOTAKB', now.subtract(const Duration(days: 25))),

      // ── April 2026 ─────────────────────────────────────────────────────────
      ('Your A/C XXXXX0987 Credited INR 75,000.00 on 01/04/2026. Salary credit from TECHCORP. Avl Bal: INR 79,000.00. -SBIBNK', now.subtract(const Duration(days: 81))),
      ('INR 22,450.00 debited from A/c XX4821 for ECS/NACH HDFC HOME LOAN EMI on 05-Apr-26. Avl Bal: INR 44,500.00. -HDFCBK', now.subtract(const Duration(days: 77))),
      ('INR 4,500.00 debited from A/c XX4821. Info: ZOMATO*FOOD. UPI Ref: 512. Avl Bal: INR 40,000.00. -HDFCBK', now.subtract(const Duration(days: 75))),
      ('INR 25,000.00 debited from A/c XX4821 via NEFT to RENT LANDLORD SHARMA. UTR: HDFC220987654. Avl Bal: INR 15,000.00. -HDFCBK', now.subtract(const Duration(days: 72))),
      ('ICICI Bank: INR 3,800.00 spent at NYKAA on Card XX5678 on 10-Apr-26. Avl Lmt: INR 74,200.00. -ICICIB', now.subtract(const Duration(days: 72))),
      ('INR 5,000.00 debited for ECS/NACH SIP AXIS MUTUAL FUND. Avl Bal: INR 10,000.00. -HDFCBK', now.subtract(const Duration(days: 70))),
      ('Rs.1,800.00 debited from Axis Bank A/c XX9012 via UPI to unacademy@ybl. Avl Bal: Rs.3,200.00. -AXISBK', now.subtract(const Duration(days: 68))),
      ('INR 299.00 debited from A/c XX4821 via UPI to jio@icici for mobile recharge. Avl Bal: INR 9,701.00. -HDFCBK', now.subtract(const Duration(days: 66))),
      ('INR 12,000.00 debited from A/c XX4821 via UPI to 9900112233@okicici. Avl Bal: INR 7,701.00. -HDFCBK', now.subtract(const Duration(days: 65))),
      ('INR 649.00 debited from A/c XX4821 on 20-Apr-26 via UPI to netflix1234@icici. Avl Bal INR 7,052.00. -HDFCBK', now.subtract(const Duration(days: 62))),
    ];

    final box = HiveService.transactions;
    int added = 0;

    for (final (sms, date) in corpus) {
      final parsed = SmsParser.parse(sms, date);
      if (parsed == null) continue;

      final alreadyExists = box.values.any((t) => t.rawSmsHash == parsed.rawSmsHash);
      if (alreadyExists) continue;

      final tx = SmsParser.toTransaction(parsed);
      await box.put(tx.id, tx);
      added++;
    }

    await HiveService.settings.put(_seeded, true);
    debugPrint('[DemoDataService] Seeded $added transactions');
    return added;
  }
}
