import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/admin_provider.dart';
import '../../models/gym_model.dart';
import '../../models/member_model.dart';
import '../../core/constants/app_colors.dart';
import '../../repositories/member_repository.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/stat_card.dart' hide PrimaryButton;
import '../../widgets/skeleton_loader.dart';

final _gymDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, gymId) {
  return ref.read(adminRepositoryProvider).getGymDetail(gymId);
});

final _recentMembersProvider =
    FutureProvider.family<List<MemberModel>, String>((ref, gymId) {
  final repo = MemberRepository(Supabase.instance.client);
  return repo.getMembers(gymId, limit: 5);
});

class GymDetailScreen extends ConsumerStatefulWidget {
  final String gymId;
  const GymDetailScreen({super.key, required this.gymId});

  @override
  ConsumerState<GymDetailScreen> createState() => _GymDetailScreenState();
}

class _GymDetailScreenState extends ConsumerState<GymDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(_gymDetailProvider(widget.gymId));
    final membersAsync = ref.watch(_recentMembersProvider(widget.gymId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(_gymDetailProvider(widget.gymId));
              ref.invalidate(_recentMembersProvider(widget.gymId));
            },
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => _buildLoadingSkeleton(),
        error: (err, _) => _buildErrorState(err.toString()),
        data: (detail) {
          final gymJson = detail['gym'] as Map<String, dynamic>;
          final gym = GymModel.fromJson(gymJson);
          final totalMembers = detail['totalMembers'] as int;
          final activeMembers = detail['activeMembers'] as int;
          final totalStaff = detail['totalStaff'] as int;
          final totalRevenue = detail['totalRevenue'] as num;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGymInfoHeader(gym),
                const SizedBox(height: 24),
                _buildStatsRow(
                    totalMembers, activeMembers, totalStaff, totalRevenue),
                const SizedBox(height: 24),
                _buildSubscriptionCard(gym),
                const SizedBox(height: 24),
                _buildOwnerInfo(gym),
                const SizedBox(height: 24),
                _buildQuickActions(gym),
                const SizedBox(height: 24),
                _buildMembersTable(membersAsync),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonCard(),
          const SizedBox(height: 24),
          Row(
            children: const [
              Expanded(child: SkeletonCard()),
              SizedBox(width: 12),
              Expanded(child: SkeletonCard()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: SkeletonCard()),
              SizedBox(width: 12),
              Expanded(child: SkeletonCard()),
            ],
          ),
          const SizedBox(height: 24),
          const SkeletonCard(),
          const SizedBox(height: 24),
          const SkeletonCard(),
          const SizedBox(height: 24),
          const SkeletonCard(),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: AppColors.dangerLight),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Retry',
              onPressed: () {
                ref.invalidate(_gymDetailProvider(widget.gymId));
                ref.invalidate(_recentMembersProvider(widget.gymId));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGymInfoHeader(GymModel gym) {
    return GlassContainer(
      backgroundColor: AppColors.surface.withValues(alpha: 0.6),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: gym.logoUrl != null && gym.logoUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      gym.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildLogoPlaceholder(gym),
                    ),
                  )
                : _buildLogoPlaceholder(gym),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gym.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  gym.address,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone_rounded,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      gym.phone,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (gym.website != null && gym.website!.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.language_rounded,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        gym.website!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoPlaceholder(GymModel gym) {
    return Center(
      child: Text(
        gym.name.isNotEmpty ? gym.name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildStatsRow(
      int totalMembers, int activeMembers, int totalStaff, num totalRevenue) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Total Members',
                value: '$totalMembers',
                icon: Icons.people_rounded,
                iconColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Active Members',
                value: '$activeMembers',
                icon: Icons.person_rounded,
                iconColor: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Staff Count',
                value: '$totalStaff',
                icon: Icons.badge_rounded,
                iconColor: AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Revenue',
                value: '\u{20B9}${totalRevenue.toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard(GymModel gym) {
    final planLabel = gym.subscription[0].toUpperCase() +
        gym.subscription.substring(1);
    final isExpired = gym.subscriptionExpiresAt != null &&
        DateTime.now().isAfter(gym.subscriptionExpiresAt!);
    final isActive = gym.isActive && !isExpired;
    final daysRemaining = gym.subscriptionExpiresAt != null
        ? gym.subscriptionExpiresAt!.difference(DateTime.now()).inDays
        : -1;

    return GlassContainer(
      backgroundColor: AppColors.surface.withValues(alpha: 0.6),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Subscription',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isActive ? AppColors.active : AppColors.expired)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'Active' : 'Expired',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color:
                        isActive ? AppColors.active : AppColors.expired,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  planLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              if (daysRemaining >= 0)
                Text(
                  '$daysRemaining days remaining',
                  style: TextStyle(
                    fontSize: 13,
                    color: daysRemaining <= 7
                        ? AppColors.warning
                        : AppColors.textSecondary,
                    fontWeight: daysRemaining <= 7
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
            ],
          ),
          if (gym.subscriptionExpiresAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Expires: ${_formatDate(gym.subscriptionExpiresAt!)}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOwnerInfo(GymModel gym) {
    return GlassContainer(
      backgroundColor: AppColors.surface.withValues(alpha: 0.6),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Owner Information',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildOwnerRow(Icons.person_rounded, 'Name', 'Owner #${gym.ownerId.substring(0, 8)}'),
          const Divider(
            color: AppColors.border,
            height: 1,
          ),
          _buildOwnerRow(Icons.phone_rounded, 'Phone', '---'),
          const Divider(
            color: AppColors.border,
            height: 1,
          ),
          _buildOwnerRow(Icons.email_rounded, 'Email', '---'),
          const SizedBox(height: 8),
          Text(
            'Fetch owner details via Supabase profiles table using ownerId.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                Icon(icon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(GymModel gym) {
    return GlassContainer(
      backgroundColor: AppColors.surface.withValues(alpha: 0.6),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: 'Edit Subscription',
              onPressed: () => _showEditSubscriptionDialog(gym),
              backgroundColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: 'Refresh Stats',
              onPressed: () {
                ref.invalidate(_gymDetailProvider(widget.gymId));
                ref.invalidate(_recentMembersProvider(widget.gymId));
              },
              backgroundColor: AppColors.surfaceLight,
              textColor: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSubscriptionDialog(GymModel gym) {
    String selectedPlan = gym.subscription;
    DateTime selectedDate = gym.subscriptionExpiresAt ??
        DateTime.now().add(const Duration(days: 365));
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Text(
            'Edit Subscription',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Plan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedPlan,
                  dropdownColor: AppColors.surfaceLight,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                  items: const [
                    DropdownMenuItem(
                        value: 'free', child: Text('Free')),
                    DropdownMenuItem(
                        value: 'starter', child: Text('Starter')),
                    DropdownMenuItem(
                        value: 'pro', child: Text('Pro')),
                    DropdownMenuItem(
                        value: 'enterprise',
                        child: Text('Enterprise')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedPlan = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Expiry Date',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 3650)),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.primary,
                            onPrimary: Colors.white,
                            surface: AppColors.surface,
                            onSurface: AppColors.textPrimary,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(selectedDate),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                        const Icon(Icons.calendar_month_rounded,
                            color: AppColors.textSecondary, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      try {
                        await ref
                            .read(adminRepositoryProvider)
                            .updateSubscription(
                                widget.gymId, selectedPlan, selectedDate);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        ref.invalidate(
                            _gymDetailProvider(widget.gymId));
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Subscription updated successfully'),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(color: AppColors.primary),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTable(AsyncValue<List<MemberModel>> membersAsync) {
    return GlassContainer(
      backgroundColor: AppColors.surface.withValues(alpha: 0.6),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Members',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          membersAsync.when(
            loading: () => Column(
              children: List.generate(
                3,
                (_) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SkeletonLoader(height: 20),
                ),
              ),
            ),
            error: (err, _) => Text(
              'Failed to load members',
              style: const TextStyle(color: AppColors.dangerLight),
            ),
            data: (members) {
              if (members.isEmpty) {
                return const Text(
                  'No members found',
                  style: TextStyle(color: AppColors.textSecondary),
                );
              }
              return Column(
                children: [
                  _buildMemberTableHeader(),
                  const Divider(color: AppColors.border, height: 1),
                  ...members.map(_buildMemberRow),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Name',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Phone',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Plan',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Status',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberRow(MemberModel member) {
    final statusColor = member.status == 'Active'
        ? AppColors.active
        : member.status == 'Expired'
            ? AppColors.expired
            : member.status == 'Paused'
                ? AppColors.paused
                : AppColors.deleted;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              member.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              member.phone,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              member.planName ?? '---',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                member.status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
