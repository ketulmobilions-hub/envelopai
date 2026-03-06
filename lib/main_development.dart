import 'package:envelope/app/app.dart';
import 'package:envelope/bootstrap.dart';
import 'package:injectable/injectable.dart';

Future<void> main() async {
  await bootstrap(() => const App(), environment: Environment.dev);
}
