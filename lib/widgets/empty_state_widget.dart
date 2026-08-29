import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/responsive.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? message;
  final String? lottieAsset;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.message,
    this.lottieAsset,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final size = Responsive.width(context);
    final lottieSize = size > 600 ? 200.0 : 150.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lottieAsset != null)
              SizedBox(
                width: lottieSize,
                height: lottieSize,
                child: Lottie.asset(
                  lottieAsset!,
                  fit: BoxFit.contain,
                ),
              )
            else if (icon != null)
              Container(
                width: lottieSize,
                height: lottieSize,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: lottieSize * 0.5, color: AppColors.textMuted),
              ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 18),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 14),
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
