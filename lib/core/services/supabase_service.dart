import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central Supabase service manager.
/// Safely initializes live Supabase if valid credentials exist in .env,
/// or enables development demo mode if placeholders are present.
class SupabaseService {
  SupabaseService._();

  static bool _isInitialized = false;
  static bool get isConfigured => _isConfigured;
  static bool _isConfigured = false;

  static SupabaseClient? get client =>
      _isConfigured ? Supabase.instance.client : null;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    String url = const String.fromEnvironment('SUPABASE_URL');
    String anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

    if (dotenv.isInitialized) {
      url = dotenv.maybeGet('SUPABASE_URL') ?? url;
      anonKey = dotenv.maybeGet('SUPABASE_ANON_KEY') ?? anonKey;
    }

    final isValidConfig =
        url.isNotEmpty &&
        url.startsWith('https://') &&
        !url.contains('your-project-id') &&
        anonKey.isNotEmpty &&
        !anonKey.contains('your-anon-key');

    if (isValidConfig) {
      try {
        await Supabase.initialize(
          url: url,
          publishableKey: anonKey,
          debug: kDebugMode,
        );
        _isConfigured = true;
        debugPrint('[SupabaseService] Live Supabase initialized successfully.');
      } catch (e) {
        debugPrint('[SupabaseService] Error initializing live Supabase: $e');
        _isConfigured = false;
      }
    } else {
      debugPrint(
        '[SupabaseService] Running in Development Mode (placeholder credentials in .env).',
      );
      _isConfigured = false;
    }

    _isInitialized = true;
  }
}
