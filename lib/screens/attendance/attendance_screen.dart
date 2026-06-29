import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymId = ref.watch(authProvider.select((s) => s.gymId));
    if (gymId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Attendance')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final attendanceAsync = ref.watch(todayAttendanceProvider(gymId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: attendanceAsync.when(
        data: (records) => records.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fingerprint, size: 80, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text('No attendance records', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => context.go('/attendance/mark'),
                      icon: const Icon(Icons.add),
                      label: const Text('Mark Attendance'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: records.length,
                itemBuilder: (context, i) {
                  final r = records[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(r.memberName?.isNotEmpty == true ? r.memberName![0].toUpperCase() : '?', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.memberName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                              Text('${r.checkIn.day}/${r.checkIn.month}/${r.checkIn.year}', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: r.checkOut == null ? AppColors.success.withValues(alpha: 0.15) : AppColors.danger.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(r.checkOut == null ? 'Present' : 'Checked Out', style: TextStyle(
                            color: r.checkOut == null ? AppColors.success : AppColors.danger,
                            fontWeight: FontWeight.w600, fontSize: 12,
                          )),
                        ),
                      ],
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.danger))),
      ),
    );
  }
}
