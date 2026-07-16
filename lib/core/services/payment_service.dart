import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
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

  Future<PaymentResult> createOrder({
    required String gymId,
    required String planType,
    required String planName,
    String? createdBy,
  }) async {
    if (!isAvailable) {
      throw Exception('Payment gateway not configured. Contact support.');
    }

    final response = await http.post(
      Uri.parse('${SupabaseConfig.url}/functions/v1/handle-payment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SupabaseConfig.publishableKey}',
        'apikey': SupabaseConfig.publishableKey,
      },
      body: jsonEncode({
        'action': 'create-payment-link',
        'gym_id': gymId,
        'plan_type': planType,
        'plan_name': planName,
        'created_by': createdBy,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['error'] ?? 'Failed to create order';
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
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not open checkout page');
    }
  }
}
