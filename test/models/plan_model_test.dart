import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook/models/plan_model.dart';

void main() {
  final sampleJson = {
    'id': 'plan1',
    'gym_id': 'gym1',
    'name': 'Basic Plan',
    'description': 'Basic gym access',
    'price': 999.50,
    'duration_days': 30,
    'features': ['Gym Access', 'Locker'],
    'color': '#6366F1',
    'is_active': true,
    'created_at': '2024-01-01 10:00:00.000',
    'updated_at': '2024-01-01 10:00:00.000',
  };

  group('PlanModel', () {
    test('fromJson parses correctly', () {
      final plan = PlanModel.fromJson(sampleJson);
      expect(plan.id, 'plan1');
      expect(plan.name, 'Basic Plan');
      expect(plan.price, 999.50);
      expect(plan.durationDays, 30);
      expect(plan.features.length, 2);
      expect(plan.isActive, true);
    });

    test('toJson roundtrip', () {
      final plan = PlanModel.fromJson(sampleJson);
      final json = plan.toJson();
      expect(json['name'], 'Basic Plan');
      expect(json['price'], 999.50);
    });

    test('formattedPrice adds rupee symbol and rounds', () {
      final plan = PlanModel.fromJson(sampleJson);
      expect(plan.formattedPrice, contains('₹'));
      expect(plan.formattedPrice, contains('1000'));
    });

    test('durationLabel returns days string', () {
      final plan = PlanModel.fromJson({...sampleJson, 'duration_days': 30});
      expect(plan.durationLabel, '30 days');

      final single = PlanModel.fromJson({...sampleJson, 'duration_days': 1});
      expect(single.durationLabel, '1 day');
    });

    test('isPopular returns true for mid-range prices', () {
      final mid = PlanModel.fromJson({...sampleJson, 'price': 1500});
      expect(mid.isPopular, true);

      final cheap = PlanModel.fromJson({...sampleJson, 'price': 100});
      expect(cheap.isPopular, false);

      final expensive = PlanModel.fromJson({...sampleJson, 'price': 5000});
      expect(expensive.isPopular, false);
    });

    test('statusColor and statusLabel reflect isActive', () {
      final active = PlanModel.fromJson(sampleJson);
      expect(active.statusLabel, 'Active');

      final inactive = PlanModel.fromJson({...sampleJson, 'is_active': false});
      expect(inactive.statusLabel, 'Inactive');
    });

    test('copyWith updates fields', () {
      final plan = PlanModel.fromJson(sampleJson);
      final updated = plan.copyWith(name: 'Premium Plan', price: 1999);
      expect(updated.name, 'Premium Plan');
      expect(updated.price, 1999);
      expect(updated.id, 'plan1');
    });
  });
}
