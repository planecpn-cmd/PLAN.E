import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppSupabaseClient {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    String url = const String.fromEnvironment('SUPABASE_URL');
    String anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

    // Fallback to local config file if not set via --dart-define
    if (url.isEmpty || anonKey.isEmpty) {
      try {
        final String jsonStr = await rootBundle.loadString('env/local.json');
        final Map<String, dynamic> config = jsonDecode(jsonStr) as Map<String, dynamic>;
        url = config['SUPABASE_URL'] as String? ?? '';
        anonKey = config['SUPABASE_ANON_KEY'] as String? ?? '';
      } catch (_) {
        // Default local Supabase values if env/local.json is missing
        url = 'http://127.0.0.1:54321';
        anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NDU1NTUyMDAsImV4cCI6MTk2MTEzMTIwMH0.demo-anon-key';
      }
    }

    if (url.isNotEmpty && anonKey.isNotEmpty) {
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
  }

  static SupabaseClient get client => Supabase.instance.client;
}
