import '../../domain/models/transaction.dart';
import 'hive_service.dart';

class TransactionLocalDatasource {
  Future<void> save(Transaction t) async {
    await HiveService.transactions.put(t.id, t);
  }

  Future<void> saveAll(List<Transaction> transactions) async {
    for (final t in transactions) {
      await HiveService.transactions.put(t.id, t);
    }
  }

  List<Transaction> getAll({bool includeIgnored = false}) {
    final all = HiveService.transactions.values.toList();
    return includeIgnored ? all : all.where((t) => !t.isIgnored).toList();
  }

  List<Transaction> getByMonth(int year, int month) {
    return getAll().where((t) {
      return t.transactionDate.year == year && t.transactionDate.month == month;
    }).toList();
  }

  List<Transaction> getByCategory(String category) {
    return getAll().where((t) => t.category == category).toList();
  }

  Transaction? getById(String id) {
    return HiveService.transactions.get(id);
  }

  Future<void> update(Transaction t) async {
    await HiveService.transactions.put(t.id, t);
  }

  Future<void> delete(String id) async {
    await HiveService.transactions.delete(id);
  }

  bool isDuplicate(String smsHash) {
    return HiveService.transactions.values
        .any((t) => t.rawSmsHash == smsHash);
  }

  List<Transaction> getUnsynced() {
    return getAll().where((t) => !t.isSynced).toList();
  }

  Future<void> markSynced(List<String> ids) async {
    for (final id in ids) {
      final t = HiveService.transactions.get(id);
      if (t != null) {
        t.isSynced = true;
        await t.save();
      }
    }
  }
}
