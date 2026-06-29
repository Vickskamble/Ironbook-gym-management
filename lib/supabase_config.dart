import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/utils/error_handler.dart';

class SupabaseConfig {
  static Future<Result<void>> initializeWithResult() async {
    try {
      await dotenv.load();
      
      final url = dotenv.env['SUPABASE_URL'];
      final key = dotenv.env['SUPABASE_ANON_KEY'];
      
      if (url == null || url.isEmpty) {
        return Result.error('SUPABASE_URL not set in .env file');
      }
      
      if (key == null || key.isEmpty) {
        return Result.error('SUPABASE_ANON_KEY not set in .env file');
      }
      
      if (!url.startsWith('https://')) {
        return Result.error('Invalid SUPABASE_URL format. Must start with https://');
      }
      
      await Supabase.initialize(
        url: url,
        publishableKey: key,
      );
      
      ErrorHandler.logInfo('SupabaseConfig', 'Successfully initialized');
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
  
  static SupabaseClient get client => Supabase.instance.client;
  
  static String get url => dotenv.env['SUPABASE_URL'] ?? '';
  static String get publishableKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
}
