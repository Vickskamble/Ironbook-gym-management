import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final SupabaseClient _client;

  ExpenseRepository(this._client);

  Future<List<ExpenseModel>> getExpenses(
    String gymId, {
    String? category,
    int? month,
    int? year,
    int? page,
    int limit = 20,
  }) async {
    try {
      dynamic query = _client
          .from('expenses')
          .select();
      query = query.eq('gym_id', gymId);
      query = query.order('created_at', ascending: false);

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      if (month != null && year != null) {
        final monthStr = month.toString().padLeft(2, '0');
        query = query
            .gte('expense_date', '$year-$monthStr-01')
            .lt('expense_date', month == 12 ? '${year + 1}-01-01' : '$year-${(month + 1).toString().padLeft(2, '0')}-01');
      } else if (year != null) {
        query = query
            .gte('expense_date', '$year-01-01')
            .lt('expense_date', '${year + 1}-01-01');
      }

      if (page != null) {
        final from = page * limit;
        final to = from + limit - 1;
        query = query.range(from, to);
      }

      final response = await query;
      return (response as List)
          .map((e) => ExpenseModel.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to load expenses: ${e.toString()}');
    }
  }

  Future<ExpenseModel> addExpense(Map<String, dynamic> data) async {
    try {
      final receiptPath = data['receipt_url'] as String?;
      if (receiptPath != null && receiptPath.isNotEmpty && !receiptPath.startsWith('http')) {
        final url = await _uploadReceipt(receiptPath);
        data['receipt_url'] = url;
      }

      final response = await _client
          .from('expenses')
          .insert(data)
          .select()
          .single();

      return ExpenseModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add expense: ${e.toString()}');
    }
  }

  Future<ExpenseModel> updateExpense(
    String gymId,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final receiptPath = data['receipt_url'] as String?;
      if (receiptPath != null && receiptPath.isNotEmpty && !receiptPath.startsWith('http')) {
        final url = await _uploadReceipt(receiptPath);
        data['receipt_url'] = url;
      }

      final response = await _client
          .from('expenses')
          .update(data)
          .eq('gym_id', gymId)
          .eq('id', id)
          .select()
          .single();

      return ExpenseModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update expense: ${e.toString()}');
    }
  }

  Future<void> deleteExpense(String gymId, String id) async {
    try {
      await _client
          .from('expenses')
          .delete()
          .eq('gym_id', gymId)
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete expense: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getExpenseStats(
    String gymId, {
    int? month,
    int? year,
  }) async {
    try {
      final now = DateTime.now();
      final currentMonth = month ?? now.month;
      final currentYear = year ?? now.year;

      final currentMonthStr = currentMonth.toString().padLeft(2, '0');
      final currentStart = '$currentYear-$currentMonthStr-01';
      final currentEnd = currentMonth == 12
          ? '${currentYear + 1}-01-01'
          : '$currentYear-${(currentMonth + 1).toString().padLeft(2, '0')}-01';

      final currentMonthExpenses = await _client
          .from('expenses')
          .select('amount, category')
          .eq('gym_id', gymId)
          .gte('expense_date', currentStart)
          .lt('expense_date', currentEnd);

      num monthlyTotal = 0;
      final Map<String, num> byCategory = {};
      for (final e in currentMonthExpenses) {
        final amount = (e['amount'] as num?) ?? 0;
        monthlyTotal += amount;
        final cat = e['category'] as String? ?? 'Other';
        byCategory[cat] = (byCategory[cat] ?? 0) + amount;
      }

      if (month == null || year == null) {
        final prevMonth = currentMonth == 1 ? 12 : currentMonth - 1;
        final prevYear = currentMonth == 1 ? currentYear - 1 : currentYear;
        final prevMonthStr = prevMonth.toString().padLeft(2, '0');
        final prevStart = '$prevYear-$prevMonthStr-01';
        final prevEnd = prevMonth == 12
            ? '${prevYear + 1}-01-01'
            : '$prevYear-${(prevMonth + 1).toString().padLeft(2, '0')}-01';

        final prevMonthExpenses = await _client
            .from('expenses')
            .select('amount')
            .eq('gym_id', gymId)
          .gte('expense_date', prevStart)
          .lt('expense_date', prevEnd);

        num prevTotal = 0;
        for (final e in prevMonthExpenses) {
          prevTotal += (e['amount'] as num?) ?? 0;
        }

        return {
          'monthlyTotal': monthlyTotal,
          'previousMonthTotal': prevTotal,
          'byCategory': byCategory,
          'count': (currentMonthExpenses as List).length,
        };
      }

      return {
        'monthlyTotal': monthlyTotal,
        'byCategory': byCategory,
        'count': (currentMonthExpenses as List).length,
      };
    } catch (e) {
      throw Exception('Failed to load expense stats: ${e.toString()}');
    }
  }

  Future<String> _uploadReceipt(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      final bytes = await file.readAsBytes();
      final ext = filePath.split('.').last.toLowerCase();
      final contentType = ext == 'pdf'
          ? 'application/pdf'
          : ext == 'png'
              ? 'image/png'
              : 'image/jpeg';
      final fileName =
          'receipts/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _client.storage.from('receipts').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );

      return _client.storage.from('receipts').getPublicUrl(fileName);
    } catch (e) {
      throw Exception('Failed to upload receipt: ${e.toString()}');
    }
  }
}
