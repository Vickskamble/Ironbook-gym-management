import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook/models/expense_model.dart';

void main() {
  final sampleJson = {
    'id': 'exp1',
    'gym_id': 'gym1',
    'category': 'Rent',
    'title': 'January Rent',
    'amount': 25000,
    'expense_date': '2024-01-01',
    'paid_by': 'Owner',
    'receipt_url': null,
    'note': 'Monthly rent',
    'created_by': 'user1',
    'created_at': '2024-01-01 10:00:00.000',
  };

  group('ExpenseModel', () {
    test('fromJson parses correctly', () {
      final expense = ExpenseModel.fromJson(sampleJson);
      expect(expense.id, 'exp1');
      expect(expense.category, 'Rent');
      expect(expense.title, 'January Rent');
      expect(expense.amount, 25000);
      expect(expense.note, 'Monthly rent');
    });

    test('toJson roundtrip', () {
      final expense = ExpenseModel.fromJson(sampleJson);
      final json = expense.toJson();
      expect(json['title'], 'January Rent');
      expect(json['amount'], 25000);
      expect(json['category'], 'Rent');
    });

    test('copyWith updates fields', () {
      final expense = ExpenseModel.fromJson(sampleJson);
      final updated = expense.copyWith(title: 'February Rent', amount: 26000);
      expect(updated.title, 'February Rent');
      expect(updated.amount, 26000);
      expect(updated.id, 'exp1');
    });
  });
}
