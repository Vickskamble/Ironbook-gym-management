import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

OverlayEntry _buildToast(BuildContext context, String message, {IconData icon = Icons.check_circle, Color color = AppColors.success}) {
  return OverlayEntry(
    builder: (ctx) => IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (ctx, value, child) => Opacity(
              opacity: value,
              child: Transform.scale(
                scale: value,
                child: child,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void showCenterToast(BuildContext context, String message, {IconData icon = Icons.check_circle, Color color = AppColors.success}) {
  final nav = Navigator.of(context, rootNavigator: true);
  final overlay = nav.overlay;
  if (overlay == null) return;
  final entry = _buildToast(context, message, icon: icon, color: color);
  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 2), () => entry.remove());
}