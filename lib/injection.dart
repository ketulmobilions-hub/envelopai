import 'package:envelope/injection.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

/// The global service locator instance.
///
/// Prefer injecting dependencies via constructors rather than calling [getIt]
/// directly. Use [getIt] only at composition roots (e.g. BlocProvider
/// factories in the widget tree).
///
/// In tests, call `getIt.reset()` in `setUp`/`tearDown` and re-register
/// fakes via `getIt.registerFactory<T>(() => FakeT())` or use `mocktail`
/// to stub at the repository level.
final GetIt getIt = GetIt.instance;

/// Initialises all registered dependencies for the given [environment].
///
/// Pass [Environment.dev], [Environment.prod], or [Environment.test]
/// (all constants from `package:injectable`). Classes annotated with
/// `@dev` or `@prod` are only registered when the matching environment
/// is active.
///
/// Called once in `bootstrap` before `runApp`.
@InjectableInit()
Future<void> configureDependencies({
  String environment = Environment.prod,
}) async =>
    getIt.init(environment: environment);
