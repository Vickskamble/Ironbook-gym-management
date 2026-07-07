import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../repositories/admin_repository.dart';
import 'package:ironbook/core/utils/error_handler.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(Supabase.instance.client);
});

final systemStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  ErrorHandler.logStep('systemStatsProvider', 'build');
  return ref.read(adminRepositoryProvider).getPlatformStats();
});

final allGymsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  ErrorHandler.logStep('allGymsProvider', 'build');
  return ref.read(adminRepositoryProvider).getAllGyms();
});

final allStaffProvider = FutureProvider<List<ProfileModel>>((ref) async {
  ErrorHandler.logStep('allStaffProvider', 'build');
  final response = await Supabase.instance.client
      .from('profiles')
      .select('*')
      .order('name');
  return (response as List).map((json) => ProfileModel.fromJson(json as Map<String, dynamic>)).toList();
});
