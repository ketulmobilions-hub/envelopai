import 'package:envelope/domain/models/models.dart';

abstract interface class ICategoryGroupsRepository {
  Stream<List<CategoryGroup>> watchAll();
  Future<List<CategoryGroup>> getAll();
  Future<CategoryGroup?> getById(String id);
  Future<void> save(CategoryGroup group);
  Future<void> deleteById(String id);
}
