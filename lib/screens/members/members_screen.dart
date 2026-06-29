import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/member_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gymId = ref.watch(authProvider).gymId;
    if (gymId == null) {
      return const Center(child: Text('No gym selected'));
    }

    final membersAsync = ref.watch(memberListProvider(gymId));

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.members)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchMembers,
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.textMuted),
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
          const SizedBox(height: 16),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: ['All', 'Active', 'Expired', 'Paused']
                  .map((status) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(status),
                          selected: _statusFilter == status,
                          onSelected: (selected) {
                            setState(() => _statusFilter = status);
                          },
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: _statusFilter == status
                                ? AppColors.primary
                                : AppColors.textSecondary,
                              fontWeight: _statusFilter == status
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: membersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (members) {
                final filtered = _statusFilter == 'All'
                    ? members
                    : members
                        .where((m) =>
                            m.status.toLowerCase() ==
                            _statusFilter.toLowerCase())
                        .toList();

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
                          child: Icon(Icons.people_outline_rounded,
                              size: 40, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 16),
                        Text(AppStrings.noMembersFound,
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 15)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final member = filtered[index];
                    final statusColor = member.status == 'Active'
                        ? AppColors.success
                        : member.status == 'Expired'
                            ? AppColors.danger
                            : AppColors.warning;

                    return Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () =>
                            context.push('/members/${member.id}'),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.border
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: statusColor
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(
                                      member.name[0].toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.phone_rounded,
                                              size: 11,
                                              color:
                                                  AppColors.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            member.phone,
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (member.planName !=
                                              null) ...[
                                            const SizedBox(width: 12),
                                            Icon(Icons.card_giftcard_rounded,
                                                size: 11,
                                                color: AppColors
                                                    .textMuted),
                                            const SizedBox(width: 4),
                                            Text(
                                              member.planName!,
                                              style: TextStyle(
                                                color: AppColors.primary
                                                    .withValues(
                                                        alpha: 0.7),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    member.status,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/members/add'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
