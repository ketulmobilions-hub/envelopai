import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:envelope/injection.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(
  FutureOr<Widget> Function() builder, {
  String environment = Environment.prod,
}) async {
  // Must be first — required by platform-channel dependencies
  // (Drift, Supabase, path_provider, shared_preferences, etc.).
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  // Initialise dependency injection before runApp.
  // @dev / @prod scoped registrations are resolved using [environment].
  await configureDependencies(environment: environment);

  runApp(await builder());
}
