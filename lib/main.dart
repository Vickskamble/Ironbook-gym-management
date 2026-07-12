import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/app_colors.dart';
import 'core/router/app_router.dart';
import 'core/utils/error_handler.dart';
import 'core/services/notification_service.dart';
import 'widgets/error_boundary.dart';
import 'widgets/debug_overlay.dart';
import 'supabase_config.dart';
import 'providers/locale_provider.dart';

Future<void> main() async {
  ErrorHandler.logStep('main', 'App starting');
  WidgetsFlutterBinding.ensureInitialized();
  ErrorHandler.logStep('main', 'WidgetsFlutterBinding initialized');

  await ErrorHandler.initialize();
  ErrorHandler.logStep('main', 'ErrorHandler initialized');

  ErrorHandler.logStep('main', 'Initializing Supabase...');
  final initResult = await SupabaseConfig.initializeWithResult();

  // Initialize Sentry (dotenv must be loaded first — SupabaseConfig.initializeWithResult loads it)
  final sentryDsn = SupabaseConfig.sentryDsn;
  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 0.1;
        options.enableWatchdogTerminationTracking = false;
      },
      appRunner: () => _runApp(initResult),
    );
  } else {
    await _runApp(initResult);
  }
}

Future<void> _runApp(Result<void> initResult) async {

  if (initResult.isSuccess) {
    ErrorHandler.logStep('_runApp', 'Supabase initialized, setting up notifications');
    try {
      await NotificationService.initialize();
      ErrorHandler.logStep('_runApp', 'NotificationService initialized');
    } catch (e, stack) {
      ErrorHandler.logError('main.notifications', e, stack);
    }
  } else {
    ErrorHandler.logError('_runApp', initResult.error, initResult.stackTrace);
  }

  ErrorHandler.logStep('_runApp', 'Running app');
  runApp(ProviderScope(
    child: initResult.isSuccess
        ? const IronBookApp()
        : InitErrorWidget(result: initResult),
  ));
}

class InitErrorWidget extends StatelessWidget {
  final Result<void> result;

  const InitErrorWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final error = result.error;
    final details = !kReleaseMode
        ? (error is Error ? error.toString() : error?.toString() ?? 'Unknown initialization error')
        : null;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ErrorScreen(
        title: 'Initialization Failed',
        message: 'Could not initialize the app. Please check your configuration and restart.',
        details: details,
      ),
    );
  }
}

class IronBookApp extends ConsumerWidget {
  const IronBookApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ErrorHandler.logStep('IronBookApp', 'Building app');
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('hi'), Locale('mr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        return DebugOverlay(
          child: ErrorBoundary(
            onError: (error, stack) {
              ErrorHandler.logError('App.onError', error, stack);
            },
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final String? details;
  final VoidCallback? onRetry;

  const ErrorScreen({
    super.key,
    required this.title,
    required this.message,
    this.details,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.danger,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (details != null && !kReleaseMode) ...[
                const SizedBox(height: 16),
                ExpansionTile(
                  title: const Text('Error Details'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        details!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              if (onRetry != null)
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
