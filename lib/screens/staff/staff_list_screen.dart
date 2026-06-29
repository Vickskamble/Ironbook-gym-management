import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/staff_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/staff_model.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/glass_container.dart';
import 'add_staff_screen.dart';
import 'staff_detail_screen.dart';

class StaffListScreen extends ConsumerStatefulWidget {
  const StaffListScreen({super.key});

  @override
  ConsumerState<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen> {
  final _searchController = TextEditingController();
  String _roleFilter = 'All';

  final List<String> _roles = ['All', 'Trainer', 'Receptionist', 'Cleaner', 'Manager', 'Other'];

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
        body: Center(child: Text('No gym selected')),
      );
    }

    final staffAsync = ref.watch(staffProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Staff Management')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search staff...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
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
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: _roles.map((role) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(role),
                  selected: _roleFilter == role,
                  onSelected: (selected) {
                    setState(() => _roleFilter = role);
                    ref.read(staffProvider.notifier).filterByRole(
                      role == 'All' ? '' : role,
                    );
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: _roleFilter == role ? AppColors.primary : AppColors.textMuted,
                    fontWeight: _roleFilter == role ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: staffAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (staff) {
                final query = _searchController.text.trim().toLowerCase();
                final filtered = query.isEmpty
                    ? staff
                    : staff.where((s) =>
                        s.name.toLowerCase().contains(query) ||
                        s.phone.contains(query)).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.people_outline_rounded,
                              size: 40, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          query.isNotEmpty ? 'No staff match your search' : 'No staff members yet',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(staffProvider.notifier).filterByRole(
                    _roleFilter == 'All' ? '' : _roleFilter,
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final staffMember = filtered[index];
                      return _StaffCard(staffMember: staffMember);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddStaffScreen()),
        ).then((_) => ref.invalidate(staffProvider)),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _StaffCard extends ConsumerWidget {
  final StaffModel staffMember;

  const _StaffCard({required this.staffMember});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = staffMember.status == 'Active'
        ? AppColors.success
        : staffMember.status == 'Terminated'
            ? AppColors.danger
            : AppColors.warning;
    final roleColor = _roleColor(staffMember.role);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StaffDetailScreen(staffId: staffMember.id),
          ),
        ),
        child: GlassContainer(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: staffMember.profilePic != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(staffMember.profilePic!, fit: BoxFit.cover),
                      )
                    : Center(
                        child: Text(
                          staffMember.name[0].toUpperCase(),
                          style: TextStyle(
                            color: roleColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            staffMember.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            staffMember.role,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: roleColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.phone_rounded, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text(
                          staffMember.phone,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    if (staffMember.salary > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '\u20B9${staffMember.salary.toStringAsFixed(0)}/month',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'trainer':
        return AppColors.primary;
      case 'receptionist':
        return AppColors.info;
      case 'cleaner':
        return AppColors.success;
      case 'manager':
        return AppColors.accent;
      default:
        return AppColors.textMuted;
    }
  }
}
