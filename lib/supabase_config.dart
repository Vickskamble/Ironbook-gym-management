import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/utils/error_handler.dart';

class SupabaseConfig {
  static bool _initialized = false;

  /// Reads a value from .env file (loaded via flutter_dotenv)
  static String _fromEnv(String key) => dotenv.env[key] ?? '';

  static Future<Result<void>> initializeWithResult() async {
    try {
      await dotenv.load();

      final url = _fromEnv('SUPABASE_URL');
      final key = _fromEnv('SUPABASE_ANON_KEY');

      if (url.isEmpty) {
        return Result.error('SUPABASE_URL not set in .env file');
      }

      if (key.isEmpty) {
        return Result.error('SUPABASE_ANON_KEY not set in .env file');
      }

      if (!url.startsWith('https://')) {
        return Result.error('Invalid SUPABASE_URL format. Must start with https://');
      }

      await Supabase.initialize(
        url: url,
        publishableKey: key,
      );

      _initialized = true;
      ErrorHandler.logInfo('SupabaseConfig', 'Supabase initialized successfully');
      return Result.success(null);
    } catch (e, stack) {
      ErrorHandler.logError('SupabaseConfig.initializeWithResult', e, stack);
      return Result.error(e, stack);
    }
  }

  static Future<void> initialize() async {
    final result = await initializeWithResult();
    if (result.isError) {
      throw result.error!;
    }
  }

  static SupabaseClient get client {
    assert(_initialized, 'Supabase not initialized yet. Call initialize() first.');
    return Supabase.instance.client;
  }

  static bool get isInitialized => _initialized;

  static String get url => _fromEnv('SUPABASE_URL');
  static String get publishableKey => _fromEnv('SUPABASE_ANON_KEY');
  static String get razorpayKeyId => _fromEnv('RAZORPAY_KEY_ID');
  static String get sentryDsn => _fromEnv('SENTRY_DSN');
}
