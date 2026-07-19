import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ironbook/supabase_config.dart';

class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? error;
  final String? requestId;
  final String? checkoutUrl;

  PaymentResult({
    required this.success,
    this.paymentId,
    this.error,
    this.requestId,
    this.checkoutUrl,
  });
}

class PaymentService {
  static final PaymentService _instance = PaymentService._();
  factory PaymentService() => _instance;
  PaymentService._();

  bool get isAvailable {
    final key = SupabaseConfig.razorpayKeyId;
    return key.isNotEmpty && key != 'your_razorpay_key_id';
  }

  String? get _accessToken => Supabase.instance.client.auth.currentSession?.accessToken;

  Future<PaymentResult> createOrder({
    required String gymId,
    required String planType,
    required String planName,
  }) async {
    if (!isAvailable) {
      throw Exception('Payment gateway not configured. Contact support.');
    }

    final token = _accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please log in again.');
    }

    final response = await http.post(
      Uri.parse('${SupabaseConfig.url}/functions/v1/handle-payment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'apikey': SupabaseConfig.publishableKey,
      },
      body: jsonEncode({
        'action': 'create-payment-link',
        'gym_id': gymId,
        'plan_type': planType,
        'plan_name': planName,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      final error = body['error'] ?? 'Failed to create order';
      throw Exception(error.toString());
    }

    final data = jsonDecode(response.body);
    return PaymentResult(
      success: true,
      requestId: data['request_id'],
      checkoutUrl: data['checkout_url'],
    );
  }

  Future<void> openCheckout(String checkoutUrl) async {
    final uri = Uri.parse(checkoutUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      final fallback = await launchUrl(uri, mode: LaunchMode.inAppWebView);
      if (!fallback) {
        throw Exception('Could not open checkout page. Please try again.');
      }
    }
  }
}
