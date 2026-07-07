import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/primary_button.dart';

class AddInventoryScreen extends ConsumerStatefulWidget {
  const AddInventoryScreen({super.key});

  @override
  ConsumerState<AddInventoryScreen> createState() => _AddInventoryScreenState();
}

class _AddInventoryScreenState extends ConsumerState<AddInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  final _lowStockController = TextEditingController(text: '5');
  final _supplierController = TextEditingController();
  String _category = 'Supplements';
  String _unit = 'pcs';
  bool _isLoading = false;

  final _categories = ['Supplements', 'Protein', 'Vitamins', 'Equipment', 'Accessories', 'Other'];
  final _units = ['pcs', 'g', 'kg', 'ml', 'L', 'box', 'pack'];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _unitPriceController.dispose();
    _sellingPriceController.dispose();
    _quantityController.dispose();
    _lowStockController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final gymId = ref.read(authProvider).gymId!;
      final data = {
        'gym_id': gymId,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'category': _category,
        'quantity': int.tryParse(_quantityController.text) ?? 0,
        'low_stock_threshold': int.tryParse(_lowStockController.text) ?? 5,
        'unit_price': double.tryParse(_unitPriceController.text) ?? 0,
        'selling_price': double.tryParse(_sellingPriceController.text),
        'supplier': _supplierController.text.trim().isEmpty ? null : _supplierController.text.trim(),
        'unit': _unit,
      };
      await ref.read(inventoryRepositoryProvider).addItem(data);
      ref.invalidate(inventoryListProvider(gymId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added to inventory'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add Inventory Item',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 24),
                      _buildField('Item Name', _nameController, validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                      const SizedBox(height: 14),
                      _buildField('Description (optional)', _descriptionController, maxLines: 2),
                      const SizedBox(height: 14),
                      _buildDropdown('Category', _category, _categories, (v) => setState(() => _category = v!)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _buildField('Unit Price (₹)', _unitPriceController, keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildField('Selling Price (₹)', _sellingPriceController, keyboardType: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _buildField('Initial Qty', _quantityController, keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildDropdown('Unit', _unit, _units, (v) => setState(() => _unit = v!))),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _buildField('Low Stock Alert At', _lowStockController, keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildField('Supplier (optional)', _supplierController)),
                        ],
                      ),
                      const SizedBox(height: 32),
                      PrimaryButton(text: 'Add Item', loading: _isLoading, onPressed: _submit),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => context.pop()),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {TextInputType? keyboardType, int maxLines = 1, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true, fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
