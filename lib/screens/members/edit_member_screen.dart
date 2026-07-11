import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/plan_provider.dart';
import '../../models/plan_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../core/utils/validators.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';

class EditMemberScreen extends ConsumerStatefulWidget {
  final String memberId;
  const EditMemberScreen({super.key, required this.memberId});

  @override
  ConsumerState<EditMemberScreen> createState() => _EditMemberScreenState();
}

class _EditMemberScreenState extends ConsumerState<EditMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  bool _initialized = false;
  DateTime _joinDate = DateTime.now();
  PlanModel? _selectedPlan;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickJoinDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joinDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _joinDate = picked);
    }
  }

  Future<void> _pickPlan(List<PlanModel> plans) async {
    final active = plans.where((p) => p.isActive).toList();
    if (!mounted) return;
    final result = await showModalBottomSheet<PlanModel>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            ...active.map((plan) => ListTile(
              leading: Icon(Icons.card_giftcard_rounded, color: _selectedPlan?.id == plan.id ? AppColors.primary : AppColors.textMuted),
              title: Text(plan.name, style: const TextStyle(color: AppColors.textPrimary)),
              subtitle: Text(plan.formattedPrice, style: const TextStyle(color: AppColors.textSecondary)),
              trailing: _selectedPlan?.id == plan.id ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
              onTap: () => Navigator.pop(ctx, plan),
            )),
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Clear Plan', style: TextStyle(color: AppColors.textMuted)),
            ),
          ],
        ),
      ),
    );
    if (mounted) {
      setState(() => _selectedPlan = result);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final data = {
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
        'join_date': _joinDate.toIso8601String().split('T')[0],
        if (_selectedPlan != null) ...{
          'plan_id': _selectedPlan!.id,
          'plan_name': _selectedPlan!.name,
        },
      };

      final gymId = ref.read(authProvider).gymId;
      if (gymId == null) return;
      await ref
          .read(memberListProvider(gymId).notifier)
          .updateMember(widget.memberId, data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member updated successfully')),
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
    final gymId = ref.watch(authProvider.select((s) => s.gymId));
    if (gymId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final memberAsync = ref.watch(memberDetailProvider((gymId: gymId, memberId: widget.memberId)));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: memberAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('$err')),
                data: (member) {
                    if (!_initialized) {
              _nameController.text = member.name;
              _phoneController.text = member.phone;
              _emailController.text = member.email ?? '';
              _ageController.text = member.age?.toString() ?? '';
              _addressController.text = member.address ?? '';
              _joinDate = member.joinDate;
              _initialized = true;
            }
            final plansAsync = ref.watch(planProvider(gymId));

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Edit Member Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 24),
                          CustomTextField(
                            controller: _nameController,
                            label: AppStrings.name,
                            validator: (value) =>
                                Validators.validateRequired(value, AppStrings.name),
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _phoneController,
                            label: AppStrings.phone,
                            keyboardType: TextInputType.phone,
                            validator: Validators.validatePhone,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _emailController,
                            label: '${AppStrings.email} (${AppStrings.optional})',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _ageController,
                            label: '${AppStrings.age} (${AppStrings.optional})',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _addressController,
                            label: '${AppStrings.address} (${AppStrings.optional})',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _pickJoinDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Join Date', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${_joinDate.day}/${_joinDate.month}/${_joinDate.year}',
                                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.edit_calendar_rounded, color: AppColors.textMuted, size: 18),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          plansAsync.when(
                            data: (plans) => GestureDetector(
                              onTap: () => _pickPlan(plans),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.card_giftcard_rounded, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Plan', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                          const SizedBox(height: 2),
                                          Text(
                                            _selectedPlan?.name ?? member.planName ?? 'No Plan',
                                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.arrow_drop_down_rounded, color: AppColors.textMuted, size: 22),
                                  ],
                                ),
                              ),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (e, _) => const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 32),
                          PrimaryButton(
                            text: 'Update Member',
                            loading: _isLoading,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  );
          },
        ),
      ),
    ],
  ),
));
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
