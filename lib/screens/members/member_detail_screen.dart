import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/member_provider.dart';
import '../../providers/plan_provider.dart';
import '../../models/member_model.dart';
import '../../models/plan_model.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class MemberDetailScreen extends ConsumerStatefulWidget {
  final String memberId;
  const MemberDetailScreen({super.key, required this.memberId});

  @override
  ConsumerState<MemberDetailScreen> createState() =>
      _MemberDetailScreenState();
}

class _MemberDetailScreenState extends ConsumerState<MemberDetailScreen> {
  Future<void> _updateStatus(String status) async {
    final gymId = ref.read(authProvider).gymId;
    if (gymId == null) return;
    await ref
        .read(memberListProvider(gymId).notifier)
        .updateMember(widget.memberId, {'status': status});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gymId = ref.watch(authProvider.select((s) => s.gymId));
    if (gymId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.memberDetails)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final memberAsync = ref.watch(memberDetailProvider((gymId: gymId, memberId: widget.memberId)));

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.memberDetails),
        actions: [
          memberAsync.whenOrNull(
            data: (member) => PopupMenuButton<String>(
              onSelected: (value) async {
                final route = '/members/edit/${widget.memberId}';
                if (value == 'edit') {
                  await context.push(route);
                } else if (value == 'pause') {
                  await _updateStatus('Paused');
                } else if (value == 'activate') {
                  await _updateStatus('Active');
                } else if (value == 'deactivate') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Deactivate Member'),
                      content: const Text(
                          'Are you sure you want to deactivate this member?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(AppStrings.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Deactivate',
                              style: TextStyle(color: AppColors.danger)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _updateStatus('Expired');
                  }
                } else if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(AppStrings.confirmDelete),
                      content: Text(AppStrings.deleteMemberWarning),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(AppStrings.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(AppStrings.delete,
                              style: TextStyle(color: AppColors.danger)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final gymId = ref.read(authProvider).gymId;
                    if (gymId != null) {
                      await ref
                          .read(memberListProvider(gymId).notifier)
                          .deleteMember(widget.memberId);
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(AppStrings.memberDeleted)),
                      );
                      context.pop();
                    }
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                if (member.status != 'Paused')
                  const PopupMenuItem(
                    value: 'pause',
                    child: Row(
                      children: [
                        Icon(Icons.pause_rounded, color: AppColors.warning),
                        SizedBox(width: 8),
                        Text('Pause',
                            style: TextStyle(color: AppColors.warning)),
                      ],
                    ),
                  ),
                if (member.status == 'Paused')
                  const PopupMenuItem(
                    value: 'activate',
                    child: Row(
                      children: [
                        Icon(Icons.play_arrow_rounded,
                            color: AppColors.success),
                        SizedBox(width: 8),
                        Text('Activate',
                            style: TextStyle(color: AppColors.success)),
                      ],
                    ),
                  ),
                if (member.status != 'Expired')
                  const PopupMenuItem(
                    value: 'deactivate',
                    child: Row(
                      children: [
                        Icon(Icons.block_rounded, color: AppColors.danger),
                        SizedBox(width: 8),
                        Text('Deactivate',
                            style: TextStyle(color: AppColors.danger)),
                      ],
                    ),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever_rounded,
                          color: AppColors.danger),
                      SizedBox(width: 8),
                      Text(AppStrings.delete,
                          style: TextStyle(color: AppColors.danger)),
                    ],
                  ),
                ),
              ],
            ),
          ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: memberAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (member) {
          final statusColor = member.status == 'Active'
              ? AppColors.success
              : member.status == 'Expired'
                  ? AppColors.danger
                  : AppColors.warning;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          AppColors.primary.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        member.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    member.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      member.status,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildQrCode(member),
                const SizedBox(height: 24),
                _buildInfoCard(member),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQrCode(MemberModel member) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          QrImageView(
            data: member.id,
            version: QrVersions.auto,
            size: 160,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Scan to mark attendance',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(MemberModel member) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.phone_rounded, 'Phone', member.phone),
          if (member.email != null)
            _buildInfoRow(Icons.email_rounded, 'Email', member.email!),
          _buildInfoRow(Icons.calendar_today_rounded, 'Join Date',
               '${member.joinDate.day}/${member.joinDate.month}/${member.joinDate.year}'),
          GestureDetector(
            onTap: () => _showPlanPicker(member),
            child: _buildInfoRow(
              Icons.card_giftcard_rounded, 'Plan', member.planName ?? 'No Plan',
              trailing: const Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
            ),
          ),
          if (member.age != null)
            _buildInfoRow(Icons.person_rounded, 'Age', '${member.age}'),
          if (member.address != null)
            _buildInfoRow(
                Icons.location_on_rounded, 'Address', member.address!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Future<void> _showPlanPicker(MemberModel member) async {
    final gymId = ref.read(authProvider).gymId;
    if (gymId == null) return;
    final plans = await ref.read(planProvider(gymId).future);
    final activePlans = plans.where((p) => p.isActive).toList();
    if (!mounted) return;
    final result = await showModalBottomSheet<PlanModel>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Plan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            ...activePlans.map((plan) => ListTile(
              leading: Icon(Icons.card_giftcard_rounded,
                color: member.planId == plan.id ? AppColors.primary : AppColors.textMuted),
              title: Text(plan.name, style: const TextStyle(color: AppColors.textPrimary)),
              subtitle: Text(plan.formattedPrice, style: const TextStyle(color: AppColors.textSecondary)),
              trailing: member.planId == plan.id
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.pop(ctx, plan),
            )),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      final gId = ref.read(authProvider).gymId!;
      await ref.read(memberListProvider(gId).notifier).updateMember(widget.memberId, {
        'plan_id': result.id,
        'plan_name': result.name,
      });
      ref.invalidate(memberDetailProvider((gymId: gId, memberId: widget.memberId)));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plan updated to ${result.name}'), backgroundColor: AppColors.success),
        );
      }
    }
  }
}
