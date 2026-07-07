import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/staff_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/staff_model.dart';
import '../../core/constants/app_colors.dart';
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
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(Icons.people_outline_rounded, size: 36, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            query.isNotEmpty ? 'No staff match your search' : 'No staff members yet',
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
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
        child: Text(role,
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
      case 'receptionist': return AppColors.info;
      case 'cleaner': return AppColors.success;
      case 'manager': return AppColors.accent;
      default: return AppColors.textMuted;
    }
  }

  Widget _buildStaffCard(StaffModel staffMember) {
    final roleColor = _roleColor(staffMember.role);
    final statusColor = staffMember.status == 'Active'
        ? Colors.green : staffMember.status == 'Terminated'
            ? Colors.red : Colors.amber;

    return Container(
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
    );
  }
}
