import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_client.dart';
import 'core/onboarding_preferences.dart';
import 'core/scaled_app_viewport.dart';
import 'core/app_version.dart';
import 'core/device_identity.dart';
import 'core/remote_config_service.dart';
import 'core/push_notification_service.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_providers.dart';
import 'theme/app_theme.dart';
import 'widgets/version_gate.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await OnboardingPreferences.initialize();
  await AppVersionInfo.initialize();
  await DeviceIdentity.initialize();
  await AppSupabaseClient.initialize();
  // Firebase is optional in local/demo builds. When FIREBASE_* dart defines
  // are present, this registers only authorized devices and handles the
  // content-free deep link included in trip-message pushes.
  unawaited(
    PushNotificationService.initialize(
      onOpen: (route) {
        WidgetsBinding.instance.addPostFrameCallback((_) => router.go(route));
      },
    ),
  );
  if (!OnboardingPreferences.isCompleted &&
      AppSupabaseClient.client.auth.currentUser != null) {
    await OnboardingPreferences.markCompleted();
  }
  // Cache-only read, no network wait — the first frame renders with
  // last-known-good remote config. A real fetch happens right after, kicked
  // off from PlanEApp.initState() below.
  final cachedRemoteConfig = await RemoteConfigService.loadCached();
  runApp(
    ProviderScope(
      overrides: [
        cachedRemoteConfigSnapshotProvider.overrideWithValue(
          cachedRemoteConfig,
        ),
      ],
      child: const PlanEApp(),
    ),
  );
}

class PlanEApp extends ConsumerStatefulWidget {
  const PlanEApp({super.key});

  @override
  ConsumerState<PlanEApp> createState() => _PlanEAppState();
}

class _PlanEAppState extends ConsumerState<PlanEApp>
    with WidgetsBindingObserver {
  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  DateTime? _pausedAt;

  // How long the app has to sit backgrounded before returning to it replays
  // the splash animation. Not zero: payment (Khalti/eSewa) hands off to an
  // external app or browser and comes straight back via deep link — that's
  // a background/resume cycle too, just a few seconds long, and shouldn't
  // yank the user back to the splash mid-checkout. A genuine "reopened the
  // app later" gap is comfortably longer than this.
  static const Duration _splashReplayThreshold = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Fire-and-forget: the splash screen's ~3.1s runtime is where this
    // completes in practice, invisibly, before the user reaches /home. On
    // failure RemoteConfigNotifier.refresh() keeps the cached state loaded
    // in main() — never blocks, never crashes a screen on a bad network.
    unawaited(ref.read(remoteConfigProvider.notifier).refresh());
    // Real connectivity, replacing the isOfflineProvider that used to be a
    // manual toggle nothing ever set (docs/OFFLINE_CACHE_PLAN.md phase 1).
    // `checkConnectivity()` gives the state at launch; `onConnectivityChanged`
    // only fires on *changes* from here on, so both are needed. This reports
    // connectivity *type*, not real internet reachability — wifi with no
    // upstream still reads as "online" — it's a fast-path signal to skip a
    // doomed network call, not the source of truth for whether a fetch will
    // actually succeed.
    Connectivity().checkConnectivity().then((results) {
      if (mounted) {
        ref
            .read(isOfflineProvider.notifier)
            .setOffline(results.every((r) => r == ConnectivityResult.none));
      }
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      ref
          .read(isOfflineProvider.notifier)
          .setOffline(results.every((r) => r == ConnectivityResult.none));
    });
    // Google/Apple sign-in returns from the system browser via a deep link
    // with no code path of its own to navigate onward — this is that path.
    // Gated on oauthInFlightProvider so it doesn't also fire for the OTP
    // screens' own signedIn events, which navigate themselves.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        router.go('/auth/set-new-password');
        return;
      }
      if (data.event == AuthChangeEvent.signedIn &&
          ref.read(oauthInFlightProvider)) {
        ref.read(oauthInFlightProvider.notifier).state = false;
        final deferred = ref.read(deferredActionProvider);
        authenticatedDestination(Supabase.instance.client, deferred).then((
          destination,
        ) {
          if (!mounted) return;
          router.go(destination);
        });
        if (deferred != null) {
          ref.read(deferredActionProvider.notifier).clear();
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the user backs out of the Google/Apple browser tab without
    // finishing (denies consent, just closes it), no signedIn event ever
    // fires to clear oauthInFlightProvider — it would stay stuck true and
    // wrongly trigger the block above on the next unrelated signedIn event
    // (e.g. the recovery-OTP screen's own verify, racing its navigation to
    // set-new-password against this one going straight to /home). Give a
    // real in-flight sign-in a moment to complete before assuming abandoned.
    if (state == AppLifecycleState.resumed && ref.read(oauthInFlightProvider)) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) ref.read(oauthInFlightProvider.notifier).state = false;
      });
    }

    // Remote config does not subscribe to Realtime, so foreground-resume is
    // its update path for changes made while the app was backgrounded. Chat
    // uses its own table-scoped Realtime stream.
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(remoteConfigProvider.notifier).refresh());
    }

    // Splash as a boot identity, not just a one-time first-launch screen —
    // replay it whenever the app returns to the foreground after being
    // backgrounded for a while, not only on a genuine cold start. Any
    // non-resumed state counts as "backgrounded" here (not just paused) —
    // some Android versions/launchers only reach `inactive` on a quick
    // app-switch without ever hitting `paused`, and that still needs to
    // start the background-duration clock.
    if (state != AppLifecycleState.resumed) {
      _pausedAt ??= DateTime.now();
    } else {
      final pausedAt = _pausedAt;
      _pausedAt = null;
      if (pausedAt != null &&
          DateTime.now().difference(pausedAt) >= _splashReplayThreshold) {
        router.go('/');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Plan E by rabina',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) =>
          ScaledAppViewport(child: VersionGate(child: child!)),
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
