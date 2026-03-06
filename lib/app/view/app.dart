import 'package:envelope/app/theme/app_theme.dart';
import 'package:envelope/l10n/l10n.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key, this.themeMode = ThemeMode.system});

  /// Controls light / dark / system theme.
  /// Wired to a user preference in Phase 9.
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: Center(child: Text('EnvelopAI')),
      ),
    );
  }
}
