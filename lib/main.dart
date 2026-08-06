import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/supabase_client.dart';
import 'core/scaled_app_viewport.dart';
import 'core/onboarding_preferences.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await OnboardingPreferences.initialize();
  await AppSupabaseClient.initialize();
  if (!OnboardingPreferences.isCompleted &&
      AppSupabaseClient.client.auth.currentUser != null) {
    await OnboardingPreferences.markCompleted();
  }
  runApp(const ProviderScope(child: PlanEApp()));
}

class PlanEApp extends StatelessWidget {
  const PlanEApp({super.key});

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
