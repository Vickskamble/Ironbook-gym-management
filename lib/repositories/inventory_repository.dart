import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/inventory_model.dart';
import '../core/utils/error_handler.dart';

class InventoryRepository {
  final SupabaseClient _client;

  InventoryRepository(this._client);

  Future<List<InventoryItem>> getItems(String gymId, {String? category}) async {
    ErrorHandler.logStep('InventoryRepository.getItems', 'called');
    try {
      dynamic query = _client
          .from('inventory')
          .select()
          .eq('gym_id', gymId)
          .order('name', ascending: true);

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      final data = await query;
      return (data as List).map((e) => InventoryItem.fromJson(e)).toList();
    } catch (e, stack) {
      ErrorHandler.logError('InventoryRepository.getItems', e, stack);
      throw Exception('Failed to load inventory: ${e.toString()}');
    }
  }

  Future<List<InventoryItem>> getLowStockItems(String gymId) async {
    ErrorHandler.logStep('InventoryRepository.getLowStockItems', 'called');
    try {
      final data = await _client
          .from('inventory')
          .select()
          .eq('gym_id', gymId);
      final items = (data as List).map((e) => InventoryItem.fromJson(e)).toList();
      items.retainWhere((item) => item.quantity <= item.lowStockThreshold);
      return items;
    } catch (e, stack) {
      ErrorHandler.logError('InventoryRepository.getLowStockItems', e, stack);
      throw Exception('Failed to load low stock items: ${e.toString()}');
    }
  }

  Future<InventoryItem> addItem(Map<String, dynamic> data) async {
    ErrorHandler.logStep('InventoryRepository.addItem', 'called');
    try {
      const allowedFields = {
        'gym_id', 'name', 'description', 'category', 'quantity',
        'low_stock_threshold', 'unit_price', 'selling_price', 'supplier', 'unit'
      };
      final filtered = Map<String, dynamic>.fromEntries(
        data.entries.where((e) => allowedFields.contains(e.key)),
      );
      final response = await _client
          .from('inventory')
          .insert(filtered)
          .select()
          .single();
      return InventoryItem.fromJson(response);
    } catch (e, stack) {
      ErrorHandler.logError('InventoryRepository.addItem', e, stack);
      throw Exception('Failed to add item: ${e.toString()}');
    }
  }

  Future<InventoryItem> updateItem(String id, Map<String, dynamic> data) async {
    ErrorHandler.logStep('InventoryRepository.updateItem', 'called');
    try {
      const allowedFields = {
        'name', 'description', 'category', 'quantity',
        'low_stock_threshold', 'unit_price', 'selling_price', 'supplier', 'unit'
      };
      final filtered = Map<String, dynamic>.fromEntries(
        data.entries.where((e) => allowedFields.contains(e.key)),
      );
      final response = await _client
          .from('inventory')
          .update(filtered)
          .eq('id', id)
          .select()
          .single();
      return InventoryItem.fromJson(response);
    } catch (e, stack) {
      ErrorHandler.logError('InventoryRepository.updateItem', e, stack);
      throw Exception('Failed to update item: ${e.toString()}');
    }
  }

  Future<InventoryItem> adjustStock(String id, int quantityChange, {String? note}) async {
    ErrorHandler.logStep('InventoryRepository.adjustStock', 'called');
    try {
      final item = await _client
          .from('inventory')
          .select()
          .eq('id', id)
          .single();
      final currentQty = (item['quantity'] as num?)?.toInt() ?? 0;
      final newQty = (currentQty + quantityChange).clamp(0, 999999);
      final response = await _client
          .from('inventory')
          .update({'quantity': newQty})
          .eq('id', id)
          .select()
          .single();
      return InventoryItem.fromJson(response);
    } catch (e, stack) {
      ErrorHandler.logError('InventoryRepository.adjustStock', e, stack);
      throw Exception('Failed to adjust stock: ${e.toString()}');
    }
  }

  Future<InventoryItem> addStock(String gymId, String id, int quantity, double unitPrice, {String? supplier}) async {
    ErrorHandler.logStep('InventoryRepository.addStock', 'called');
    try {
      final item = await _client
          .from('inventory')
          .select()
          .eq('id', id)
          .single();
      final currentQty = (item['quantity'] as num?)?.toInt() ?? 0;
      final newQty = currentQty + quantity;

      await _client.from('inventory_purchases').insert({
        'gym_id': gymId,
        'item_id': id,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': unitPrice * quantity,
        'supplier': supplier ?? item['supplier'],
        'purchased_at': DateTime.now().toIso8601String(),
      });

      final response = await _client
          .from('inventory')
          .update({'quantity': newQty, 'unit_price': unitPrice})
          .eq('id', id)
          .select()
          .single();
      return InventoryItem.fromJson(response);
    } catch (e, stack) {
      ErrorHandler.logError('InventoryRepository.addStock', e, stack);
      throw Exception('Failed to add stock: ${e.toString()}');
    }
  }

  Future<InventoryItem> sellItem(
    String gymId, String id, int quantity, double sellingPrice, {
    String? memberId, String? memberName, String? note,
  }) async {
    ErrorHandler.logStep('InventoryRepository.sellItem', 'called');
    try {
      final item = await _client
          .from('inventory')
          .select()
          .eq('id', id)
          .single();
      final currentQty = (item['quantity'] as num?)?.toInt() ?? 0;
      if (currentQty < quantity) {
        throw Exception('Insufficient stock. Available: $currentQty');
      }
      final newQty = currentQty - quantity;

      await _client.from('inventory_sales').insert({
        'gym_id': gymId,
        'item_id': id,
        'item_name': item['name'],
        'quantity': quantity,
        'unit_price': sellingPrice,
        'total_price': sellingPrice * quantity,
        'member_id': memberId,
        'member_name': memberName,
        'sold_by': _client.auth.currentUser?.id,
        'sold_at': DateTime.now().toIso8601String(),
        'note': note,
      });

      final response = await _client
          .from('inventory')
          .update({'quantity': newQty})
          .eq('id', id)
          .select()
          .single();
      return InventoryItem.fromJson(response);
    } catch (e, stack) {
      ErrorHandler.logError('InventoryRepository.sellItem', e, stack);
      throw Exception('Failed to sell item: ${e.toString()}');
    }
  }

  Future<List<InventorySale>> getSales(String gymId, {int limit = 50}) async {
    ErrorHandler.logStep('InventoryRepository.getSales', 'called');
    try {
      final data = await _client
          .from('inventory_sales')
          .select()
          .eq('gym_id', gymId)
          .order('sold_at', ascending: false)
          .limit(limit);
      return (data as List).map((e) => InventorySale.fromJson(e)).toList();
    } catch (e, stack) {
      ErrorHandler.logError('InventoryRepository.getSales', e, stack);
      throw Exception('Failed to load sales: ${e.toString()}');
    }
  }

  Future<void> deleteItem(String id) async {
    ErrorHandler.logStep('InventoryRepository.deleteItem', 'called');
    try {
      await _client.from('inventory').delete().eq('id', id);
    } catch (e, stack) {
      ErrorHandler.logError('InventoryRepository.deleteItem', e, stack);
      throw Exception('Failed to delete item: ${e.toString()}');
    }
  }
}
