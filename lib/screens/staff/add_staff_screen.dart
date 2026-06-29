import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/staff_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/staff_model.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../core/utils/validators.dart';

class AddStaffScreen extends ConsumerStatefulWidget {
  const AddStaffScreen({super.key});

  @override
  ConsumerState<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends ConsumerState<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _salaryController = TextEditingController();
  String _selectedRole = 'Trainer';
  String _selectedShift = 'Full Day';
  final _specializationController = TextEditingController();
  DateTime _joinDate = DateTime.now();
  String? _profilePicPath;
  bool _isLoading = false;

  final List<String> _roles = ['Trainer', 'Receptionist', 'Cleaner', 'Manager', 'Other'];
  final List<String> _shifts = ['Morning', 'Evening', 'Full Day'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _salaryController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joinDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _joinDate = picked);
    }
  }

  Future<void> _pickPhoto() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo picker - select from gallery or camera')),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final gymId = ref.read(authProvider).gymId;
      if (gymId == null) throw Exception('No gym selected');

      final staff = StaffModel(
        id: '',
        gymId: gymId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        role: _selectedRole,
        salary: double.tryParse(_salaryController.text.trim()) ?? 0.0,
        joinDate: _joinDate,
        status: 'Active',
        profilePic: _profilePicPath,
        specialization: _selectedRole == 'Trainer' && _specializationController.text.trim().isNotEmpty
            ? _specializationController.text.trim()
            : null,
        shift: _selectedShift,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(staffProvider.notifier).addStaff(staff);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff member added successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
      appBar: AppBar(title: const Text('Add Staff Member')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _pickPhoto,
                      child: Center(
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border, width: 1),
                          ),
                          child: _profilePicPath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(_profilePicPath!, fit: BoxFit.cover),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt_rounded,
                                        color: AppColors.textMuted, size: 28),
                                    const SizedBox(height: 4),
                                    Text('Photo',
                                        style: TextStyle(
                                            color: AppColors.textMuted, fontSize: 11)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hintText: 'Enter full name',
                      validator: (value) => Validators.validateRequired(value, 'Name'),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Phone',
                      hintText: 'Enter 10-digit phone',
                      keyboardType: TextInputType.phone,
                      validator: Validators.validatePhone,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email (optional)',
                      hintText: 'Enter email',
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
                      controller: _passwordController,
                      label: 'Password (optional)',
                      hintText: 'Set login password',
                      obscureText: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Employment Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        filled: true,
                      ),
                      dropdownColor: AppColors.surface,
                      items: _roles.map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _salaryController,
                      label: 'Salary (\u20B9/month)',
                      hintText: 'Enter monthly salary',
                      keyboardType: TextInputType.number,
                      validator: (value) => Validators.validatePositiveNumber(value, 'Salary'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedShift,
                      decoration: const InputDecoration(
                        labelText: 'Shift',
                        filled: true,
                      ),
                      dropdownColor: AppColors.surface,
                      items: _shifts.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedShift = val);
                      },
                    ),
                    if (_selectedRole == 'Trainer') ...[
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _specializationController,
                        label: 'Specialization',
                        hintText: 'e.g. Strength, Yoga, Cardio',
                      ),
                    ],
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Join Date',
                            suffixIcon: Icon(Icons.calendar_today_rounded),
                            filled: true,
                          ),
                          controller: TextEditingController(
                            text: '${_joinDate.day}/${_joinDate.month}/${_joinDate.year}',
                          ),
                          validator: (value) => Validators.validateRequired(value, 'Join date'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Add Staff Member',
                loading: _isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
