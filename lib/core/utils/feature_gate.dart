import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/subscription_service.dart';

enum AppFeature {
  staff,
  inventory,
  expenses,
  notifications,
  importExport,
  qrAttendance,
  bulkNotifications;

  static const _routeMap = {
    '/staff': AppFeature.staff,
    '/inventory': AppFeature.inventory,
    '/expenses': AppFeature.expenses,
    '/import-export': AppFeature.importExport,
    '/notifications': AppFeature.notifications,
    '/attendance/mark': AppFeature.qrAttendance,
    '/notifications/bulk': AppFeature.bulkNotifications,
  };

  static AppFeature? fromRoute(String route) {
    for (final e in _routeMap.entries) {
      if (route == e.key || route.startsWith('${e.key}/')) return e.value;
    }
    return null;
  }

  bool isAvailable(String plan) => plan != 'free';

  String get label {
    switch (this) {
      case AppFeature.staff: return 'Staff Management';
      case AppFeature.inventory: return 'Inventory';
      case AppFeature.expenses: return 'Expenses';
      case AppFeature.notifications: return 'Notifications';
      case AppFeature.importExport: return 'Import/Export';
      case AppFeature.qrAttendance: return 'QR Attendance';
      case AppFeature.bulkNotifications: return 'Bulk Notifications';
    }
  }
}

void showUpgradeDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      title: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 40),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Upgrade Required',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This feature is available on Pro plan and above. Upgrade to unlock.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            Navigator.of(context).pushNamed('subscription');
          },
          child: const Text('View Plans', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}