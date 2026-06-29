import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../models/member_model.dart';
import '../../models/plan_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../core/utils/validators.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';

class AddPaymentScreen extends ConsumerStatefulWidget {
  const AddPaymentScreen({super.key});

  @override
  ConsumerState<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends ConsumerState<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  MemberModel? _selectedMember;
  PlanModel? _selectedPlan;
  String _paymentMethod = 'Cash';
  bool _isLoading = false;

  List<MemberModel> _members = [];
  List<PlanModel> _plans = [];
  bool _loadingMembers = true;
  bool _loadingPlans = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final gymId = ref.read(authProvider).gymId;
    if (gymId == null) return;

    try {
      final membersRes = await Supabase.instance.client
          .from('members')
          .select()
          .eq('gym_id', gymId)
          .eq('status', 'Active');
      _members = (membersRes as List)
          .map((json) => MemberModel.fromJson(json))
          .toList();
    } catch (_) {}

    try {
      final plansRes = await Supabase.instance.client
          .from('plans')
          .select()
          .eq('gym_id', gymId)
          .eq('is_active', true);
      _plans = (plansRes as List)
          .map((json) => PlanModel.fromJson(json))
          .toList();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _loadingMembers = false;
        _loadingPlans = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onPlanSelected(PlanModel? plan) {
    setState(() {
      _selectedPlan = plan;
      if (plan != null) {
        _amountController.text = plan.price.toStringAsFixed(0);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a member')),
      );
      return;
    }
    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plan')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final gymId = ref.read(authProvider).gymId!;
      final now = DateTime.now();

      final data = {
        'gym_id': gymId,
        'member_id': _selectedMember!.id,
        'member_name': _selectedMember!.name,
        'plan_id': _selectedPlan!.id,
        'plan_name': _selectedPlan!.name,
        'amount': _selectedPlan!.price,
        'final_amount': double.parse(_amountController.text.trim()),
        'discount': _selectedPlan!.price - double.parse(_amountController.text.trim()),
        'paid_at': now.toIso8601String(),
        'method': _paymentMethod,
        'note': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      };

      await ref
          .read(paymentListProvider(gymId).notifier)
          .addPayment(gymId, data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              _loadingMembers
                  ? const CircularProgressIndicator()
                    : DropdownButtonFormField<MemberModel>(
                      initialValue: null,
                      decoration: InputDecoration(
                        labelText: 'Select Member',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _members
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text('${m.name} (${m.phone})'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedMember = value);
                      },
                    ),
              const SizedBox(height: 16),
              _loadingPlans
                  ? const CircularProgressIndicator()
                  : DropdownButtonFormField<PlanModel>(
                      initialValue: null,
                      decoration: InputDecoration(
                        labelText: 'Select Plan',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _plans
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                    '${p.name} - \$${p.price.toStringAsFixed(0)} / ${p.durationDays} days'),
                              ))
                          .toList(),
                      onChanged: _onPlanSelected,
                    ),
              if (_selectedPlan != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Expires: ${DateTime.now().add(Duration(days: _selectedPlan!.durationDays)).toString().substring(0, 10)}',
                          style: const TextStyle(
                              color: AppColors.primary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              CustomTextField(
                controller: _amountController,
                label: 'Amount (₹)',
                hintText: 'Enter amount',
                keyboardType: TextInputType.number,
                validator: (value) =>
                    Validators.validatePositiveNumber(value, 'Amount'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: ['Cash', 'UPI', 'Card', 'Cheque', 'Other']
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _paymentMethod = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                hintText: 'Any additional notes',
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Record Payment',
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
