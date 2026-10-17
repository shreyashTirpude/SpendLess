// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:spendlens/core/utils/sms_parser.dart';
import 'package:spendlens/core/utils/merchant_normalizer.dart';
import 'package:spendlens/core/utils/category_engine.dart';

void main() {
  final now = DateTime(2026, 6, 19, 10, 0);

  // ── Helper ──────────────────────────────────────────────────────────────────
  ParsedSms? p(String sms) => SmsParser.parseSingle(sms, now);

  // ─────────────────────────────────────────────────────────────────────────────
  // SECTION 1: Amount extraction
  // ─────────────────────────────────────────────────────────────────────────────
  group('Amount extraction', () {
    test('HDFC UPI debit — ₹ prefix', () {
      final r = p('INR 2,450.00 debited from A/c XX4821 on 19-Jun-26. Info: ZOMATO*FOOD. Avl Bal: INR 18,320.50. -HDFCBK');
      expect(r?.amount, 2450.00);
    });

    test('SBI Rs. debit', () {
      final r = p("Your a/c no. XXXX0987 is debited for Rs.1,200.00 on 19-Jun-26 and a/c credited (UPI Ref no 512345678902).");
      expect(r?.amount, 1200.00);
    });

    test('Lakh format (5,00,000)', () {
      final r = p('INR 5,00,000.00 credited to A/c XX4821 on 19-Jun-26 via RTGS. Avl Bal: INR 10,00,000.00. -HDFCBK');
      expect(r?.amount, 500000.00);
    });

    test('No decimal', () {
      final r = p('Rs.500 debited from Axis Bank A/c XX9012 on 19-Jun-26 via UPI. Avl Bal: Rs.9,500.00. -AXISBK');
      expect(r?.amount, 500.0);
    });

    test('Balance should NOT be extracted as amount', () {
      final r = p('INR 50.00 debited from A/c XX4821. Avl Bal: INR 12,456.00. -HDFCBK');
      expect(r?.amount, 50.00);
    });

    test('ICICI — amount between semicolons', () {
      final r = p('ICICI Bank Acct XX5678 debited with INR 4,299.00 on 19-Jun-26; AMAZON SELLER SERVIC credited. Avl Bal INR 10,000.00.');
      expect(r?.amount, 4299.00);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // SECTION 2: Debit / Credit detection
  // ─────────────────────────────────────────────────────────────────────────────
  group('Credit/Debit detection', () {
    test('HDFC debit keyword', () {
      final r = p('INR 500.00 debited from A/c XX4821 on 19-Jun-26. -HDFCBK');
      expect(r?.isCredit, false);
    });

    test('SBI salary credit', () {
      final r = p('Your A/C XXXXX0987 Credited INR 62,500.00 on 01/06/26 -Salary credit from EMPLOYER. Avl Bal: INR 68,250.00. -SBIBNK');
      expect(r?.isCredit, true);
    });

    test('Refund credit', () {
      final r = p('Refund of INR 799.00 from FLIPKART credited to your HDFC A/c XX4821 on 19-Jun-26. Avl Bal: INR 19,119.50. -HDFCBK');
      expect(r?.isCredit, true);
    });

    test('Sent-to = debit', () {
      final r = p('Rs.2,000.00 sent to Rahul Sharma via UPI. UPI Ref: 512398000111. Avl Bal: Rs.8,000.00. -AXISBK');
      expect(r?.isCredit, false);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // SECTION 3: Channel detection
  // ─────────────────────────────────────────────────────────────────────────────
  group('Channel detection', () {
    test('UPI channel', () {
      final r = p('INR 350.00 debited from A/c XX4821 via UPI. Ref: 512399001122. -HDFCBK');
      expect(r?.channel, 'UPI');
    });

    test('NEFT channel', () {
      final r = p('INR 50,000.00 debited from A/c XX4821 via NEFT. UTR: HDFC225987654321. -HDFCBK');
      expect(r?.channel, 'NEFT');
    });

    test('ATM channel', () {
      final r = p('INR 10,000.00 withdrawn at ATM from A/c XX4821. Avl Bal: INR 5,000.00. -HDFCBK');
      expect(r?.channel, 'ATM');
    });

    test('NACH/ECS channel', () {
      final r = p('INR 9,876.00 debited from A/c XX4821 for ECS/NACH EMI. Avl Bal: INR 22,444.00. -HDFCBK');
      expect(r?.channel, 'NACH');
    });

    test('IMPS channel', () {
      final r = p('Rs.20,000.00 credited to Axis Bank A/c XX9012 on 19-Jun-26 via IMPS. -AXISBK');
      expect(r?.channel, 'IMPS');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // SECTION 4: Merchant extraction
  // ─────────────────────────────────────────────────────────────────────────────
  group('Merchant extraction', () {
    test('HDFC Info field: ZOMATO*FOOD', () {
      final r = p('INR 350.00 debited from A/c XX4821. Info: ZOMATO*FOOD. UPI Ref: 512. Avl Bal: INR 5,000.00. -HDFCBK');
      expect(r?.merchant, 'Zomato');
    });

    test('Swiggy via VPA', () {
      final r = p('Rs.650.00 debited from Axis Bank A/c XX9012 to swiggy@icici on 19-Jun-26. UPI Ref: 512. -AXISBK');
      expect(r?.merchant, 'Swiggy');
    });

    test('"at AMAZON SELLER SERVIC" (truncated)', () {
      final r = p('INR 4,299.00 spent on Card XX5678 at AMAZON SELLER SERVIC on 19-Jun-26. -ICICIB');
      expect(r?.merchant, 'Amazon');
    });

    test('UPI VPA mobile number → title-case name from "to" field', () {
      final r = p('Rs.500.00 sent to Priya via UPI to 9876543210@oksbi. UPI Ref: 512. Avl Bal: Rs.8,000.00. -AXISBK');
      expect(r?.isP2P, true);
    });

    test('HDFC salary credit info', () {
      final r = p('INR 75,000.00 credited to Kotak a/c XX3344 on 01-Jun-26. Info: SAL/TECHCORP/JUN26. Avl Bal INR 82,100.00. -KOTAKB');
      expect(r?.isCredit, true);
    });

    test('Zomato via zoicici VPA (merchant-only handle)', () {
      final r = p('INR 350.00 debited. UPI to zomato123@zoicici. Avl Bal: INR 5,000.00. -HDFCBK');
      expect(r?.merchant, 'Zomato');
      expect(r?.isP2P, false);
    });

    test('Personal VPA: rahul.sharma@ybl → P2P', () {
      final r = p('Rs.1,000.00 sent to rahul.sharma@ybl via PhonePe. UPI Ref: 512. Avl Bal: Rs.5,000.00. -YESBNK');
      expect(r?.isP2P, true);
    });

    test('NACH → loan EMI', () {
      final r = p('INR 12,450.00 debited from A/c XX4821 for ECS/NACH HDFC HOME LOAN EMI. Avl Bal: INR 8,000.00. -HDFCBK');
      expect(r?.channel, 'NACH');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // SECTION 5: Category classification
  // ─────────────────────────────────────────────────────────────────────────────
  group('Category classification', () {
    String cat(String sms) {
      final parsed = p(sms);
      if (parsed == null) return 'NULL';
      return CategoryEngine.categorizeFromSms(
        parsed.rawSmsBody,
        parsed.merchant,
        isCredit: parsed.isCredit,
        vpa: parsed.vpa,
        channel: parsed.channel,
        isP2P: parsed.isP2P,
      );
    }

    test('Zomato → Food & Dining', () {
      expect(cat('INR 350.00 debited. Info: ZOMATO*FOOD. Avl Bal: INR 5,000.00. -HDFCBK'),
          'Food & Dining');
    });

    test('Swiggy → Food & Dining', () {
      expect(cat('Rs.650.00 debited to swiggy@icici. UPI Ref: 512. Avl Bal: Rs.4,350.00. -AXISBK'),
          'Food & Dining');
    });

    test('Bigbasket → Groceries', () {
      expect(cat('INR 2,200.00 debited to bigbasket@icici. UPI Ref: 512. Avl Bal: INR 18,000.00. -HDFCBK'),
          'Groceries');
    });

    test('Zepto → Groceries', () {
      expect(cat('Rs.450.00 debited to zepto@icici. UPI Ref: 512. Avl Bal: Rs.9,550.00. -AXISBK'),
          'Groceries');
    });

    test('Uber → Transport', () {
      expect(cat('INR 280.00 debited. Info: UBER*TRIP*BLR. Avl Bal: INR 4,720.00. -HDFCBK'),
          'Transport');
    });

    test('IRCTC → Transport', () {
      expect(cat('INR 1,450.00 debited to irctc@sbi. UPI Ref: 512. Avl Bal: INR 8,550.00. -SBIBNK'),
          'Transport');
    });

    test('Netflix → Subscriptions', () {
      expect(cat('INR 649.00 debited to netflix1234@icici. UPI Ref: 512. Avl Bal: INR 9,351.00. -ICICIB'),
          'Subscriptions');
    });

    test('Amazon → Shopping', () {
      expect(cat('INR 4,299.00 spent on Card XX5678 at AMAZON SELLER SERVIC. Avl Bal: INR 82,301.00. -ICICIB'),
          'Shopping');
    });

    test('Salary credit', () {
      expect(cat('Your A/C XXXXX0987 Credited INR 62,500.00 on 01/06/26 -Salary credit from EMPLOYER. Avl Bal: 68,250.00. -SBIBNK'),
          'Salary');
    });

    test('Refund credit', () {
      expect(cat('Refund of INR 799.00 from FLIPKART credited to your A/c XX4821. Avl Bal: INR 19,119.50. -HDFCBK'),
          'Refund');
    });

    test('NACH EMI → Loan EMI', () {
      expect(cat('INR 12,450.00 debited for ECS/NACH HDFC HOME LOAN EMI from A/c XX4821. Avl Bal: INR 8,000.00. -HDFCBK'),
          'Loan EMI');
    });

    test('Personal VPA → Send Money', () {
      expect(cat('Rs.1,000.00 sent to rahul.sharma@ybl via UPI. UPI Ref: 512. Avl Bal: Rs.5,000.00. -YESBNK'),
          'Send Money');
    });

    test('Mobile VPA → Send Money', () {
      expect(cat('Rs.500.00 sent to 9876543210@oksbi via UPI. Avl Bal: Rs.9,500.00. -SBIBNK'),
          'Send Money');
    });

    test('BESCOM electricity → Bills & Utilities', () {
      expect(cat('INR 1,250.00 debited to bescom@sbi for electricity bill. UPI Ref: 512. Avl Bal: INR 8,750.00. -SBIBNK'),
          'Bills & Utilities');
    });

    test('Jio recharge → Bills & Utilities', () {
      expect(cat('INR 299.00 debited to jio@icici for mobile recharge. UPI Ref: 512. Avl Bal: INR 5,701.00. -ICICIB'),
          'Bills & Utilities');
    });

    test('Apollo Pharmacy → Health', () {
      expect(cat('INR 850.00 debited to apollopharmacy@icici. UPI Ref: 512. Avl Bal: INR 9,150.00. -ICICIB'),
          'Health');
    });

    test('BYJU\'S → Education', () {
      expect(cat('INR 5,000.00 debited to byjus@ybl. UPI Ref: 512. Avl Bal: INR 15,000.00. -YESBNK'),
          'Education');
    });

    test('Groww → Investment', () {
      expect(cat('INR 10,000.00 debited to groww@icici for SIP. UPI Ref: 512. Avl Bal: INR 5,000.00. -ICICIB'),
          'Investment');
    });

    test('LIC → Insurance', () {
      expect(cat('INR 8,500.00 debited to lic@sbi LIC PREMIUM. UPI Ref: 512. Avl Bal: INR 11,500.00. -SBIBNK'),
          'Insurance');
    });

    test('OYO → Travel & Hotels', () {
      expect(cat('INR 2,400.00 debited to oyo@icici. UPI Ref: 512. Avl Bal: INR 7,600.00. -ICICIB'),
          'Travel & Hotels');
    });

    test('ATM withdrawal → ATM & Cash', () {
      expect(cat('INR 10,000.00 withdrawn at ATM from A/c XX4821 on 19-Jun-26. Avl Bal: INR 5,000.00. -HDFCBK'),
          'ATM & Cash');
    });

    test('EPFO → Government', () {
      expect(cat('INR 2,400.00 debited to epfo@sbi PF CONTRIBUTION. UPI Ref: 512. Avl Bal: INR 7,600.00. -SBIBNK'),
          'Government');
    });

    test('HPCL petrol → Fuel', () {
      expect(cat('INR 2,000.00 debited. Info: HP PETROL PUMP*PUNE. Avl Bal: INR 8,000.00. -HDFCBK'),
          'Fuel');
    });

    test('NACH insurance → Insurance', () {
      expect(cat('INR 3,500.00 debited for ECS/NACH LIC PREMIUM from A/c XX4821. Avl Bal: INR 6,500.00. -HDFCBK'),
          'Insurance');
    });

    test('NACH SIP → Investment', () {
      expect(cat('INR 5,000.00 debited for ECS/NACH SIP AXIS MUTUAL FUND from A/c XX4821. Avl Bal: INR 5,000.00. -HDFCBK'),
          'Investment');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // SECTION 6: Filter logic (should return null)
  // ─────────────────────────────────────────────────────────────────────────────
  group('Filter logic', () {
    test('OTP message → null', () {
      expect(p('Your OTP is 123456. Do not share. Valid for 5 min.'), isNull);
    });

    test('Promo message → null', () {
      expect(p('Congratulations! You won Rs.10,000 in our lucky draw. Subscribe now!'), isNull);
    });

    test('Failed transaction → null', () {
      expect(p('ALERT: Your UPI txn of INR 2,000.00 has FAILED. Ref: 512300000001. Amount will be reversed within 24 hrs.'), isNull);
    });

    test('Non-bank SMS → null', () {
      expect(p('Your order #12345 has been shipped. Expected delivery: 21-Jun-26.'), isNull);
    });

    test('No amount → null', () {
      expect(p('Your account has been debited. UPI transaction completed.'), isNull);
    });

    // ── Loan-offer / promotional spam (regression for the 25-lakh bug) ──────
    test('Pre-approved loan offer → null', () {
      expect(
          p('Congratulations! You are eligible for a pre-approved personal loan of Rs 25,00,000. Apply now -HDFCBK'),
          isNull);
    });

    test('"You got a loan of 25 lakh" promo → null', () {
      expect(p('Dear customer, you got a loan offer of Rs 25 lakh at lowest interest rate. Click here to apply -SBIBNK'),
          isNull);
    });

    test('Credit card limit increase offer → null', () {
      expect(
          p('Your ICICI card is eligible for a credit limit increase to INR 3,00,000. Apply today! -ICICIB'),
          isNull);
    });

    test('Cashback marketing → null', () {
      expect(p('Flat 50% cashback on your next UPI payment! Offer ends soon. -PAYTMB'),
          isNull);
    });

    test('REAL loan EMI debit still parses (not rejected)', () {
      final r = p('INR 4,200.00 debited from A/c XX4821 for ECS/NACH BAJAJ FINANCE PERSONAL LOAN EMI. Avl Bal: INR 8,000. -HDFCBK');
      expect(r, isNotNull);
      expect(r!.amount, 4200.00);
    });

    test('REAL loan disbursal credit still parses', () {
      final r = p('INR 5,00,000.00 credited to A/c XX4821 as loan disbursal. Avl Bal: INR 5,12,000. UPI Ref 5123. -HDFCBK');
      expect(r, isNotNull);
      expect(r!.amount, 500000.00);
    });

    test('Credited reversal (refund) is NOT dropped as failed', () {
      final r = p('Rs.500.00 reversed and credited back to your A/c XX4821 for cancelled Amazon order. Avl Bal: Rs.8,500. -HDFCBK');
      expect(r, isNotNull);
      expect(r!.amount, 500.00);
      expect(r.isCredit, true);
    });

    // ── Non-transaction "useless" messages → must be null (no false positives)
    test('Credit-card bill due reminder → null', () {
      expect(p('Your HDFC Credit Card bill of Rs.12,500.00 is due on 25-Jun-26. Pay now to avoid charges. -HDFCBK'),
          isNull);
    });

    test('EMI due reminder → null', () {
      expect(p('Reminder: Your EMI of Rs.4,200.00 is due on 05-Jul-26 for loan a/c XX99. -HDFCBK'),
          isNull);
    });

    test('UPI collect / payment request → null', () {
      expect(p('Rahul has requested Rs.500.00 via UPI. Approve the request in your app. -AXISBK'),
          isNull);
    });

    test('Future-tense SIP mandate notice → null', () {
      expect(p('Rs.5,000.00 will be debited from A/c XX4821 on 05-Jul-26 towards SIP via e-mandate. -HDFCBK'),
          isNull);
    });

    test('Balance enquiry → null', () {
      expect(p('Your available balance is Rs.18,320.50 in A/c XX4821 as on 22-Jun-26. -HDFCBK'),
          isNull);
    });

    test('Statement generated → null', () {
      expect(p('Your monthly e-statement is generated for A/c XX4821. Total amount due Rs.12,500. -HDFCBK'),
          isNull);
    });

    test('Delivery / order update → null', () {
      expect(p('Your order worth Rs.2,499 is out for delivery. Track your order now. -AMAZON'),
          isNull);
    });

    test('Recharge offer → null', () {
      expect(p('Your plan expires today! Recharge now with Rs.299 for unlimited data. -JIO'),
          isNull);
    });

    test('Minimum amount due reminder → null', () {
      expect(p('ICICI Card XX5678: Total amount due Rs.15,000, minimum amount due Rs.750, due date 25-Jun. -ICICIB'),
          isNull);
    });

    // ── Real txns that LOOK similar must STILL parse ───────────────────────
    test('Real EMI debit (past tense) still parses despite future EMI mention', () {
      final r = p('Rs.4,200.00 has been debited from A/c XX4821 for EMI. Next EMI will be debited on 05-Jul-26. Avl Bal Rs.8,000. -HDFCBK');
      expect(r, isNotNull);
      expect(r!.amount, 4200.00);
      expect(r.isCredit, false);
    });

    test('Real debit with "available balance is" phrasing still parses', () {
      final r = p('INR 750.00 debited from A/c XX4821 via UPI to swiggy@icici. Your available balance is INR 9,250.00. -HDFCBK');
      expect(r, isNotNull);
      expect(r!.amount, 750.00);
    });

    // ── Terse real transactions must NOT be dropped by the junk filter ──────
    test('NEFT "transferred to" still parses', () {
      final r = p('INR 15,000.00 transferred to A/c XXXXXX1234 via NEFT. UTR: HDFC2259. -HDFCBK');
      expect(r, isNotNull);
      expect(r!.amount, 15000.00);
    });

    test('Terse "Paid Rs to merchant" still parses', () {
      final r = p('Paid Rs.200.00 to Zomato via UPI Ref 5123. -HDFCBK');
      expect(r, isNotNull);
      expect(r!.amount, 200.00);
    });

    test('IMPS "received from" credit still parses', () {
      final r = p('INR 3,000.00 received from RAHUL via IMPS in A/c XX4821. -HDFCBK');
      expect(r, isNotNull);
      expect(r!.amount, 3000.00);
      expect(r.isCredit, true);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // SECTION 7: Date extraction
  // ─────────────────────────────────────────────────────────────────────────────
  group('Date extraction', () {
    test('DD-Mon-YY format', () {
      final r = p('INR 500.00 debited from A/c XX4821 on 15-Jun-26. Avl Bal: INR 9,500.00. -HDFCBK');
      expect(r?.transactionDate.month, 6);
      expect(r?.transactionDate.day, 15);
    });

    test('DD/MM/YYYY format', () {
      final r = p('Your a/c XXXX0987 is debited for Rs.1,200.00 on 10/06/2026 via UPI. -SBIBNK');
      expect(r?.transactionDate.day, 10);
      expect(r?.transactionDate.month, 6);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // SECTION 8: Account last-4 extraction
  // ─────────────────────────────────────────────────────────────────────────────
  group('Account extraction', () {
    test('A/c XX4821 → last4 = 4821', () {
      final r = p('INR 500.00 debited from A/c XX4821 on 19-Jun-26. Avl Bal: INR 9,500.00. -HDFCBK');
      expect(r?.accountLast4, '4821');
    });

    test('Card XX5678 → last4 = 5678', () {
      final r = p('INR 4,299.00 spent on Card XX5678 at MYNTRA on 19-Jun-26. -HDFCCC');
      expect(r?.accountLast4, '5678');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // SECTION 9: MerchantNormalizer standalone
  // ─────────────────────────────────────────────────────────────────────────────
  group('MerchantNormalizer', () {
    test('Legal entity: BUNDL TECHNOLOGIES → Swiggy', () {
      expect(MerchantNormalizer.normalize('BUNDL TECHNOLOGIES'), 'Swiggy');
    });

    test('Legal entity: ANI TECHNOLOGIES → Ola', () {
      expect(MerchantNormalizer.normalize('ANI TECHNOLOGIES'), 'Ola');
    });

    test('Legal entity: JUBILANT FOOD → Dominos', () {
      expect(MerchantNormalizer.normalize('JUBILANT FOOD'), "Domino's");
    });

    test('Asterisk noise: SWIGGY*ORDER#123456 → Swiggy', () {
      expect(MerchantNormalizer.normalize('SWIGGY*ORDER#123456'), 'Swiggy');
    });

    test('Asterisk noise: ZOMATO*HYDERABAD → Zomato', () {
      expect(MerchantNormalizer.normalize('ZOMATO*HYDERABAD'), 'Zomato');
    });

    test('Asterisk noise: UBER*TRIP*BLR12345 → Uber', () {
      expect(MerchantNormalizer.normalize('UBER*TRIP*BLR12345'), 'Uber');
    });

    test('Truncation: AMAZON SELLER SERVIC → Amazon', () {
      expect(MerchantNormalizer.normalize('AMAZON SELLER SERVIC'), 'Amazon');
    });

    test('VPA: zomato.food@hdfcbank → Zomato', () {
      expect(MerchantNormalizer.normalizeVpa('zomato.food@hdfcbank'), 'Zomato');
    });

    test('VPA: uber12345@okhdfcbank → Uber', () {
      expect(MerchantNormalizer.normalizeVpa('uber12345@okhdfcbank'), 'Uber');
    });

    test('VPA personal: rahul.sharma@ybl → Rahul Sharma', () {
      final result = MerchantNormalizer.normalizeVpa('rahul.sharma@ybl');
      expect(result.toLowerCase(), 'rahul sharma');
    });

    test('VPA mobile: 9876543210@oksbi → 9876543210', () {
      // Mobile VPA → title-case of the number (displayed as-is)
      final result = MerchantNormalizer.normalizeVpa('9876543210@oksbi');
      expect(result, isNotEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // SECTION 10: Real-world SMS corpus (integration)
  // ─────────────────────────────────────────────────────────────────────────────
  group('Real-world SMS corpus', () {
    final corpus = [
      // HDFC UPI food
      ('INR 2,450.00 debited from A/c XX4821 on 19-Jun-26 at 14:32 IST. Info: ZOMATO*FOOD. UPI Ref: 512345678901. Avl Bal: INR 18,320.50. -HDFCBK',
          2450.00, false, 'Food & Dining'),
      // SBI salary
      ('Your A/C XXXXX0987 Credited INR 62,500.00 on 01/06/26. Salary credit from TECHCORP. Avl Bal: INR 68,250.00. -SBIBNK',
          62500.00, true, 'Salary'),
      // ICICI Amazon purchase
      ('ICICI Bank: INR 4,299.00 spent on Card XX5678 at AMAZON SELLER on 19-Jun-26. Avl Lmt: INR 82,300.00. -ICICIB',
          4299.00, false, 'Shopping'),
      // Axis Swiggy UPI
      ('Rs.750.00 debited from Axis Bank A/c XX9012 on 19-Jun-26. Info: SWIGGY*DELIVERY. UPI Ref No: 512398000111. Avl Bal: Rs.9,250.00. -AXISBK',
          750.00, false, 'Food & Dining'),
      // Kotak Netflix sub
      ('INR 649.00 debited from Kotak a/c XX3344 on 19-Jun-26 via UPI to netflix1234@icici. Avl Bal INR 12,551.00. -KOTAKB',
          649.00, false, 'Subscriptions'),
      // IDFC Zepto grocery
      ('Your IDFC FIRST Bank A/c XX7788 has been debited for INR 899.00 on 19-Jun-26 via UPI. Ref: zepto12345@icici. Avl Bal: INR 9,101.00. -IDFCFB',
          899.00, false, 'Groceries'),
      // HDFC NACH home loan
      ('INR 22,450.00 debited from A/c XX4821 for ECS/NACH HDFC HOME LOAN EMI on 05-Jun-26. Avl Bal: INR 8,550.00. -HDFCBK',
          22450.00, false, 'Loan EMI'),
      // SBI NEFT large transfer
      ('Your a/c no. XXXX0987 is debited for Rs.1,00,000.00 on 10-Jun-26 via NEFT to a/c XXXXXX1234 (IMPS Ref 512398765). -SBMSMS',
          100000.00, false, 'Send Money'),
      // Kotak salary
      ('INR 75,000.00 credited to Kotak a/c XX3344 on 01-Jun-26. Info: SAL/EMPLOYERLTD/JUN26. Avl Bal INR 82,100.00. -KOTAKB',
          75000.00, true, 'Salary'),
      // PhonePe P2P
      ('Rs.500.00 sent to priya.mehta@ybl via PhonePe on 19-Jun-26. UPI Ref: 512399001122. Avl Bal: Rs.8,000.00. -AXISBK',
          500.00, false, 'Send Money'),
      // ATM withdrawal
      ('INR 10,000.00 withdrawn at ATM from A/c XX4821 on 18-Jun-26. Avl Bal: INR 18,320.50. -HDFCBK',
          10000.00, false, 'ATM & Cash'),
      // Groww SIP
      ('INR 5,000.00 debited from A/c XX4821 for ECS/NACH SIP AXIS MUTUAL FUND. Avl Bal: INR 13,320.50. -HDFCBK',
          5000.00, false, 'Investment'),
      // Flipkart refund
      ('Refund of INR 799.00 from FLIPKART credited to your HDFC A/c XX4821 on 19-Jun-26. Avl Bal: INR 18,319.50. -HDFCBK',
          799.00, true, 'Refund'),
      // Uber ride
      ('INR 280.00 debited from A/c XX4821. Info: UBER*TRIP*BLR12345. Avl Bal: INR 18,040.50. -HDFCBK',
          280.00, false, 'Transport'),
      // Bescom electricity
      ('INR 1,250.00 debited to bescom@sbi for electricity bill. UPI Ref: 512. Avl Bal: INR 8,750.00. -SBIBNK',
          1250.00, false, 'Bills & Utilities'),
    ];

    for (final (sms, amount, isCredit, category) in corpus) {
      test('$category: amount=$amount credit=$isCredit', () {
        final r = p(sms);
        expect(r, isNotNull, reason: 'Parser returned null for SMS');
        expect(r!.amount, amount);
        expect(r.isCredit, isCredit);
        final cat = CategoryEngine.categorizeFromSms(
          r.rawSmsBody,
          r.merchant,
          isCredit: r.isCredit,
          vpa: r.vpa,
          channel: r.channel,
          isP2P: r.isP2P,
        );
        expect(cat, category,
            reason: 'Expected $category but got $cat for: $sms');
      });
    }
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // SECTION: Idempotent transaction ids (duplicate-payments regression)
  // ─────────────────────────────────────────────────────────────────────────────
  group('toTransaction id determinism', () {
    const body =
        'INR 2,450.00 debited from A/c XX4821 on 19-Jun-26 at 10:30. Info: ZOMATO*FOOD. UPI Ref: 512345678901. Avl Bal: INR 18,320.50. -HDFCBK';

    test('same SMS content always maps to the same transaction id', () {
      // uuid v4 ids made every parse a brand-new Hive row, so overlapping
      // scans (startup + resume + 15-min timer) stored the same bank SMS
      // 3-4 times. Ids derive from the SMS hash so puts overwrite, not append.
      final first = SmsParser.toTransaction(p(body)!);
      final second = SmsParser.toTransaction(p(body)!);
      expect(first.id, second.id,
          reason: 'parsing the same SMS twice must reuse the same Hive key');
    });

    test('different SMS content maps to different transaction ids', () {
      final a = SmsParser.toTransaction(p(body)!);
      final b = SmsParser.toTransaction(p(body.replaceAll('2,450.00', '999.00'))!);
      expect(a.id, isNot(b.id));
    });

    test('id is a valid uuid (Supabase column compatibility)', () {
      final id = SmsParser.toTransaction(p(body)!).id;
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
            .hasMatch(id),
        isTrue,
        reason: 'derived id must stay in canonical uuid format, got: $id',
      );
    });
  });
}
