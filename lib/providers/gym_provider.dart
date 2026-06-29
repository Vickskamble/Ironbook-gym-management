import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/gym_repository.dart';
import '../models/gym_model.dart';

final gymRepositoryProvider = Provider<GymRepository>((ref) {
  return GymRepository();
});

final gymProvider = FutureProvider.family<GymModel, String>((ref, gymId) {
  return ref.read(gymRepositoryProvider).getGym(gymId);
});
