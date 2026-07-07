import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/inventory_model.dart';
import '../repositories/inventory_repository.dart';
import 'package:ironbook/core/utils/error_handler.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(Supabase.instance.client);
});

final inventoryListProvider = FutureProvider.family<List<InventoryItem>, String>((ref, gymId) {
  ErrorHandler.logStep('inventoryListProvider', 'build', {'gymId': gymId});
  return ref.read(inventoryRepositoryProvider).getItems(gymId);
});

final inventorySalesProvider = FutureProvider.family<List<InventorySale>, String>((ref, gymId) {
  ErrorHandler.logStep('inventorySalesProvider', 'build', {'gymId': gymId});
  return ref.read(inventoryRepositoryProvider).getSales(gymId);
});

final lowStockCountProvider = FutureProvider.family<int, String>((ref, gymId) async {
  ErrorHandler.logStep('lowStockCountProvider', 'build', {'gymId': gymId});
  final items = await ref.read(inventoryRepositoryProvider).getItems(gymId);
  return items.where((i) => i.isLowStock).length;
});
