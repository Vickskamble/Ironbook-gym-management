import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/staff_provider.dart';
import '../../models/staff_model.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/primary_button.dart';

class StaffDetailScreen extends ConsumerStatefulWidget {
  final String staffId;

  const StaffDetailScreen({super.key, required this.staffId});

  @override
  ConsumerState<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends ConsumerState<StaffDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffListProvider);

    return staffAsync.when(
      data: (staffList) {
        final staffMember = staffList.where((s) => s.id == widget.staffId).firstOrNull;
        if (staffMember == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Staff Details')),
            body: const Center(child: Text('Staff member not found')),
          );
        }
        return _buildDetailScreen(staffMember);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Staff Details')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Staff Details')),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'Trainer': return AppColors.primary;
      case 'Manager': return AppColors.success;
      case 'Receptionist': return AppColors.info;
      case 'Cleaner': return AppColors.warning;
      default: return AppColors.textSecondary;
    }
  }

  Widget _buildDetailScreen(StaffModel staffMember) {
    final statusColor = staffMember.status == 'Active'
        ? AppColors.success
        : staffMember.status == 'Terminated'
            ? AppColors.danger
            : AppColors.warning;
    final roleColor = _roleColor(staffMember.role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Details'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit coming soon')),
                );
              } else if (value == 'terminate') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text('Terminate Staff?'),
                    content: Text('Are you sure you want to terminate ${staffMember.name}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                        child: const Text('Terminate'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await ref.read(staffListProvider.notifier).terminateStaff(staffMember.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Staff terminated')),
                    );
                    Navigator.pop(context);
                  }
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'terminate', child: Text('Terminate')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GlassContainer(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: roleColor.withValues(alpha: 0.2),
                      child: Text(
                        staffMember.name.isNotEmpty
                            ? staffMember.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: roleColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(staffMember.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(staffMember.role, style: TextStyle(color: roleColor, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(staffMember.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GlassContainer(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Contact Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const Divider(color: AppColors.border),
                    _infoRow(Icons.phone, 'Phone', staffMember.phone),
                    if (staffMember.email != null) _infoRow(Icons.email, 'Email', staffMember.email!),
                    if (staffMember.shift != null) _infoRow(Icons.schedule, 'Shift', staffMember.shift!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GlassContainer(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Employment Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const Divider(color: AppColors.border),
                    _infoRow(Icons.work, 'Role', staffMember.role),
                    _infoRow(Icons.currency_rupee, 'Salary', '₹${staffMember.salary.toStringAsFixed(0)}/month'),
                    _infoRow(Icons.calendar_today, 'Joined', '${staffMember.joinDate.day}/${staffMember.joinDate.month}/${staffMember.joinDate.year}'),
                    if (staffMember.specialization != null) _infoRow(Icons.star, 'Specialization', staffMember.specialization!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: 'Call',
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Calling...')),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                    text: 'Message',
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Messaging...')),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Expanded(child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
