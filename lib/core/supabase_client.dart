import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppSupabaseClient {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    String url = const String.fromEnvironment('SUPABASE_URL');
    String anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

    // Load from env/local.json if not passed via --dart-define
    if (url.isEmpty || anonKey.isEmpty) {
      try {
        final String jsonStr = await rootBundle.loadString('env/local.json');
        final Map<String, dynamic> config = jsonDecode(jsonStr) as Map<String, dynamic>;
        url = config['SUPABASE_URL'] as String? ?? '';
        anonKey = config['SUPABASE_ANON_KEY'] as String? ?? '';
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
    _initialized = true;
  }

  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError('AppSupabaseClient has not been initialized. Call initialize() first.');
    }
    return Supabase.instance.client;
  }
}
