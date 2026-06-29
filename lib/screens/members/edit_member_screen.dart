import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/member_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../core/utils/validators.dart';
import '../../core/constants/app_strings.dart';

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
      };

      await ref
          .read(memberListProvider(ref.read(authProvider).gymId!).notifier)
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
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Member')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final memberAsync = ref.watch(memberDetailProvider((gymId: gymId, memberId: widget.memberId)));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Member')),
      body: memberAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('$err')),
        data: (member) {
          if (!_initialized) {
            _nameController.text = member.name;
            _phoneController.text = member.phone;
            _emailController.text = member.email ?? '';
            _ageController.text = member.age?.toString() ?? '';
            _addressController.text = member.address ?? '';
            _initialized = true;
          }

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
    );
  }
}
