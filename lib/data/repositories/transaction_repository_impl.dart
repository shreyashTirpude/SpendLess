import '../../domain/models/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../local/transaction_local_datasource.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDatasource _local = TransactionLocalDatasource();

  @override
  Future<void> save(Transaction t) async {
    if (t.rawSmsHash != null && _local.isDuplicate(t.rawSmsHash!)) return;
    await _local.save(t);
  }

  @override
  Future<void> saveAll(List<Transaction> transactions) async {
    for (final t in transactions) {
      if (t.rawSmsHash != null && _local.isDuplicate(t.rawSmsHash!)) continue;
      await _local.save(t);
    }
  }

  @override
  List<Transaction> getAll({bool includeIgnored = false}) {
    return _local.getAll(includeIgnored: includeIgnored);
  }

  @override
  List<Transaction> getThisMonth() {
    final now = DateTime.now();
    final txns = _local.getByMonth(now.year, now.month)
        .where((t) => !t.isIgnored)
        .toList();
    txns.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return txns;
  }

  @override
  List<Transaction> getByMonth(int year, int month) {
    return _local.getByMonth(year, month);
  }

  @override
  List<Transaction> getByCategory(String category) {
    return _local.getByCategory(category);
  }

  @override
  Transaction? getById(String id) {
    return _local.getById(id);
  }

  @override
  Future<void> update(Transaction t) async {
    await _local.update(t);
  }

  @override
  Future<void> delete(String id) async {
    await _local.delete(id);
  }

  @override
  bool isDuplicate(String smsHash) {
    return _local.isDuplicate(smsHash);
  }

  @override
  Future<void> syncAll(String userId) async {
    final unsynced = _local.getUnsynced();
    if (unsynced.isNotEmpty) {
      await _local.markSynced(unsynced.map((t) => t.id).toList());
    }
  }
}
