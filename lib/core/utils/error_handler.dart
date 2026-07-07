import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class DebugLog {
  final DateTime timestamp;
  final String level;
  final String source;
  final String message;
  final String? error;
  final String? stackTrace;

  DebugLog({
    required this.timestamp,
    required this.level,
    required this.source,
    required this.message,
    this.error,
    this.stackTrace,
  });
}

class ErrorHandler {
  static bool _initialized = false;

  static final List<DebugLog> _debugBuffer = [];
  static int get logCount => _debugBuffer.length;
  static List<DebugLog> get recentLogs => List.unmodifiable(_debugBuffer);
  static final int _maxLogs = 500;

  static List<DebugLog> getLogsBySource(String source) {
    return _debugBuffer.where((l) => l.source == source).toList();
  }

  static void clearLogs() => _debugBuffer.clear();

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    FlutterError.onError = (details) {
      logError('FlutterError', details.exception, details.stack);
      FlutterError.dumpErrorToConsole(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      logError('PlatformDispatcher', error, stack);
      return true;
    };
  }

  static void _addLog(DebugLog log) {
    _debugBuffer.add(log);
    if (_debugBuffer.length > _maxLogs) {
      _debugBuffer.removeAt(0);
    }
  }

  static void logError(String source, Object? error, StackTrace? stack) {
    final timestamp = DateTime.now();
    final msg = 'ERROR: $error';
    final stackStr = stack?.toString();

    _addLog(DebugLog(
      timestamp: timestamp,
      level: 'ERROR',
      source: source,
      message: msg,
      error: error.toString(),
      stackTrace: stackStr,
    ));

    if (kReleaseMode) return;

    final formatted = '''
═══════════════════════════════════════════
ERROR [${timestamp.toIso8601String()}] - $source
────────────────────────────────────────────
$error
${stackStr != null ? 'STACK:\n$stackStr\n' : ''}═══════════════════════════════════════════
''';

    developer.log(formatted, name: 'IronBook', level: 1000, error: error, stackTrace: stack);
    debugPrint(formatted);
  }

  static void logInfo(String source, String message) {
    final timestamp = DateTime.now();
    final log = '[INFO][${timestamp.toIso8601String()}] $source: $message';

    _addLog(DebugLog(
      timestamp: timestamp,
      level: 'INFO',
      source: source,
      message: message,
    ));

    if (kReleaseMode) return;

    developer.log(log, name: 'IronBook', level: 800);
    debugPrint(log);
  }

  static void logWarning(String source, String message) {
    final timestamp = DateTime.now();
    final log = '[WARN][${timestamp.toIso8601String()}] $source: $message';

    _addLog(DebugLog(
      timestamp: timestamp,
      level: 'WARN',
      source: source,
      message: message,
    ));

    if (kReleaseMode) return;

    developer.log(log, name: 'IronBook', level: 900);
    debugPrint(log);
  }

  static void logStep(String source, String step, [Map<String, dynamic>? data]) {
    final details = data != null ? ' | data: $data' : '';
    logInfo(source, 'STEP: $step$details');
  }

  static void logApi(String source, String method, String endpoint, {Object? request, Object? response, Object? error}) {
    final buf = StringBuffer('API $method $endpoint');
    if (request != null) buf.write(' | REQ: $request');
    if (response != null) buf.write(' | RES: $response');
    if (error != null) buf.write(' | ERR: $error');
    final msg = buf.toString();
    if (error != null) {
      _addLog(DebugLog(
        timestamp: DateTime.now(),
        level: 'ERROR',
        source: source,
        message: msg,
        error: error.toString(),
      ));
      if (kReleaseMode) return;
      developer.log(msg, name: 'IronBook', level: 1000);
      debugPrint('ERROR: $msg');
    } else {
      logInfo(source, msg);
    }
  }

  static void logDbQuery(String source, String table, String action, {Object? filters, Object? result}) {
    final msg = 'DB $action $table | filters: $filters | result: $result';
    logInfo(source, msg);
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
