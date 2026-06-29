import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/plan_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class PlanDetailScreen extends ConsumerStatefulWidget {
  final String planId;
  const PlanDetailScreen({super.key, required this.planId});

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final gymId = ref.watch(authProvider.select((s) => s.gymId));
    if (gymId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Plan Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final plansAsync = ref.watch(planProvider(gymId));
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Details'),
        actions: [
          plansAsync.whenOrNull(
            data: (plans) {
              final plan = plans.where((p) => p.id == widget.planId).firstOrNull;
              if (plan == null) return const SizedBox.shrink();
              return PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  await context.push('/plans/edit/${widget.planId}');
                } else if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text(AppStrings.confirmDelete),
                      content: const Text(
                          'Are you sure you want to delete this plan?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text(AppStrings.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(AppStrings.delete,
                              style: TextStyle(color: AppColors.danger)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref
                        .read(planProvider(gymId)
                            .notifier)
                        .deletePlan(widget.planId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Plan deleted successfully')),
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
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: AppColors.danger),
                      SizedBox(width: 8),
                      Text(AppStrings.delete,
                          style: TextStyle(color: AppColors.danger)),
                    ],
                  ),
                ),
              ],
            );
          },
        ) ??
            const SizedBox.shrink(),
        ],
      ),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (plans) {
          final plan = plans.where((p) => p.id == widget.planId).firstOrNull;
          if (plan == null) {
            return const Center(child: Text('Plan not found'));
          }
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
                        plan.name[0].toUpperCase(),
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
                    plan.name,
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
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: plan.isActive
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      plan.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: plan.isActive
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.surface,
                        AppColors.surfaceLight,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        currencyFormat.format(plan.price),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '/ ${plan.durationDays} days',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (plan.description.isNotEmpty) ...[
                  _buildSection('Description', plan.description),
                  const SizedBox(height: 20),
                ],
                if (plan.features.isNotEmpty) ...[
                  _buildSection('What\'s Included', null),
                  const SizedBox(height: 8),
                  ...plan.features.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.check_rounded,
                                  size: 14, color: AppColors.success),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(f,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  )),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 20),
                ],
                _buildInfoRow(
                    Icons.date_range, 'Created', '${plan.createdAt.day}/${plan.createdAt.month}/${plan.createdAt.year}'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        if (value != null) ...[
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
