import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../../domain/models/transaction.dart';
import '../../domain/models/budget.dart';
import '../../domain/models/category.dart';
import '../../domain/models/user_profile.dart';

class HiveService {
  static const String _transactionsBox = 'transactions';
  static const String _budgetsBox = 'budgets';
  static const String _settingsBox = 'settings';
  static const String _userBox = 'user';

  static Future<void> initialize() async {
    await Hive.initFlutter();

    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(BudgetAdapter());
    Hive.registerAdapter(AppCategoryAdapter());
    Hive.registerAdapter(UserProfileAdapter());

    const secureStorage = FlutterSecureStorage();
    String? encryptionKeyString = await secureStorage.read(key: 'hive_key');

    if (encryptionKeyString == null) {
      final key = Hive.generateSecureKey();
      await secureStorage.write(
        key: 'hive_key',
        value: base64UrlEncode(key),
      );
      encryptionKeyString = base64UrlEncode(key);
    }

    final encryptionKey = base64Url.decode(encryptionKeyString);
    final encryptionCipher = HiveAesCipher(encryptionKey);

    await Hive.openBox<Transaction>(
      _transactionsBox,
      encryptionCipher: encryptionCipher,
    );
    await Hive.openBox<Budget>(
      _budgetsBox,
      encryptionCipher: encryptionCipher,
    );
    await Hive.openBox<UserProfile>(
      _userBox,
      encryptionCipher: encryptionCipher,
    );
    // Settings box is encrypted too — it now holds auth accounts (PBKDF2 hashes,
    // TOTP secrets, recovery hashes) and consent records. On upgrade from an
    // older unencrypted box, recreate it (pre-release: acceptable reset).
    try {
      await Hive.openBox(_settingsBox, encryptionCipher: encryptionCipher);
    } catch (_) {
      await Hive.deleteBoxFromDisk(_settingsBox);
      await Hive.openBox(_settingsBox, encryptionCipher: encryptionCipher);
    }
  }

  static Box<Transaction> get transactions => Hive.box<Transaction>(_transactionsBox);
  static Box<Budget> get budgets => Hive.box<Budget>(_budgetsBox);
  static Box<UserProfile> get user => Hive.box<UserProfile>(_userBox);
  static Box get settings => Hive.box(_settingsBox);
}
