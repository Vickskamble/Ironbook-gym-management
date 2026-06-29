import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ironbook/core/constants/app_colors.dart';
import 'package:ironbook/core/utils/error_handler.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final void Function(Object, StackTrace?)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    ErrorHandler.logInfo('ErrorBoundary', 'Initialized');
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, _error!, _stackTrace);
      }
      return _DefaultErrorWidget(
        error: _error!,
        stackTrace: _stackTrace,
        onRetry: _resetError,
      );
    }
    return widget.child;
  }

  void _resetError() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  @override
  void didUpdateWidget(covariant ErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      _resetError();
    }
  }

}

class _DefaultErrorWidget extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback onRetry;

  const _DefaultErrorWidget({
    required this.error,
    this.stackTrace,
    required this.onRetry,
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
                'Something went wrong',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'An unexpected error occurred. Please try again.',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('Error Details'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      error.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AsyncErrorWidget extends StatelessWidget {
  final AsyncSnapshot snapshot;
  final Widget Function(BuildContext) childBuilder;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget? loadingWidget;
  final Widget? emptyWidget;

  const AsyncErrorWidget({
    super.key,
    required this.snapshot,
    required this.childBuilder,
    this.errorBuilder,
    this.loadingWidget,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) {
      return errorBuilder?.call(context, snapshot.error!, snapshot.stackTrace) ??
          _DefaultErrorWidget(
            error: snapshot.error!,
            stackTrace: snapshot.stackTrace,
            onRetry: () => context.go(GoRouterState.of(context).uri.toString()),
          );
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return loadingWidget ??
          const Center(child: CircularProgressIndicator());
    }

    if (snapshot.data == null) {
      return emptyWidget ??
          Center(
            child: Text(
              'No data available',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
    }

    return childBuilder(context);
  }
}
