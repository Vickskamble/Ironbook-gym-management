import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../core/constants/app_colors.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _gymNameController = TextEditingController();
  final _gymAddressController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _gymNameController.dispose();
    _gymAddressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final result = await ref.read(authProvider.notifier).signUp(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          gymName: _gymNameController.text,
          gymAddress: _gymAddressController.text,
          phone: _phoneController.text,
        );
    if (!mounted) return;
    if (result) {
      context.go('/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created! Please check your email to confirm.')),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Row(
                  children: [
                    if (_step > 0)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: AppColors.textPrimary,
                        onPressed: () => setState(() => _step--),
                      )
                    else
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text('Sign In', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    const Spacer(),
                    Row(
                      children: List.generate(3, (i) => Container(
                        width: _step == i ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i <= _step ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ).createShader(bounds),
                  child: Text(
                    ['Account Info', 'Gym Details', 'Verify'][_step],
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ['Create your owner account', 'Tell us about your gym', 'Review and confirm'][_step],
                  style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                if (_step == 0) ...[
                  CustomTextField(label: 'Full Name', hintText: 'John Doe', controller: _nameController, validator: (v) => v == null || v.isEmpty ? 'Name required' : null),
                  const SizedBox(height: 16),
                  CustomTextField(label: 'Email', hintText: 'your@email.com', controller: _emailController, keyboardType: TextInputType.emailAddress, validator: (v) {
                    if (v == null || v.isEmpty) return 'Email required';
                    if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Invalid email';
                    return null;
                  }),
                  const SizedBox(height: 16),
                  CustomTextField(label: 'Password', hintText: 'Min 6 characters', controller: _passwordController, obscureText: true, validator: (v) {
                    if (v == null || v.isEmpty) return 'Password required';
                    if (v.length < 6) return 'Min 6 characters';
                    return null;
                  }),
                  const SizedBox(height: 16),
                  CustomTextField(label: 'Confirm Password', hintText: 'Re-enter password', controller: _confirmPasswordController, obscureText: true, validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirm password required';
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  }),
                ] else if (_step == 1) ...[
                  CustomTextField(label: 'Gym Name', hintText: 'Your Gym Name', controller: _gymNameController, validator: (v) => v == null || v.isEmpty ? 'Gym name required' : null),
                  const SizedBox(height: 16),
                  CustomTextField(label: 'Gym Address', hintText: 'Full address', controller: _gymAddressController, maxLines: 2, validator: (v) => v == null || v.isEmpty ? 'Address required' : null),
                  const SizedBox(height: 16),
                  CustomTextField(label: 'Phone', hintText: '10-digit number', controller: _phoneController, keyboardType: TextInputType.phone, validator: (v) {
                    if (v == null || v.isEmpty) return 'Phone required';
                    if (!RegExp(r'^[0-9]{10}$').hasMatch(v)) return 'Invalid phone';
                    return null;
                  }),
                ] else ...[
                  _buildReviewItem('Name', _nameController.text),
                  _buildReviewItem('Email', _emailController.text),
                  _buildReviewItem('Gym', _gymNameController.text),
                  _buildReviewItem('Phone', _phoneController.text),
                ],
                const SizedBox(height: 32),
                if (authState.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(authState.error!, style: const TextStyle(color: AppColors.danger))),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: PrimaryButton(
                    text: _step == 2 ? 'Create Account' : 'Next',
                    loading: authState.isLoading,
                    onPressed: _step == 2 ? _submit : () => setState(() => _step++),
                  ),
                ),
                if (_step == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Center(
                      child: TextButton(
                        onPressed: () => context.go('/login'),
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(color: AppColors.textSecondary),
                            children: const [TextSpan(text: 'Sign In', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))],
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.check, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}
