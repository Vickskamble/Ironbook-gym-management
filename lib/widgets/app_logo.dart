import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 1});

  @override
  Widget build(BuildContext context) {
    final iconSize = 72 * size;
    final fontSize = 32 * size;
    final tagFontSize = 14 * size;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize + 24,
          height: iconSize + 24,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF6C63FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20 * size),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.fitness_center,
            size: iconSize,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.primary, Color(0xFF6C63FF)],
          ).createShader(bounds),
          child: Text(
            'IronBook',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'GYM MANAGEMENT',
          style: TextStyle(
            fontSize: tagFontSize,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}
