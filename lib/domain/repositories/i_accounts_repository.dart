import 'package:envelope/domain/models/models.dart';

abstract interface class IAccountsRepository {
  Stream<List<Account>> watchAll();
  Future<List<Account>> getAll();
  Future<Account?> getById(String id);
  Future<void> save(Account account);
  Future<void> deleteById(String id);
}
