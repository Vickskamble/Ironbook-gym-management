import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildReportCard(context, 'Revenue Report', Icons.trending_up_rounded, AppColors.success, 'Monthly, yearly revenue breakdown'),
          const SizedBox(height: 12),
          _buildReportCard(context, 'Member Report', Icons.people_rounded, AppColors.primary, 'New, active, expired members'),
          const SizedBox(height: 12),
          _buildReportCard(context, 'Attendance Report', Icons.fingerprint, AppColors.accent, 'Daily, monthly attendance summary'),
          const SizedBox(height: 12),
          _buildReportCard(context, 'Expense Report', Icons.receipt_long_rounded, AppColors.warning, 'Category-wise expense analysis'),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, String title, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        ],
      ),
    );
  }
}
