import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/plan_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/plan_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../core/utils/validators.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class EditPlanScreen extends ConsumerStatefulWidget {
  final String planId;
  const EditPlanScreen({super.key, required this.planId});

  @override
  ConsumerState<EditPlanScreen> createState() => _EditPlanScreenState();
}

class _EditPlanScreenState extends ConsumerState<EditPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _featureController = TextEditingController();
  final _features = <String>[];
  String _selectedColor = AppColors.primary.toARGB32().toRadixString(16).padLeft(8, '0');
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _featureController.dispose();
    super.dispose();
  }

  void _addFeature() {
    final text = _featureController.text.trim();
    if (text.isNotEmpty && !_features.contains(text)) {
      setState(() => _features.add(text));
      _featureController.clear();
    }
  }

  void _removeFeature(String feature) {
    setState(() => _features.remove(feature));
  }

  void _loadPlanData(PlanModel plan) {
    _nameController.text = plan.name;
    _descriptionController.text = plan.description;
    _priceController.text = plan.price.toString();
    _durationController.text = plan.durationDays.toString();
    _features.clear();
    _features.addAll(plan.features);
    _selectedColor = plan.color;
    _initialized = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).profile;
      if (user == null) {
        throw Exception('User profile not found');
      }

      final gymId = user.gymId;
      if (gymId == null) {
        throw Exception('Gym ID not found');
      }

      final updatedData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'duration_days': int.parse(_durationController.text.trim()),
        'features': List<String>.from(_features),
        'color': _selectedColor,
      };

      ref.read(planProvider(gymId).notifier).updatePlan(widget.planId, gymId, updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan updated successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.error}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gymId = ref.read(authProvider).profile?.gymId;
    if (gymId == null) {
      return const Scaffold(body: Center(child: Text('Gym not found')));
    }
    final plansAsync = ref.watch(planProvider(gymId));
    return plansAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('$err'))),
      data: (plans) {
        final plan = plans.where((p) => p.id == widget.planId).firstOrNull;
        if (plan == null) {
          return const Scaffold(body: Center(child: Text('Plan not found')));
        }
        if (!_initialized) {
          _loadPlanData(plan);
        }
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
              const Text(
                'Plan Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _nameController,
                label: 'Plan Name',
                hintText: 'e.g. Monthly Premium',
                validator: (value) => Validators.validateRequired(value, 'Plan name'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                hintText: 'Describe what this plan includes',
                maxLines: 3,
                validator: (value) => value != null && value.trim().isEmpty ? null : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _priceController,
                label: 'Price (₹)',
                hintText: 'e.g. 999',
                keyboardType: TextInputType.number,
                validator: (value) => Validators.validatePositiveNumber(value, 'Price'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _durationController,
                label: 'Duration (Days)',
                hintText: 'e.g. 30',
                keyboardType: TextInputType.number,
                validator: (value) => Validators.validatePositiveNumber(value, 'Duration'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Features',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _featureController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Unlimited gym access',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                      ),
                      onFieldSubmitted: (_) => _addFeature(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      onPressed: _addFeature,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _features
                    .map((f) => Chip(
                          label: Text(f, style: const TextStyle(fontSize: 13)),
                          deleteIcon: const Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textMuted),
                          onDeleted: () => _removeFeature(f),
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                          ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  text: 'Save Changes',
                  loading: _isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    ],
    ),
      ),
    );
      },
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}