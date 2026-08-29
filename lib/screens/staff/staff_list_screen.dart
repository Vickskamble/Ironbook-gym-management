import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/staff_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/staff_model.dart';
import '../../core/constants/app_colors.dart';
import 'add_staff_screen.dart';
import 'staff_detail_screen.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/empty_state_widget.dart';

class StaffListScreen extends ConsumerStatefulWidget {
  const StaffListScreen({super.key});

  @override
  ConsumerState<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen> {
  final _searchController = TextEditingController();
  String _roleFilter = 'All';

  final List<String> _roles = ['All', 'trainer', 'staff', 'admin'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gymId = ref.watch(authProvider).gymId;
    if (gymId == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('No gym selected')),
      );
    }

    final staffAsync = ref.watch(staffProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search staff...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                            ref.read(staffProvider.notifier).filterByRole(
                              _roleFilter == 'All' ? '' : _roleFilter,
                            );
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  if (value.isEmpty) {
                    ref.read(staffProvider.notifier).filterByRole(
                      _roleFilter == 'All' ? '' : _roleFilter,
                    );
                  }
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _roles.map((role) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _buildFilterChip(role),
                )).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: staffAsync.when(
                loading: () => const _StaffSkeleton(),
                error: (error, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: EmptyStateWidget(
                      icon: Icons.error_outline,
                      title: 'Failed to load staff',
                      message: error.toString(),
                      actionLabel: 'Retry',
                      onAction: () => ref.invalidate(staffProvider),
                    ),
                  ),
                data: (staff) {
                  final query = _searchController.text.trim().toLowerCase();
                  final filtered = query.isEmpty
                      ? staff
                      : staff.where((s) =>
                          s.name.toLowerCase().contains(query) ||
                          s.phone.contains(query)).toList();

                  if (filtered.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.badge_rounded,
                      title: 'No staff found',
                      message: 'Add your first staff member',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.read(staffProvider.notifier).filterByRole(
                      _roleFilter == 'All' ? '' : _roleFilter,
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => _buildStaffCard(filtered[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 50,
        height: 50,
        margin: const EdgeInsets.only(bottom: 14),
        child: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddStaffScreen()),
          ).then((_) => ref.invalidate(staffProvider)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 6,
          highlightElevation: 8,
          child: const Icon(Icons.add_rounded, size: 22),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String role) {
    final selected = _roleFilter == role;
    return GestureDetector(
      onTap: () {
        setState(() => _roleFilter = role);
        ref.read(staffProvider.notifier).filterByRole(role == 'All' ? '' : role);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(role == 'All' ? 'All' : role[0].toUpperCase() + role.substring(1),
            style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'trainer': return AppColors.primary;
      case 'admin': return AppColors.accent;
      case 'staff': return AppColors.info;
      default: return AppColors.textMuted;
    }
  }

  Widget _buildStaffCard(StaffModel staffMember) {
    final roleColor = _roleColor(staffMember.role);
    final statusColor = staffMember.status == 'Active'
        ? Colors.green : staffMember.status == 'Terminated'
            ? Colors.red : Colors.amber;

    return Dismissible(
      key: ValueKey(staffMember.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Delete Staff', style: TextStyle(color: Colors.white)),
            content: const Text('Are you sure?', style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  ref.read(staffProvider.notifier).terminateStaff(staffMember.id);
                  Navigator.pop(ctx, true);
                },
                child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        ) ?? false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: staffMember.status != 'Active'
              ? const Color(0x1AEF4444)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: staffMember.status != 'Active'
                ? const Color(0x26EF4444)
                : AppColors.border,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => StaffDetailScreen(staffId: staffMember.id)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: staffMember.profilePic != null
                            ? [Colors.grey, Colors.grey]
                            : [roleColor, roleColor.withValues(alpha: 0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: staffMember.profilePic != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(staffMember.profilePic!, fit: BoxFit.cover),
                          )
                        : Center(
                            child: Text(
                              staffMember.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(staffMember.name,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
                            ),
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(staffMember.role,
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: roleColor)),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.phone_rounded, size: 11, color: AppColors.textMuted),
                            const SizedBox(width: 3),
                            Text(staffMember.phone,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StaffSkeleton extends StatelessWidget {
  const _StaffSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: List.generate(8, (_) => const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: _StaffCardSkeleton(),
        )),
      ),
    );
  }
}

class _StaffCardSkeleton extends StatelessWidget {
  const _StaffCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          SkeletonLoader(width: 42, height: 42, borderRadius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 140, height: 14),
                SizedBox(height: 6),
                SkeletonLoader(width: 100, height: 11),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SkeletonLoader(width: 60, height: 18, borderRadius: 9),
              SizedBox(height: 4),
              SkeletonLoader(width: 50, height: 11),
            ],
          ),
        ],
      ),
    );
  }

}
