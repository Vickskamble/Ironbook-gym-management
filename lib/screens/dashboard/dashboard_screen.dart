import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/member_model.dart';
import '../../repositories/dashboard_repository.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? get _gymId => ref.read(authProvider).gymId;

  void _loadData() {
    final gid = _gymId;
    if (gid == null) return;
    ref.invalidate(dashboardStatsProvider(gid));
    ref.invalidate(revenueDataProvider(gid));
    ref.invalidate(recentMembersProvider(gid));
    ref.invalidate(expiringMembersProvider(gid));
  }

  @override
  Widget build(BuildContext context) {
    final gid = _gymId;
    if (gid == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final theme = Theme.of(context);
    final statsAsync = ref.watch(dashboardStatsProvider(gid));
    final revenueAsync = ref.watch(revenueDataProvider(gid));
    final recentMembersAsync = ref.watch(recentMembersProvider(gid));
    final expiringMembersAsync = ref.watch(expiringMembersProvider(gid));
    final unreadCountAsync = ref.watch(unreadCountProvider(gid));

    final isLoading = statsAsync.isLoading ||
        revenueAsync.isLoading ||
        recentMembersAsync.isLoading ||
        expiringMembersAsync.isLoading;

    final hasError = statsAsync.hasError ||
        revenueAsync.hasError ||
        recentMembersAsync.hasError ||
        expiringMembersAsync.hasError;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading dashboard',
                            style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface)),
                        const SizedBox(height: 8),
                        TextButton(onPressed: _loadData, child: const Text('Retry')),
                      ],
                    ),
                  )
                : _buildContent(
                    theme,
                    statsAsync.value!,
                    revenueAsync.value!,
                    recentMembersAsync.value!,
                    expiringMembersAsync.value!,
                    unreadCountAsync.value ?? 0,
                  ),
      ),
    );
  }

  Widget _buildContent(
    ThemeData theme,
    DashboardStats stats,
    List<MonthlyRevenue> revenueData,
    List<MemberModel> recentMembers,
    List<MemberModel> expiringMembers,
    int unreadCount,
  ) {
    final now = DateTime.now();
    final months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
    ];
    final days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
    final gymName = ref.watch(authProvider.select((s) => s.gym?.name ?? 'IronBook Gym'));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x6610B981),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    gymName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh, size: 20),
                  color: AppColors.textSecondary,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 4),
                Stack(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/notifications/bulk'),
                      icon: const Icon(Icons.notifications_none, size: 20),
                      color: AppColors.textSecondary,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hello, Admin 👋',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: expiringMembers.isEmpty
                    ? const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF6D28D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x22FFFFFF),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 30,
                    bottom: -30,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x15FFFFFF),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'ALERT',
                          style: TextStyle(
                            color: Colors.white, fontSize: 10,
                            fontWeight: FontWeight.w700, letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      expiringMembers.isEmpty
                          ? const Text(
                              'All members active',
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                            )
                          : Text(
                              '${expiringMembers.length} Member${expiringMembers.length == 1 ? '' : 's'} Expiring Soon',
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                      const SizedBox(height: 4),
                      expiringMembers.isEmpty
                          ? const SizedBox()
                          : Text(
                              'Their membership is ending within 7 days',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                            ),
                      if (expiringMembers.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () => context.go('/notifications/bulk'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.notifications_active, size: 14, color: Color(0xFF4F46E5)),
                                SizedBox(width: 6),
                                Text(
                                  'Notify Now',
                                  style: TextStyle(
                                    color: Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              children: [
                _buildStatCard(
                  icon: Icons.people_alt_rounded,
                  accentColor: const Color(0xFF6366F1),
                  value: stats.totalMembers.toString(),
                  label: 'Total Members',
                ),
                _buildStatCard(
                  icon: Icons.currency_rupee_rounded,
                  accentColor: const Color(0xFF10B981),
                  value: 'Rs${stats.thisMonthRevenue.toStringAsFixed(0)}',
                  label: 'This Month',
                ),
                _buildStatCard(
                  icon: Icons.check_circle_outline,
                  accentColor: const Color(0xFF10B981),
                  value: stats.activeMembers.toString(),
                  label: 'Active',
                ),
                _buildStatCard(
                  icon: Icons.warning_amber_rounded,
                  accentColor: const Color(0xFFF59E0B),
                  value: stats.expiringSoon.toString(),
                  label: 'Expiring Soon',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildRevenueCard(theme, revenueData),
          const SizedBox(height: 20),
          _buildRecentActivity(theme, recentMembers),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => context.go('/members/add'),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Add New Member',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color accentColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 20, color: accentColor),
              ),
              const Spacer(),
              Container(
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withValues(alpha: 0.3)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26, fontWeight: FontWeight.w900,
              letterSpacing: -1, color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(ThemeData theme, List<MonthlyRevenue> revenueData) {
    final totalRevenue = revenueData.fold<num>(0, (sum, r) => sum + r.amount);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Revenue Overview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'Last 6 Months',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Rs${totalRevenue.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 16),
          if (revenueData.isNotEmpty)
            SizedBox(
              height: 72,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxRevenue(revenueData),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                          if (value.toInt() >= 0 && value.toInt() < labels.length) {
                            return Text(
                              labels[value.toInt()],
                              style: const TextStyle(fontSize: 8, color: AppColors.textMuted),
                            );
                          }
                          return const SizedBox();
                        },
                        reservedSize: 14,
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: _buildBarGroups(revenueData),
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text(
                'Revenue from member subscriptions',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Spacer(),
              Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.textMuted),
            ],
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(List<MonthlyRevenue> revenueData) {
    final maxY = _getMaxRevenue(revenueData);
    final minBarY = maxY > 0 ? maxY * 0.02 : 1.0;

    return List.generate(revenueData.length, (index) {
      final amount = revenueData[index].amount.toDouble();
      final toY = amount > 0 ? amount : minBarY;
      final isCurrentMonth = index == revenueData.length - 1;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: toY,
            color: isCurrentMonth ? const Color(0xFF10B981) : const Color(0xFF6366F1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(3),
              topRight: Radius.circular(3),
            ),
            width: 8,
            fromY: 0,
          ),
        ],
      );
    });
  }

  double _getMaxRevenue(List<MonthlyRevenue> revenueData) {
    if (revenueData.isEmpty) return 1000;
    final max = revenueData.fold<num>(
      0,
      (max, item) => item.amount > max ? item.amount : max,
    );
    return max.toDouble();
  }

  Widget _buildRecentActivity(ThemeData theme, List<MemberModel> recentMembers) {
    if (recentMembers.isEmpty) return const SizedBox();

    final displayMembers = recentMembers.take(2).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              GestureDetector(
                onTap: () => context.go('/members'),
                child: const Text(
                  'View All',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6366F1), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          ...displayMembers.map((member) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: member.status == 'Active'
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    member.name,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  _timeAgo(member.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 7}w ago';
  }
}
