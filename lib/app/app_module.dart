import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@module
abstract class AppModule {
  @preResolve
  @Singleton()
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}
