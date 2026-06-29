import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ImportExportScreen extends StatelessWidget {
  const ImportExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Import / Export')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOption(context, 'Export Members', Icons.people_rounded, AppColors.primary, 'Download members list as CSV/Excel'),
          const SizedBox(height: 12),
          _buildOption(context, 'Export Payments', Icons.payments_rounded, AppColors.success, 'Download payment history'),
          const SizedBox(height: 12),
          _buildOption(context, 'Export Attendance', Icons.fingerprint, AppColors.accent, 'Download attendance records'),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),
          _buildOption(context, 'Import Members', Icons.file_upload_rounded, AppColors.warning, 'Upload members from CSV'),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, String title, IconData icon, Color color, String subtitle) {
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
