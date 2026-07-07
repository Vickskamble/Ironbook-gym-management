import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../core/constants/app_colors.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _gymNameController = TextEditingController();
  final _gymTypeController = TextEditingController();
  final _gymAddressController = TextEditingController();
  final _phoneController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _gymNameFocusNode = FocusNode();
  final _gymTypeFocusNode = FocusNode();
  final _gymAddressFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();

  double _passwordStrength = 0.0;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _confirmMatchError;
  bool _isFormattingPhone = false;
  bool _agreedToTerms = false;
  bool _showSuccessOverlay = false;
  String? _highlightedField;

  late AnimationController _stepAnimController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late AnimationController _successAnimController;
  late Animation<double> _successScaleAnimation;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_checkFields);
    _emailController.addListener(_checkFields);
    _passwordController.addListener(_onPasswordChanged);
    _confirmPasswordController.addListener(_checkFields);
    _confirmPasswordFocusNode.addListener(_onConfirmBlur);
    _phoneController.addListener(_onPhoneChanged);

    _stepAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _stepAnimController,
      curve: Curves.easeInOut,
    ));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _stepAnimController,
      curve: Curves.easeInOut,
    ));
    _stepAnimController.forward();

    _successAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _successAnimController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkFields);
    _emailController.removeListener(_checkFields);
    _passwordController.removeListener(_onPasswordChanged);
    _confirmPasswordController.removeListener(_checkFields);
    _confirmPasswordFocusNode.removeListener(_onConfirmBlur);
    _phoneController.removeListener(_onPhoneChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _gymNameController.dispose();
    _gymTypeController.dispose();
    _gymAddressController.dispose();
    _phoneController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _gymNameFocusNode.dispose();
    _gymTypeFocusNode.dispose();
    _gymAddressFocusNode.dispose();
    _phoneFocusNode.dispose();
    _stepAnimController.dispose();
    _successAnimController.dispose();
    super.dispose();
  }

  void _checkFields() {
    setState(() {});
  }

  void _onPasswordChanged() {
    _checkFields();
    final text = _passwordController.text;
    if (text.isEmpty) {
      setState(() => _passwordStrength = 0.0);
      return;
    }
    int score = 0;
    if (text.length >= 8) score += 20;
    if (text.length >= 10) score += 15;
    if (text.contains(RegExp(r'[a-z]'))) score += 15;
    if (text.contains(RegExp(r'[A-Z]'))) score += 15;
    if (text.contains(RegExp(r'[0-9]'))) score += 15;
    if (text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score += 20;
    setState(() => _passwordStrength = score / 100.0);
  }

  void _onConfirmBlur() {
    if (!_confirmPasswordFocusNode.hasFocus) {
      final confirm = _confirmPasswordController.text;
      final pass = _passwordController.text;
      if (confirm.isNotEmpty && confirm != pass) {
        setState(() => _confirmMatchError = "Passwords don't match");
      } else if (confirm.isNotEmpty && confirm == pass) {
        setState(() => _confirmMatchError = null);
      } else {
        setState(() => _confirmMatchError = null);
      }
    }
  }

  void _onPhoneChanged() {
    if (_isFormattingPhone) return;
    _isFormattingPhone = true;
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > 10 ? digits.substring(0, 10) : digits;
    final cursor = _phoneController.selection.baseOffset;
    String formatted = trimmed;
    if (trimmed.length > 5) {
      formatted = '${trimmed.substring(0, 5)} ${trimmed.substring(5)}';
    }
    if (_phoneController.text != formatted) {
      _phoneController.text = formatted;
      if (cursor <= 5) {
        _phoneController.selection = TextSelection.collapsed(offset: cursor);
      } else if (trimmed.length > 5 && cursor >= 5) {
        _phoneController.selection = TextSelection.collapsed(offset: cursor + 1);
      }
    }
    _isFormattingPhone = false;
  }

  void _goToStep(int step, {FocusNode? focusNode}) {
    setState(() => _step = step);
    _stepAnimController.reset();
    _stepAnimController.forward();
    if (focusNode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => focusNode.requestFocus());
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final result = await ref.read(authProvider.notifier).signUp(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          gymName: _gymNameController.text,
          gymAddress: _gymAddressController.text,
          phone: _phoneController.text.replaceAll(' ', ''),
          gymType: _gymTypeController.text.trim(),
        );
    if (!mounted) return;
    if (result) {
      setState(() => _showSuccessOverlay = true);
      _successAnimController.forward();
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      context.go('/dashboard');
    } else {
      final err = ref.read(authProvider).error;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err ?? 'Something went wrong',
                style: GoogleFonts.inter(fontSize: 13)),
            backgroundColor: const Color(0xFF1A0A0A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Top bar
                    Row(
                      children: [
                        if (_step > 0)
                          GestureDetector(
                            onTap: () => _goToStep(_step - 1),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              child: Text('Sign In',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  )),
                            ),
                          ),
                        const Spacer(),
                        _buildStepIndicator(),
                      ],
                    ),
                    const SizedBox(height: 36),
                    // Header
                    AnimatedBuilder(
                      animation: _stepAnimController,
                      builder: (context, child) {
                        return SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFD4C8FF), Color(0xFF6D5DF6)],
                            ).createShader(bounds),
                            child: Text(
                              ['Account Info', 'Gym Details', 'Verify'][_step],
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 27,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.27,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ['Create your owner account', 'Tell us about your gym', 'Review and confirm before you launch'][_step],
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Error toast
                    if (authState.error != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A0A0A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(authState.error!,
                                  style: GoogleFonts.inter(
                                    color: AppColors.danger,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ),
                          ],
                        ),
                      ),
                    // Step content
                    if (_step == 0) ..._buildAccountInfoStep() else if (_step == 1) ..._buildGymDetailsStep() else ..._buildVerifyStep(),
                    const SizedBox(height: 28),
                    // Terms checkbox for step 2
                    if (_step == 2)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                              child: Container(
                                width: 19,
                                height: 19,
                                margin: const EdgeInsets.only(top: 1),
                                decoration: BoxDecoration(
                                  gradient: _agreedToTerms
                                      ? const LinearGradient(
                                          colors: [Color(0xFF6D5DF6), Color(0xFFB15CF6)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: _agreedToTerms ? null : Colors.transparent,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: _agreedToTerms ? Colors.transparent : AppColors.border,
                                    width: 1.5,
                                  ),
                                ),
                                child: _agreedToTerms
                                    ? const Icon(Icons.check, color: Colors.white, size: 13)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  text: 'I agree to the ',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Terms of Service',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                      recognizer: null,
                                    ),
                                    TextSpan(
                                      text: ' and ',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Button
                    PrimaryButton(
                      text: _step == 2 ? 'Create Account' : 'Next',
                      loading: authState.isLoading && _step == 2,
                      onPressed: authState.isLoading
                          ? null
                          : (_step == 0
                              ? () {
                                  if (_formKey.currentState!.validate()) {
                                    _goToStep(1);
                                  }
                                }
                              : (_step == 1
                                  ? () {
                                      if (_gymNameController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Gym name is required'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                        );
                                        return;
                                      }
                                      if (_phoneController.text.replaceAll(RegExp(r'\D'), '').length != 10) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Valid 10-digit phone is required'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                        );
                                        return;
                                      }
                                      _goToStep(2);
                                    }
                                  : (_agreedToTerms && !authState.isLoading
                                      ? _submit
                                      : null))),
                    ),
                    if (_step == 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Center(
                          child: GestureDetector(
                            onTap: () => context.go('/login'),
                            child: RichText(
                              text: TextSpan(
                                text: 'Already have an account? ',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Sign In',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
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
          // Success overlay
          if (_showSuccessOverlay)
            _buildSuccessOverlay(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final isActive = i == _step;
        final isDone = i < _step;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isDone || isActive
                    ? const LinearGradient(
                        colors: [Color(0xFF6D5DF6), Color(0xFFB15CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isDone || isActive ? null : Colors.transparent,
                border: Border.all(
                  color: isDone || isActive ? Colors.transparent : AppColors.border,
                  width: 1.5,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6D5DF6).withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, color: Colors.white, size: 13)
                    : Text('${i + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : AppColors.textMuted,
                        )),
              ),
            ),
            if (i < 2)
              Container(
                width: 24,
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: isDone
                      ? const LinearGradient(
                          colors: [Color(0xFF6D5DF6), Color(0xFFB15CF6)],
                        )
                      : null,
                  color: isDone ? null : AppColors.border,
                ),
              ),
          ],
        );
      }),
    );
  }

  List<Widget> _buildAccountInfoStep() {
    final confirmMatch = _confirmPasswordController.text.isNotEmpty &&
        _confirmPasswordController.text == _passwordController.text &&
        !_confirmPasswordFocusNode.hasFocus;
    final confirmMismatch = _confirmMatchError != null;

    return [
      CustomTextField(
        label: 'Full Name',
        hintText: 'John Doe',
        controller: _nameController,
        focusNode: _nameFocusNode,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
        validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Email',
        hintText: 'your@email.com',
        controller: _emailController,
        focusNode: _emailFocusNode,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Email required';
          if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) return 'Invalid email';
          return null;
        },
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Password',
        hintText: 'Min 8 characters, 1 upper, 1 number',
        controller: _passwordController,
        obscureText: _obscurePassword,
        focusNode: _passwordFocusNode,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Password required';
          if (v.length < 8) return 'Min 8 characters';
          return null;
        },
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: _obscurePassword ? AppColors.textMuted : AppColors.primary,
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      // Password strength bar
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Container(
          height: 3,
          width: double.infinity,
          color: AppColors.border,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _passwordStrength,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF59E0B),
                    const Color(0xFF84CC16),
                    const Color(0xFF10B981),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      // Confirm Password
      CustomTextField(
        label: 'Confirm Password',
        hintText: 'Re-enter password',
        controller: _confirmPasswordController,
        obscureText: _obscureConfirm,
        focusNode: _confirmPasswordFocusNode,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _confirmPasswordFocusNode.unfocus(),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Confirm password required';
          if (v != _passwordController.text) return 'Passwords do not match';
          return null;
        },
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: _obscureConfirm ? AppColors.textMuted : AppColors.primary,
            size: 20,
          ),
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
      ),
      if (confirmMatch)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
              const SizedBox(width: 6),
              Text('Passwords match',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.success,
                  )),
            ],
          ),
        ),
      if (confirmMismatch)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(Icons.error_rounded, color: AppColors.danger, size: 14),
              const SizedBox(width: 6),
              Text('Passwords don\'t match',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.danger,
                  )),
            ],
          ),
        ),
    ];
  }

  List<Widget> _buildGymDetailsStep() {
    return [
      CustomTextField(
        label: 'Gym Name',
        hintText: 'Your Gym Name',
        controller: _gymNameController,
        focusNode: _gymNameFocusNode,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => _gymTypeFocusNode.requestFocus(),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Gym name required';
          if (v.trim().length < 3) return 'Min 3 characters';
          return null;
        },
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Gym Type',
        hintText: 'e.g. CrossFit, Yoga, Personal Training',
        controller: _gymTypeController,
        focusNode: _gymTypeFocusNode,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => _gymAddressFocusNode.requestFocus(),
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Gym Address',
        hintText: 'Full address',
        controller: _gymAddressController,
        focusNode: _gymAddressFocusNode,
        maxLines: 3,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => _phoneFocusNode.requestFocus(),
        validator: (v) => v == null || v.isEmpty ? 'Address required' : null,
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: IconButton(
            icon: Icon(Icons.near_me_rounded, color: AppColors.primary, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Location access coming soon',
                      style: GoogleFonts.inter(fontSize: 13)),
                  backgroundColor: AppColors.surface,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Phone',
        hintText: '98XXX XXXXX',
        controller: _phoneController,
        focusNode: _phoneFocusNode,
        keyboardType: TextInputType.phone,
        fontFamily: 'JetBrains Mono',
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _phoneFocusNode.unfocus(),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Phone required';
          final clean = v.replaceAll(RegExp(r'\D'), '');
          if (clean.length != 10) return 'Must be exactly 10 digits';
          return null;
        },
      ),
      const SizedBox(height: 4),
      Text('Enter 10-digit mobile number',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textMuted,
          )),
    ];
  }

  List<Widget> _buildVerifyStep() {
    final rows = [
      _ReviewData(Icons.person_rounded, 'Name', _nameController.text,
          _nameFocusNode, 0),
      _ReviewData(Icons.email_rounded, 'Email', _emailController.text,
          _emailFocusNode, 0),
      _ReviewData(Icons.business_rounded, 'Gym', _gymNameController.text,
          _gymNameFocusNode, 1),
      _ReviewData(Icons.phone_rounded, 'Phone', _phoneController.text,
          _phoneFocusNode, 1),
    ];

    return [
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: List.generate(rows.length, (i) {
            final r = rows[i];
            final isHighlighted = _highlightedField == r.label;
            final showTopBorder = i > 0;
            return _buildReviewRow(r, isHighlighted, showTopBorder);
          }),
        ),
      ),
    ];
  }

  Widget _buildReviewRow(_ReviewData data, bool isHighlighted, bool showTopBorder) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        border: showTopBorder
            ? Border(top: BorderSide(color: AppColors.border))
            : null,
      ),
      child: Material(
        color: isHighlighted
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: showTopBorder
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(16)),
        child: InkWell(
          borderRadius: showTopBorder
              ? BorderRadius.zero
              : const BorderRadius.vertical(top: Radius.circular(16)),
          onTap: () {
            setState(() => _highlightedField = data.label);
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted) setState(() => _highlightedField = null);
            });
            _goToStep(data.step, focusNode: data.focusNode);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(data.icon, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.label.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: AppColors.textMuted,
                          )),
                      const SizedBox(height: 2),
                      Text(data.value,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          )),
                    ],
                  ),
                ),
                Icon(Icons.edit_rounded, color: AppColors.textMuted, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return AnimatedBuilder(
      animation: _successScaleAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withValues(alpha: 0.7),
          child: Center(
            child: Transform.scale(
              scale: _successScaleAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6D5DF6), Color(0xFFB15CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6D5DF6).withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          Text('Account Created',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              )),
          const SizedBox(height: 8),
          Text('Setting up your gym dashboard\u2026',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              )),
        ],
      ),
    );
  }
}

class _ReviewData {
  final IconData icon;
  final String label;
  final String value;
  final FocusNode focusNode;
  final int step;

  const _ReviewData(this.icon, this.label, this.value, this.focusNode, this.step);
}
