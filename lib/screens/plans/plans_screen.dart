import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/stat_card.dart' hide CustomTextField;
import '../../widgets/custom_text_field.dart';
import '../../providers/plan_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/plan_model.dart';

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  final _searchController = TextEditingController();
  final String _selectedFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gymId = ref.watch(authProvider.select((s) => s.gymId));
    if (gymId == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Plans Management'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final planState = ref.watch(planProvider(gymId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Plans Management'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
      ),
      body: planState.when(
        data: (plans) {
          // Filter plans based on search and filter
          final filteredPlans = _filterPlans(plans);

          return Column(
            children: [
              // Header with stats
              _buildHeaderSection(theme, filteredPlans.length),
              const SizedBox(height: 16),

              // Search and Filter Bar
              _buildSearchAndFilterBar(),
              const SizedBox(height: 16),

              // Plans Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filteredPlans.length,
                    itemBuilder: (context, index) {
                      final plan = filteredPlans[index];
                      return _buildPlanCard(plan);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 80), // Space for FAB
            ],
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading plans...'),
            ],
          ),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading plans'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.read(planProvider(gymId).notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.go('/plans/add');
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Plan'),
      ),
    );
  }

  // Filter plans based on search and filter
  List<PlanModel> _filterPlans(List<PlanModel> plans) {
    final searchText = _searchController.text.toLowerCase();
    final List<PlanModel> filtered = plans.where((plan) {
      final matchesSearch = plan.name.toLowerCase().contains(searchText) ||
          plan.description.toLowerCase().contains(searchText);

      if (_selectedFilter == 'All') return matchesSearch;
      if (_selectedFilter == 'Active') return matchesSearch && plan.isActive;
      if (_selectedFilter == 'Inactive') return matchesSearch && !plan.isActive;

      return matchesSearch;
    }).toList();

    return filtered;
  }

  // Build header section with statistics
  Widget _buildHeaderSection(ThemeData theme, int planCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerTheme.color ?? AppColors.border, 
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(child: StatCard(
            title: 'Total Plans',
            value: planCount.toString(),
            icon: Icons.description_rounded,
            iconColor: AppColors.primary,
          )),
          const SizedBox(width: 12),
          Expanded(child: StatCard(
            title: 'Active',
            value: _getActiveCount(planCount).toString(),
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
          )),
          const SizedBox(width: 12),
          Expanded(child: StatCard(
            title: 'Inactive',
            value: (planCount - _getActiveCount(planCount)).toString(),
            icon: Icons.highlight_off_outlined,
            iconColor: Colors.grey,
          )),
        ],
      ),
    );
  }

  // Build search and filter bar
  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Search Field
          CustomTextField(
            label: 'Search Plans',
            hintText: 'Search by name or description',
            controller: _searchController,
            suffixIcon: const Icon(Icons.search_rounded),
          
          ),
          const SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'All', Icons.list_alt),
                const SizedBox(width: 8),
                _buildFilterChip('Active', 'Active', Icons.check_circle),
                const SizedBox(width: 8),
                _buildFilterChip('Inactive', 'Inactive', Icons.highlight_off),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build filter chip
  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.15)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : Theme.of(context).dividerTheme.color ?? AppColors.border, 
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Get active count
  int _getActiveCount(int total) {
    // TODO: Calculate from actual plan list
    return (total * 0.7).round(); // Rough estimate for demo
  }

  // Build plan card
  Widget _buildPlanCard(PlanModel plan) {
    final statusColor = plan.isActive ? Colors.green : Colors.grey;
    final statusLabel = plan.isActive ? 'Active' : 'Inactive';
    final cardColors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
    ];
    final colorIdx = plan.id.hashCode.abs() % cardColors.length;
    final accentColor = plan.isActive ? cardColors[colorIdx] : Colors.grey;

    return GestureDetector(
      onTap: () => context.go('/plans/edit/${plan.id}'),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor.withValues(alpha: 0.15),
              accentColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withValues(alpha: 0.6)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.fitness_center_rounded, size: 14, color: accentColor),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            plan.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      plan.formattedPrice,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          plan.durationLabel,
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}