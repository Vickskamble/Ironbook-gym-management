import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/gym_repository.dart';
import '../models/gym_model.dart';
import 'package:ironbook/core/utils/error_handler.dart';

final gymRepositoryProvider = Provider<GymRepository>((ref) {
  return GymRepository(Supabase.instance.client);
});

final gymProvider = FutureProvider.family<GymModel, String>((ref, gymId) {
  ErrorHandler.logStep('gymProvider', 'build', {'gymId': gymId});
  return ref.read(gymRepositoryProvider).getGym(gymId);
});
