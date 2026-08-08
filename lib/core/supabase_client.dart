import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppSupabaseClient {
  static bool _initialized = false;
  static String _url = '';

  /// Project base URL (e.g. `https://project-ref.supabase.co`), used to build
  /// Edge Function URLs that need to be opened outside `functions.invoke`
  /// (payment gateway checkout/return links).
  static String get baseUrl => _url;

  /// Deep link the OS routes back into this app after an OAuth browser flow.
  /// A custom URL scheme needs no domain — it's registered directly in
  /// AndroidManifest.xml and Info.plist. Swap for a Universal/App Link on a
  /// real domain later without touching any call site of this constant.
  static const String authRedirectUrl = 'planee://login-callback';

  static Future<void> initialize() async {
    if (_initialized) return;

    String url = const String.fromEnvironment('SUPABASE_URL');
    String anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
    String demoEmail = '';
    String demoPassword = '';

    // Load any missing value from env/local.json. A --dart-define can override
    // either setting independently without discarding the other local value.
    if (url.isEmpty || anonKey.isEmpty) {
      try {
        final String jsonStr = await rootBundle.loadString('env/local.json');
        final Map<String, dynamic> config =
            jsonDecode(jsonStr) as Map<String, dynamic>;
        if (url.isEmpty) {
          url = config['SUPABASE_URL'] as String? ?? '';
        }
        if (anonKey.isEmpty) {
          anonKey = config['SUPABASE_ANON_KEY'] as String? ?? '';
        }
        demoEmail = config['DEMO_EMAIL'] as String? ?? '';
        demoPassword = config['DEMO_PASSWORD'] as String? ?? '';
      } catch (e) {
        throw StateError(
          'Failed to load Supabase configuration from env/local.json or --dart-define: $e',
        );
      }
    }

    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL or SUPABASE_ANON_KEY is empty. Provide real keys in env/local.json or --dart-define.',
      );
    }

    await Supabase.initialize(
      url: url,
      // ignore: deprecated_member_use
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _url = url;
    if (Supabase.instance.client.auth.currentUser == null &&
        demoEmail.isNotEmpty &&
        demoPassword.isNotEmpty) {
      await Supabase.instance.client.auth.signInWithPassword(
        email: demoEmail,
        password: demoPassword,
      );
    }
    _initialized = true;
  }

  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError(
        'AppSupabaseClient has not been initialized. Call initialize() first.',
      );
    }
    return Supabase.instance.client;
  }
}
