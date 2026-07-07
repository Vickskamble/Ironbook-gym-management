import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/member_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/member_model.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = 'All';

  static const _avatarGradients = [
    [Color(0xFF6C63FF), Color(0xFF9C5CFF)],
    [Color(0xFF00D68F), Color(0xFF0CBCB0)],
    [Color(0xFFFFB020), Color(0xFFFF7849)],
    [Color(0xFFFF6B9D), Color(0xFFA855F7)],
    [Color(0xFF34D399), Color(0xFF059669)],
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gymId = ref.watch(authProvider).gymId;
    if (gymId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: Text('No gym selected')),
      );
    }

    final membersAsync = ref.watch(memberListProvider(gymId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search members...',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
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
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(memberListProvider(gymId).notifier)
                                .search(gymId, '');
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  ref
                      .read(memberListProvider(gymId).notifier)
                      .search(gymId, value);
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: membersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
                data: (members) {
                  final activeCount = members
                      .where((m) => m.status == 'Active')
                      .length;
                  final expiredCount = members
                      .where((m) => m.status == 'Expired')
                      .length;
                  final pausedCount = members
                      .where((m) => m.status == 'Paused')
                      .length;
                  final expiringCount = members
                      .where(
                        (m) => m.daysUntilExpiry >= 0 && m.daysUntilExpiry <= 7,
                      )
                      .length;

                  final filtered = _statusFilter == 'All'
                      ? members
                      : _statusFilter == 'Expiring'
                      ? members
                            .where(
                              (m) =>
                                  m.daysUntilExpiry >= 0 &&
                                  m.daysUntilExpiry <= 7,
                            )
                            .toList()
                      : members
                            .where(
                              (m) =>
                                  m.status.toLowerCase() ==
                                  _statusFilter.toLowerCase(),
                            )
                            .toList();

                  return Column(
                    children: [
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _buildFilterChip('All (${members.length})', 'All'),
                            const SizedBox(width: 6),
                            _buildFilterChip('Active ($activeCount)', 'Active'),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              'Expired ($expiredCount)',
                              'Expired',
                            ),
                            const SizedBox(width: 6),
                            _buildFilterChip('Paused ($pausedCount)', 'Paused'),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              'Expiring ($expiringCount)',
                              'Expiring',
                            ),
                          ],
                        ),
                      ),
                      if (_statusFilter != 'Expiring') ...[
                        _buildExpiryWarningBar(members),
                      ],
                      const SizedBox(height: 10),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        Icons.people_outline_rounded,
                                        size: 40,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No members found',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) =>
                                    _buildMemberCard(filtered[index], index),
                              ),
                      ),
                    ],
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
          onPressed: () => context.push('/members/add'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 6,
          highlightElevation: 8,
          child: const Icon(Icons.add_rounded, size: 22),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _statusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildExpiryWarningBar(List<MemberModel> members) {
    final expiring = members
        .where((m) => m.daysUntilExpiry >= 0 && m.daysUntilExpiry <= 7)
        .toList();
    if (expiring.isEmpty) return const SizedBox();

    final m = expiring.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x33F59E0B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x33F59E0B)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: Color(0xFFF59E0B),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${m.name} expires in ${m.daysUntilExpiry} day${m.daysUntilExpiry == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/notifications/bulk'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'Notify',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(MemberModel member, int index) {
    final statusColor = member.status == 'Active'
        ? Colors.green
        : member.status == 'Expired'
        ? Colors.red
        : Colors.amber;

    final isExpiring =
        member.daysUntilExpiry >= 0 && member.daysUntilExpiry <= 7;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isExpiring ? const Color(0x08F59E0B) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpiring ? const Color(0x38F59E0B) : AppColors.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/members/${member.id}'),
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
                      colors: _avatarGradients[index % _avatarGradients.length],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      member.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                         member.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text('\u{1F4F1}', style: TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                          Text(
                            member.phone,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                        Container(
                         padding: const EdgeInsets.symmetric(
                           horizontal: 8,
                           vertical: 3,
                         ),
                         decoration: BoxDecoration(
                           color: member.planName != null
                               ? const Color(0x336366F1)
                               : const Color(0x1A475569),
                           borderRadius: BorderRadius.circular(99),
                         ),
                         constraints: BoxConstraints(
                           maxWidth: Responsive.width(context) * 0.25,
                         ),
                         child: Text(
                           member.planName ?? 'No Plan Assigned',
                           style: TextStyle(
                             color: member.planName != null
                                 ? const Color(0xFF818CF8)
                                 : AppColors.textMuted,
                             fontSize: 9,
                             fontWeight: FontWeight.w700,
                           ),
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                         ),
                       ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        member.status,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                    if (member.membershipEnd != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        isExpiring
                            ? '${member.daysUntilExpiry} day${member.daysUntilExpiry == 1 ? '' : 's'} left'
                            : '${member.membershipEnd!.day}/${member.membershipEnd!.month}/${member.membershipEnd!.year}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isExpiring
                              ? const Color(0xFFF59E0B)
                              : AppColors.textMuted,
                          fontWeight: isExpiring
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
