import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/dashboard_repository.dart';
import '../models/member_model.dart';
import 'package:ironbook/core/utils/error_handler.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(Supabase.instance.client);
});

final dashboardStatsProvider = FutureProvider.family<DashboardStats, String>((ref, gymId) {
  ErrorHandler.logStep('dashboardStatsProvider', 'build', {'gymId': gymId});
  return ref.read(dashboardRepositoryProvider).getDashboardStats(gymId);
});

final revenueDataProvider = FutureProvider.family<List<MonthlyRevenue>, String>((ref, gymId) {
  ErrorHandler.logStep('revenueDataProvider', 'build', {'gymId': gymId});
  return ref.read(dashboardRepositoryProvider).getLastSixMonthsRevenue(gymId);
});

final recentMembersProvider = FutureProvider.family<List<MemberModel>, String>((ref, gymId) {
  ErrorHandler.logStep('recentMembersProvider', 'build', {'gymId': gymId});
  return ref.read(dashboardRepositoryProvider).getRecentMembers(gymId);
});

final expiringMembersProvider = FutureProvider.family<List<MemberModel>, String>((ref, gymId) {
  ErrorHandler.logStep('expiringMembersProvider', 'build', {'gymId': gymId});
  return ref.read(dashboardRepositoryProvider).getExpiringMembers(gymId);
});

final formattedRevenueProvider = Provider.family<String, String>((ref, gymId) {
  ErrorHandler.logStep('formattedRevenueProvider', 'build', {'gymId': gymId});
  final statsAsync = ref.watch(dashboardStatsProvider(gymId));
  return statsAsync.when(
    data: (stats) => '₹${stats.thisMonthRevenue.toStringAsFixed(0)}',
    loading: () => '₹0',
    error: (_, _) => '₹0',
  );
});

final revenueTrendProvider = Provider.family<String, String>((ref, gymId) {
  ErrorHandler.logStep('revenueTrendProvider', 'build', {'gymId': gymId});
  final revenueAsync = ref.watch(revenueDataProvider(gymId));
  return revenueAsync.when(
    data: (revenueData) {
      if (revenueData.length < 2) return '+0%';
      final currentMonth = revenueData.last.amount;
      final previousMonth = revenueData[revenueData.length - 2].amount;
      if (previousMonth == 0) {
        return currentMonth > 0 ? '+100%' : '+0%';
      }
      final percentage = ((currentMonth - previousMonth) / previousMonth * 100);
      return '${percentage > 0 ? '+' : ''}${percentage.toStringAsFixed(0)}%';
    },
    loading: () => '+0%',
    error: (_, _) => '+0%',
  );
});

String formatCurrency(num amount) {
  return '₹${amount.toStringAsFixed(0)}';
}

String getMemberInitials(String name) {
  if (name.isEmpty) return '';
  final words = name.split(' ');
  if (words.length == 1) return words[0][0].toUpperCase();
  return (words[0][0] + words[words.length - 1][0]).toUpperCase();
}

Color getStatusColor(String status) {
  switch (status) {
    case 'Active':
      return const Color(0xFF10B981);
    case 'Expired':
      return const Color(0xFFEF4444);
    case 'Paused':
      return const Color(0xFFF59E0B);
    case 'Deleted':
      return const Color(0xFF475569);
    default:
      return const Color(0xFF64748B);
  }
}

String getStatusLabel(String status) {
  switch (status) {
    case 'Active':
      return 'Active';
    case 'Expired':
      return 'Expired';
    case 'Paused':
      return 'Paused';
    case 'Deleted':
      return 'Deleted';
    case 'Expired Today':
      return 'Expired Today';
    default:
      return status;
  }
}
