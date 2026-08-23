import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Optional Firebase-backed push integration.
///
/// The app remains runnable without Firebase credentials. Production builds
/// enable this using FIREBASE_* dart defines; tokens are then registered only
/// after the user has granted notification permission.
class PushNotificationService {
  PushNotificationService._();

  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const _iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'com.plane.plan_e',
  );
  static const _webVapidKey = String.fromEnvironment('FIREBASE_WEB_VAPID_KEY');

  static FirebaseMessaging? _messaging;
  static StreamSubscription<String>? _tokenSubscription;
  static StreamSubscription<RemoteMessage>? _openedSubscription;
  static StreamSubscription<AuthState>? _authSubscription;
  static ValueChanged<String>? _onOpen;
  static bool _initializing = false;
  static bool _configured = false;

  static bool get isConfigured => _configured;

  static Future<void> initialize({required ValueChanged<String> onOpen}) async {
    _onOpen = onOpen;
    if (_configured || _initializing || !_hasBuildConfiguration) return;
    if (!_isSupportedPlatform) return;
    _initializing = true;

    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: _apiKey,
          appId: _appId,
          messagingSenderId: _senderId,
          projectId: _projectId,
          authDomain: _authDomain.isEmpty ? null : _authDomain,
          storageBucket: _storageBucket.isEmpty ? null : _storageBucket,
          iosBundleId: _iosBundleId,
        ),
      );
      final messaging = FirebaseMessaging.instance;
      if (!await messaging.isSupported()) return;
      _messaging = messaging;
      _configured = true;

      _tokenSubscription = messaging.onTokenRefresh.listen((token) {
        unawaited(_registerToken(token));
      });
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        _openMessage,
      );
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen((state) {
            if (state.event == AuthChangeEvent.signedIn ||
                state.event == AuthChangeEvent.tokenRefreshed) {
              unawaited(syncIfAuthorized());
            }
          });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) _openMessage(initialMessage);
      await syncIfAuthorized();
    } catch (_) {
      // Missing/invalid platform Firebase setup must not prevent app startup.
      await _tokenSubscription?.cancel();
      await _openedSubscription?.cancel();
      await _authSubscription?.cancel();
      _tokenSubscription = null;
      _openedSubscription = null;
      _authSubscription = null;
      _configured = false;
      _messaging = null;
    } finally {
      _initializing = false;
    }
  }

  static Future<bool> permissionGranted() async {
    final messaging = _messaging;
    if (!_configured || messaging == null) return false;
    final settings = await messaging.getNotificationSettings();
    return _isAuthorized(settings.authorizationStatus);
  }

  static Future<bool> requestPermissionAndRegister() async {
    final messaging = _messaging;
    if (!_configured || messaging == null) return false;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (!_isAuthorized(settings.authorizationStatus)) return false;
    return syncIfAuthorized();
  }

  static Future<bool> syncIfAuthorized() async {
    final messaging = _messaging;
    if (!_configured || messaging == null) return false;
    if (Supabase.instance.client.auth.currentUser == null) return false;
    final settings = await messaging.getNotificationSettings();
    if (!_isAuthorized(settings.authorizationStatus)) return false;

    final token = await messaging.getToken(
      vapidKey: kIsWeb && _webVapidKey.isNotEmpty ? _webVapidKey : null,
    );
    if (token == null || token.isEmpty) return false;
    await _registerToken(token);
    return true;
  }

  /// Removes this device from future sends before the Supabase session ends.
  static Future<void> unregisterCurrentDevice() async {
    final messaging = _messaging;
    if (!_configured || messaging == null) return;
    if (Supabase.instance.client.auth.currentUser == null) return;
    try {
      final token = await messaging.getToken(
        vapidKey: kIsWeb && _webVapidKey.isNotEmpty ? _webVapidKey : null,
      );
      if (token == null || token.isEmpty) return;
      await Supabase.instance.client.rpc(
        'unregister_trip_push_device',
        params: {'p_token': token, 'p_provider': 'fcm'},
      );
    } catch (_) {
      // Signing out must remain available while offline.
    }
  }

  static Future<void> _registerToken(String token) async {
    if (Supabase.instance.client.auth.currentUser == null) return;
    try {
      await Supabase.instance.client.rpc(
        'register_trip_push_device',
        params: {
          'p_token': token,
          'p_platform': _platformName,
          // Firebase registration tokens work for Android, web, and iOS.
          'p_provider': 'fcm',
        },
      );
    } catch (_) {
      // Token refresh will retry, and startup/resume can call sync again.
    }
  }

  static void _openMessage(RemoteMessage message) {
    final route = message.data['route'];
    if (route is String && isSafeTripMessageRoute(route)) {
      _onOpen?.call(route);
    }
  }

  @visibleForTesting
  static bool isSafeTripMessageRoute(String route) {
    return RegExp(r'^/(chat|host/messages)/[0-9a-fA-F-]{36}$').hasMatch(route);
  }

  static bool _isAuthorized(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  static bool get _hasBuildConfiguration =>
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _senderId.isNotEmpty &&
      _projectId.isNotEmpty;

  static bool get _isSupportedPlatform =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  static String get _platformName {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'android';
  }
}
