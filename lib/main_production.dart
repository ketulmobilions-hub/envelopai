import 'package:envelope/app/app.dart';
import 'package:envelope/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
