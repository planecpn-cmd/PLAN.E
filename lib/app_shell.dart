import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/scaled_app_viewport.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Shared PLAN E application shell.
///
/// Shared production router, theme, localization, and viewport configuration.
class PlanEAppShell extends StatelessWidget {
  const PlanEAppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PLAN E',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) => ScaledAppViewport(child: child!),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
