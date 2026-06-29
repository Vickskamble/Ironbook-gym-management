import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/member_provider.dart';
import '../../models/plan_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/glass_container.dart';
import '../../core/utils/validators.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class AddMemberScreen extends ConsumerStatefulWidget {
  const AddMemberScreen({super.key});

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  PlanModel? _selectedPlan;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final gymId = ref.read(authProvider).gymId!;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final durationDays = _selectedPlan?.durationDays ?? 30;
      final membershipEnd = today.add(Duration(days: durationDays));
      final data = {
        'gym_id': gymId,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        'age': _ageController.text.trim().isEmpty
            ? null
            : int.tryParse(_ageController.text.trim()),
        'address': _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        'plan_id': _selectedPlan?.id,
        'plan_name': _selectedPlan?.name,
        'join_date': today.toIso8601String().split('T')[0],
        'membership_start': today.toIso8601String().split('T')[0],
        'membership_end': membershipEnd.toIso8601String().split('T')[0],
      };

      await ref.read(memberListProvider(gymId).notifier).addMember(gymId, data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.memberAdded)),
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildPlanSelector() {
    final gymId = ref.read(authProvider).gymId;
    if (gymId == null) return const SizedBox.shrink();
    final plansAsync = ref.watch(planProvider(gymId));
    return plansAsync.when(
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (plans) {
        return GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          borderRadius: 12,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PlanModel?>(
              isExpanded: true,
              value: _selectedPlan,
              hint: Text('Select Plan (optional)',
                  style: TextStyle(color: AppColors.textMuted)),
              dropdownColor: AppColors.surface,
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text('No Plan',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
                ...plans.map((plan) => DropdownMenuItem(
                      value: plan,
                      child: Text(plan.name,
                          style: const TextStyle(color: Colors.white)),
                    )),
              ],
              onChanged: (plan) {
                setState(() => _selectedPlan = plan);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.addMember)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.memberDetails,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _nameController,
                label: AppStrings.name,
                hintText: AppStrings.enterName,
                validator: (value) => Validators.validateRequired(value, AppStrings.name),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                label: AppStrings.phone,
                hintText: AppStrings.enterPhone,
                keyboardType: TextInputType.phone,
                validator: Validators.validatePhone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                label: '${AppStrings.email} (${AppStrings.optional})',
                hintText: AppStrings.enterEmail,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    return Validators.validateEmail(value);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _ageController,
                label: '${AppStrings.age} (${AppStrings.optional})',
                hintText: AppStrings.enterAge,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _addressController,
                label: '${AppStrings.address} (${AppStrings.optional})',
                hintText: AppStrings.enterAddress,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildPlanSelector(),
              const SizedBox(height: 32),
              PrimaryButton(
                text: AppStrings.addMember,
                loading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
