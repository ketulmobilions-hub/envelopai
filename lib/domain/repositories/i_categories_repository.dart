import 'package:envelope/domain/models/models.dart';

abstract interface class ICategoriesRepository {
  Stream<List<Category>> watchAll();
  Future<List<Category>> getAll();
  Future<Category?> getById(String id);
  Stream<List<Category>> watchByGroup(String groupId);
  Future<void> save(Category category);
  Future<void> deleteById(String id);
}
