import '../models/transaction.dart';

abstract class TransactionRepository {
  Future<void> save(Transaction t);
  Future<void> saveAll(List<Transaction> transactions);
  List<Transaction> getAll({bool includeIgnored});
  List<Transaction> getThisMonth();
  List<Transaction> getByMonth(int year, int month);
  List<Transaction> getByCategory(String category);
  Transaction? getById(String id);
  Future<void> update(Transaction t);
  Future<void> delete(String id);
  bool isDuplicate(String smsHash);
  Future<void> syncAll(String userId);
}
