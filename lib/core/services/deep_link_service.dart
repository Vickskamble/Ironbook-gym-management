import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class DeepLinkResult {
  final bool success;
  final String? gymId;
  final String? requestId;

  DeepLinkResult({required this.success, this.gymId, this.requestId});
}

typedef DeepLinkCallback = void Function(DeepLinkResult);

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._();
  factory DeepLinkService() => _instance;
  DeepLinkService._();

  AppLinks? _appLinks;
  StreamSubscription<Uri>? _subscription;
  DeepLinkCallback? onPaymentResult;

  Future<void> initialize() async {
    _appLinks = AppLinks();

    if (kIsWeb) {
      return;
    }

    final initialUri = await _appLinks!.getInitialLink();
    if (initialUri != null) {
      _handleUri(initialUri);
    }

    _subscription = _appLinks!.uriLinkStream.listen(_handleUri);
  }

  void _handleUri(Uri uri) {
    if (uri.scheme == 'ironbook' && uri.host == 'payment') {
      final status = uri.queryParameters['status'];
      final gymId = uri.queryParameters['gym_id'];
      final requestId = uri.queryParameters['request_id'];
      onPaymentResult?.call(DeepLinkResult(
        success: status == 'success',
        gymId: gymId,
        requestId: requestId,
      ));
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _appLinks = null;
  }
}
