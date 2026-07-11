import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _init();
    });
  }

  Future<void> _init() async {
    try {
      if (kDebugMode) debugPrint('[Splash] _init started');
      await ref.read(authProvider.notifier).waitForInit()
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
      if (!mounted) return;
      final authState = ref.read(authProvider);

      if (authState.profile != null) {
        if (kDebugMode) debugPrint('[Splash] Profile found, navigating to home');
        _goHome(authState.profile!.role);
        return;
      }

      if (kDebugMode) debugPrint('[Splash] No profile, checking SharedPreferences');
      final SharedPreferences prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 3));
      if (!mounted) return;
      final savedLang = prefs.getString('language');
      if (savedLang == null) {
        context.go('/language');
      } else {
        final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
        context.go(seenOnboarding ? '/login' : '/onboarding');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Splash] _init error: $e');
      if (!mounted) return;
      context.go('/login');
    }
  }

  void _goHome(String role) {
    context.go(role == 'superadmin' ? '/admin' : '/dashboard');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 25,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  size: 55,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                ).createShader(bounds),
                child: const Text(
                  'IronBook',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
