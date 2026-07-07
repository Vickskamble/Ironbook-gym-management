import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook/models/payment_model.dart';

void main() {
  final sampleJson = {
    'id': 'pay1',
    'gym_id': 'gym1',
    'member_id': 'mem1',
    'member_name': 'Rahul Sharma',
    'plan_id': 'plan1',
    'plan_name': 'Basic',
    'amount': 1000,
    'discount': 100,
    'final_amount': 900,
    'paid_at': '2024-01-15 10:00:00.000',
    'method': 'UPI',
    'transaction_id': 'TXN123',
    'note': 'Paid',
    'next_due_date': '2024-02-15',
    'created_by': 'user1',
    'created_at': '2024-01-15 10:00:00.000',
  };

  group('PaymentModel', () {
    test('fromJson parses correctly', () {
      final payment = PaymentModel.fromJson(sampleJson);
      expect(payment.id, 'pay1');
      expect(payment.memberName, 'Rahul Sharma');
      expect(payment.amount, 1000);
      expect(payment.discount, 100);
      expect(payment.finalAmount, 900);
      expect(payment.method, 'UPI');
    });

    test('toJson roundtrip', () {
      final payment = PaymentModel.fromJson(sampleJson);
      final json = payment.toJson();
      expect(json['amount'], 1000);
      expect(json['final_amount'], 900);
      expect(json['method'], 'UPI');
    });

    test('copyWith updates fields', () {
      final payment = PaymentModel.fromJson(sampleJson);
      final updated = payment.copyWith(method: 'Cash', amount: 500);
      expect(updated.method, 'Cash');
      expect(updated.amount, 500);
      expect(updated.id, 'pay1');
    });
  });
}
