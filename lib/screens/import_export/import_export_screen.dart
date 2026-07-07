import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/import_export_repository.dart';

class ImportExportScreen extends ConsumerWidget {
  const ImportExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymId = ref.watch(authProvider.select((s) => s.gymId));
    if (gymId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _buildHeader(),
            _buildOptionCard(
              context,
              icon: Icons.file_download_rounded,
              color: const Color(0xFF6366F1),
              title: 'Export Members',
              subtitle: 'Download members list as CSV',
              onTap: () async {
                try {
                  final repo = ImportExportRepository(Supabase.instance.client);
                  final path = await repo.exportMembersToCSV(gymId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Exported: $path'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
                    );
                  }
                }
              },
            ),
            _buildOptionCard(
              context,
              icon: Icons.payments_rounded,
              color: const Color(0xFF10B981),
              title: 'Export Payments',
              subtitle: 'Download payment history as Excel',
              onTap: () async {
                try {
                  final repo = ImportExportRepository(Supabase.instance.client);
                  final path = await repo.generateRevenueReportExcel(gymId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Exported: $path'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
                    );
                  }
                }
              },
            ),
            _buildOptionCard(
              context,
              icon: Icons.fingerprint,
              color: const Color(0xFF8B5CF6),
              title: 'Export Attendance',
              subtitle: 'Download attendance records',
              onTap: () => _exportAttendance(context, ref, gymId),
            ),
            _buildOptionCard(
              context,
              icon: Icons.file_upload_rounded,
              color: const Color(0xFFF59E0B),
              title: 'Import Members',
              subtitle: 'Upload members from CSV',
              onTap: () async {
                try {
                  final result = await FilePicker.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['csv'],
                  );
                  if (result == null || result.files.isEmpty) return;
                  final filePath = result.files.first.path;
                  if (filePath == null) return;
                  if (!File(filePath).existsSync()) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selected file not found'), backgroundColor: AppColors.danger),
                      );
                    }
                    return;
                  }
                  final adminId = Supabase.instance.client.auth.currentUser?.id;
                  if (adminId == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User not authenticated'), backgroundColor: AppColors.danger),
                      );
                    }
                    return;
                  }
                  final repo = ImportExportRepository(Supabase.instance.client);
                  final importResult = await repo.importMembersFromCSV(
                    gymId: gymId,
                    filePath: filePath,
                    adminId: adminId,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Imported: ${importResult['inserted']} members, '
                          'Skipped: ${importResult['skipped']}',
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    if ((importResult['errors'] as List).isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Errors: ${(importResult['errors'] as List).join(', ')}'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Import error: $e'), backgroundColor: AppColors.danger),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x336366F1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x266366F1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF818CF8)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Files are saved to your device. Use a file manager to access them.',
                      style: TextStyle(color: const Color(0xFF818CF8), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Row(
        children: [
          Container(
            width: 3, height: 16,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          const Text('IMPORT / EXPORT',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _exportAttendance(
    BuildContext context, WidgetRef ref, String gymId) async {
  final range = await _showDateRangePicker(context);
  if (range == null) return;
  if (!context.mounted) return;

  try {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating attendance report...'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );

    final repo = ImportExportRepository(Supabase.instance.client);
    final pdfBytes = await repo.generateAttendanceReportPDF(
      gymId,
      fromDate: range.start,
      toDate: range.end,
    );

    if (!context.mounted) return;

    await Printing.layoutPdf(
      onLayout: (_) => pdfBytes,
      name: 'attendance_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    if (!context.mounted) return;

    _showExportDialog(context, pdfBytes);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

Future<DateTimeRange?> _showDateRangePicker(BuildContext context) {
  final now = DateTime.now();
  return showDialog<DateTimeRange>(
    context: context,
    builder: (ctx) {
      DateTimeRange? selected;
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            title: const Text('Select Date Range',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRangeOption(
                  context,
                  'Last 7 Days',
                  DateTimeRange(
                    start: now.subtract(const Duration(days: 7)),
                    end: now,
                  ),
                  selected,
                  () => setDialogState(() => selected = DateTimeRange(
                    start: now.subtract(const Duration(days: 7)),
                    end: now,
                  )),
                ),
                const SizedBox(height: 8),
                _buildRangeOption(
                  context,
                  'Last 30 Days',
                  DateTimeRange(
                    start: now.subtract(const Duration(days: 30)),
                    end: now,
                  ),
                  selected,
                  () => setDialogState(() => selected = DateTimeRange(
                    start: now.subtract(const Duration(days: 30)),
                    end: now,
                  )),
                ),
                const SizedBox(height: 8),
                _buildRangeOption(
                  context,
                  'Custom Range',
                  null,
                  selected,
                  () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: now,
                      initialDateRange: selected,
                      builder: (ctx, child) {
                        return Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.primary,
                              surface: AppColors.surface,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setDialogState(() => selected = picked);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: selected != null
                    ? () => Navigator.pop(ctx, selected)
                    : null,
                child: const Text('Export', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _buildRangeOption(
  BuildContext context,
  String label,
  DateTimeRange? range,
  DateTimeRange? selected,
  VoidCallback onTap,
) {
  final isSelected = selected != null && range != null &&
      selected.start == range.start && selected.end == range.end;
  return SizedBox(
    width: double.infinity,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    )),
              ),
              if (range != null)
                Text(
                  '${range.start.day}/${range.start.month} - ${range.end.day}/${range.end.month}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _showExportDialog(BuildContext context, Uint8List pdfBytes) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      title: const Text('Report Generated',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      content: const Text('Attendance report has been generated successfully.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            Printing.sharePdf(
              bytes: pdfBytes,
              filename: 'attendance_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
            );
          },
          child: const Text('Share', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            Printing.layoutPdf(
              onLayout: (_) => pdfBytes,
              name: 'attendance_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
            );
          },
          child: const Text('Print Preview', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}
