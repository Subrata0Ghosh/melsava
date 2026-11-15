import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/melsava_app.dart';
import 'core/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables safely
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // If .env is missing or unreadable, defaults will be handled
  }

  // Initialize Supabase (or fallback dev mode if keys are placeholders)
  await SupabaseService.initialize();

  runApp(const ProviderScope(child: MelsavaApp()));
}
