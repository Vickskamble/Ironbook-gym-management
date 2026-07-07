import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ironbook/core/constants/app_colors.dart';
import 'package:ironbook/providers/auth_provider.dart';
import 'package:ironbook/widgets/custom_text_field.dart';
import 'package:ironbook/widgets/primary_button.dart';
import 'package:ironbook/core/utils/error_handler.dart';
import 'package:ironbook/models/gym_model.dart';

class GymSetupScreen extends ConsumerStatefulWidget {
  const GymSetupScreen({super.key});

  @override
  ConsumerState<GymSetupScreen> createState() => _GymSetupScreenState();
}

class _GymSetupScreenState extends ConsumerState<GymSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || authState.profile == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not authenticated')));
        return;
      }

      final client = Supabase.instance.client;
      final gymResponse = await client.from('gyms').insert({
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.replaceAll(' ', ''),
        'type': _typeController.text.trim().isEmpty ? null : _typeController.text.trim(),
        'owner_id': user.id,
      }).select().single();

      final gym = GymModel.fromJson(gymResponse);

      await client.from('profiles').update({
        'gym_id': gym.id,
        'role': 'owner',
      }).eq('id', user.id);

      final profile = authState.profile!.copyWith(gymId: gym.id);

      ref.read(authProvider.notifier).updateProfileData(profile, gym);

      ErrorHandler.logInfo('GymSetup', 'Gym created successfully');
      if (mounted) context.go('/dashboard');
    } catch (e, stack) {
      ErrorHandler.logError('GymSetup', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.toString()}')));
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text('Set Up Your Gym',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    )),
                const SizedBox(height: 8),
                Text('Tell us about your gym to get started',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    )),
                const SizedBox(height: 32),
                CustomTextField(
                  label: 'Gym Name',
                  hintText: 'Your Gym Name',
                  controller: _nameController,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Gym Type',
                  hintText: 'e.g. CrossFit, Yoga',
                  controller: _typeController,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Address',
                  hintText: 'Full address',
                  controller: _addressController,
                  maxLines: 3,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Phone',
                  hintText: '98XXX XXXXX',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final clean = v.replaceAll(RegExp(r'\D'), '');
                    if (clean.length != 10) return 'Enter 10 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  text: 'Create Gym',
                  loading: _isLoading,
                  onPressed: _isLoading ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
