import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class ErrorHandler {
  static bool _initialized = false;
  
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    
    FlutterError.onError = (details) {
      logError('FlutterError', details.exception, details.stack);
    };
    
    PlatformDispatcher.instance.onError = (error, stack) {
      logError('PlatformDispatcher', error, stack);
      return true;
    };
  }
  
  static void logError(String source, Object? error, StackTrace? stack) {
    final timestamp = DateTime.now().toIso8601String();
    final message = '''
═══════════════════════════════════════════
ERROR [$timestamp] - $source
────────────────────────────────────────────
$error
═══════════════════════════════════════════
''';
    
    developer.log(message, name: 'IronBook', level: 1000, error: error, stackTrace: stack);
    debugPrint(message);
  }
  
  static void logInfo(String source, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final log = '[INFO][$timestamp] $source: $message';
    developer.log(log, name: 'IronBook', level: 800);
    debugPrint(log);
  }
  
  static void logWarning(String source, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final log = '[WARN][$timestamp] $source: $message';
    developer.log(log, name: 'IronBook', level: 900);
    debugPrint(log);
  }
}

class Result<T> {
  final T? value;
  final Object? error;
  final StackTrace? stackTrace;
  
  const Result._({this.value, this.error, this.stackTrace});
  
  factory Result.success(T value) => Result._(value: value);
  factory Result.error(Object error, [StackTrace? stack]) => Result._(error: error, stackTrace: stack);
  
  bool get isSuccess => error == null;
  bool get isError => error != null;
  
  T getOrThrow() {
    if (isError) throw error!;
    return value!;
  }
  
  T getOrElse(T fallback) => isSuccess ? value! : fallback;
}

extension FutureResult<T> on Future<T> {
  Future<Result<T>> toResult() async {
    try {
      final value = await this;
      return Result.success(value);
    } catch (e, stack) {
      return Result.error(e, stack);
    }
  }
}
