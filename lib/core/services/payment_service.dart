import 'dart:async';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:ironbook/core/utils/error_handler.dart';
import 'package:ironbook/supabase_config.dart';

class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? error;

  PaymentResult({required this.success, this.paymentId, this.error});
}

class PaymentService {
  Razorpay? _razorpay;
  bool _initialized = false;
  void Function(PaymentResult)? _onResult;

  static final PaymentService _instance = PaymentService._();
  factory PaymentService() => _instance;
  PaymentService._();

  bool get isAvailable {
    final key = SupabaseConfig.razorpayKeyId;
    return key.isNotEmpty && key != 'your_razorpay_key_id';
  }

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    ErrorHandler.logInfo('PaymentService', 'Payment success: ${response.paymentId}');
    _onResult?.call(PaymentResult(
      success: true,
      paymentId: response.paymentId,
    ));
    _onResult = null;
  }

  void _handleError(PaymentFailureResponse response) {
    ErrorHandler.logError('PaymentService', 'Payment failed: ${response.message}', null);
    _onResult?.call(PaymentResult(
      success: false,
      error: response.message ?? 'Payment failed',
    ));
    _onResult = null;
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ErrorHandler.logInfo('PaymentService', 'External wallet: ${response.walletName}');
  }

  Future<PaymentResult> processPayment({
    required double amount,
    required String description,
    required BuildContext context,
  }) async {
    if (!isAvailable) {
      return PaymentResult(success: true, paymentId: 'simulated');
    }

    initialize();

    final completer = Completer<PaymentResult>();

    _onResult = (result) {
      if (!completer.isCompleted) completer.complete(result);
    };

    try {
      final options = {
        'key': SupabaseConfig.razorpayKeyId,
        'amount': (amount * 100).toInt(),
        'name': 'IronBook',
        'description': description,
        'prefill': {'contact': '', 'email': ''},
        'theme': {'color': '#6366F1'},
      };

      _razorpay!.open(options);

      return await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          _onResult = null;
          return PaymentResult(success: false, error: 'Payment timed out');
        },
      );
    } catch (e, stack) {
      ErrorHandler.logError('PaymentService.processPayment', e, stack);
      _onResult = null;
      return PaymentResult(success: false, error: e.toString());
    }
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    _initialized = false;
  }
}
