import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'error_handler.dart';
import '../constants/app_colors.dart';

class NetworkUtils {
  static final Connectivity _connectivity = Connectivity();
  static bool _isOnline = true;
  static final _listeners = <VoidCallback>[];

  static bool get isOnline => _isOnline;

  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  static void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  static Future<void> initialize() async {
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    await _checkConnectivity();
  }

  static Future<void> _onConnectivityChanged(
    List<ConnectivityResult> results,
  ) async {
    await _checkConnectivity();
  }

  static Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasConnection = results.any((r) => r != ConnectivityResult.none);

      if (hasConnection) {
        // Verify actual internet access
        final hasInternet = await _verifyInternetAccess();
        if (hasInternet != _isOnline) {
          _isOnline = hasInternet;
          _notifyListeners();
        }
      } else {
        if (_isOnline) {
          _isOnline = false;
          _notifyListeners();
        }
      }
    } catch (e, stack) {
      ErrorHandler.logError('NetworkUtils._checkConnectivity', e, stack);
    }
  }

  static Future<bool> _verifyInternetAccess() async {
    try {
      final result = await InternetAddress.lookup(
        'www.supabase.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> checkInternet() async {
    return await _verifyInternetAccess();
  }
}

class NetworkAwareWidget extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext)? offlineBuilder;

  const NetworkAwareWidget({
    super.key,
    required this.child,
    this.offlineBuilder,
  });

  @override
  State<NetworkAwareWidget> createState() => _NetworkAwareWidgetState();
}

class _NetworkAwareWidgetState extends State<NetworkAwareWidget> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _isOnline = NetworkUtils.isOnline;
    NetworkUtils.addListener(_onConnectivityChanged);
  }

  @override
  void dispose() {
    NetworkUtils.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onConnectivityChanged() {
    if (mounted) {
      setState(() {
        _isOnline = NetworkUtils.isOnline;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOnline) {
      return widget.offlineBuilder?.call(context) ??
          _OfflineBanner(child: widget.child);
    }
    return widget.child;
  }
}

class _OfflineBanner extends StatelessWidget {
  final Widget child;

  const _OfflineBanner({required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.warning,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You\'re offline. Changes will sync when reconnected.',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
