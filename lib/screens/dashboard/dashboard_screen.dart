import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/stat_card.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/member_model.dart';
import '../../repositories/dashboard_repository.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? get _gymId => ref.read(authProvider).gymId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _loadData() {
    final gid = _gymId;
    if (gid == null) return;
    ref.invalidate(dashboardStatsProvider(gid));
    ref.invalidate(revenueDataProvider(gid));
    ref.invalidate(recentMembersProvider(gid));
    ref.invalidate(expiringMembersProvider(gid));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hello Admin 👋',
              style: TextStyle(fontSize: 20, color: AppColors.textPrimary),
            ),
            Text(
              'Current Gym',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            color: AppColors.textPrimary,
          ),
          IconButton(
            onPressed: () => context.go('/notifications/bulk'),
            icon: Icon(Icons.notifications_none),
            color: AppColors.textPrimary,
          ),
        ],
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
      ),
      body: _buildBody(theme, isLoading, hasError,
          statsAsync, revenueAsync, recentMembersAsync, expiringMembersAsync),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/members/add'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Member'),
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    bool isLoading,
    bool hasError,
    AsyncValue<DashboardStats> statsAsync,
    AsyncValue<List<MonthlyRevenue>> revenueAsync,
    AsyncValue<List<MemberModel>> recentMembersAsync,
    AsyncValue<List<MemberModel>> expiringMembersAsync,
  ) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading dashboard...'),
          ],
        ),
      );
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading dashboard',
              style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    final stats = statsAsync.value!;
    final revenueData = revenueAsync.value!;
    final recentMembers = recentMembersAsync.value!;
    final expiringMembers = expiringMembersAsync.value!;

    return RefreshIndicator(
      onRefresh: () async {
        final gid = _gymId;
        if (gid == null) return;
        ref.invalidate(dashboardStatsProvider(gid));
        ref.invalidate(revenueDataProvider(gid));
        ref.invalidate(recentMembersProvider(gid));
        ref.invalidate(expiringMembersProvider(gid));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(stats),
            const SizedBox(height: 24),
            _buildStatsGrid(stats),
            const SizedBox(height: 24),
            _buildRevenueChartSection(theme, revenueData),
            const SizedBox(height: 24),
            _buildMembersTabs(theme, recentMembers, expiringMembers),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(DashboardStats stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Good Morning!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have ${stats.expiringSoon} members expiring soon',
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(DashboardStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.25,
      children: [
        StatCard(
          title: 'Total Members',
          value: stats.totalMembers.toString(),
          subtitle: 'All time signups',
          icon: Icons.people_alt_rounded,
          iconColor: AppColors.primary,
        ),
        StatCard(
          title: 'This Month Revenue',
          value: formatCurrency(stats.thisMonthRevenue),
          subtitle: 'Payments this month',
          icon: Icons.currency_rupee_rounded,
          iconColor: AppColors.success,
        ),
        StatCard(
          title: 'Active Members',
          value: stats.activeMembers.toString(),
          subtitle: 'Currently active',
          icon: Icons.check_circle_outline,
          iconColor: AppColors.success,
        ),
        StatCard(
          title: 'Expiring Soon',
          value: stats.expiringSoon.toString(),
          subtitle: 'Within 7 days',
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildRevenueChartSection(ThemeData theme, List<MonthlyRevenue> revenueData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerTheme.color ?? AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Revenue Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              Text(
                'Last 6 Months',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (revenueData.isNotEmpty)
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxRevenue(revenueData) + 100,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.primary,
                      getTooltipItem: (group, groupIndex, bar, barIndex) {
                        return BarTooltipItem(
                          '₹${bar.toY.toStringAsFixed(0)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                          if (value.toInt() >= 0 && value.toInt() < months.length) {
                            return Text(
                              months[value.toInt()],
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1000,
                        getTitlesWidget: (value, meta) {
                          if (value % 1000 == 0) {
                            return Text(
                              '₹${(value / 1000).toInt()}K',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1000,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.dividerTheme.color,
                        strokeWidth: 0.5,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: theme.dividerTheme.color ?? AppColors.border,
                      width: 0.5,
                    ),
                  ),
                  barGroups: _buildBarGroups(revenueData),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(List<MonthlyRevenue> revenueData) {
    return List.generate(revenueData.length, (index) {
      final amount = revenueData[index].amount / 1000;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: amount,
            color: AppColors.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            width: 20,
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

  Widget _buildMembersTabs(
    ThemeData theme,
    List<MemberModel> recentMembers,
    List<MemberModel> expiringMembers,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerTheme.color ?? AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: TabBar(
              controller: _tabController,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              indicatorColor: AppColors.primary,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: 'Recent Members'),
                Tab(text: 'Expiring Soon'),
              ],
            ),
          ),
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecentMembersList(recentMembers),
                _buildExpiringMembersList(expiringMembers),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMembersList(List<MemberModel> members) {
    if (members.isEmpty) {
      return _buildEmptyState('No recent members found', Icons.people_alt_outlined);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        return _buildMemberCard(members[index]);
      },
    );
  }

  Widget _buildExpiringMembersList(List<MemberModel> members) {
    if (members.isEmpty) {
      return _buildEmptyState('No members expiring soon', Icons.event_available_outlined);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        return _buildMemberCard(members[index], isExpiring: true);
      },
    );
  }

  Widget _buildMemberCard(MemberModel member, {bool isExpiring = false}) {
    final initials = getMemberInitials(member.name);
    final statusColor = getStatusColor(member.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isExpiring
            ? statusColor.withValues(alpha: 0.1)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpiring
              ? statusColor.withValues(alpha: 0.3)
              : Theme.of(context).dividerTheme.color ?? AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isExpiring
                  ? statusColor.withValues(alpha: 0.2)
                  : AppColors.primary.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      member.phone,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  getStatusLabel(member.status),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              if (isExpiring) ...[
                const SizedBox(height: 4),
                Text(
                  'Expires ${member.membershipEnd?.day}/${member.membershipEnd?.month}/${member.membershipEnd?.year}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.danger,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
