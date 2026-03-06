import 'package:envelope/data/database/app_database.dart';
import 'package:injectable/injectable.dart';

Future<void> _closeDatabase(AppDatabase db) => db.close();

@module
abstract class DatabaseModule {
  @Singleton(dispose: _closeDatabase)
  AppDatabase get appDatabase => AppDatabase();
}
