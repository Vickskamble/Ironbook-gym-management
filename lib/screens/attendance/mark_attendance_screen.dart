import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/attendance_model.dart';
import '../../models/member_model.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/skeleton_loader.dart';

class MarkAttendanceScreen extends ConsumerStatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  ConsumerState<MarkAttendanceScreen> createState() =>
      _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends ConsumerState<MarkAttendanceScreen> {
  final _searchController = TextEditingController();
  bool _isCheckInMode = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $amPm';
  }

  String _formatDuration(int? minutes) {
    if (minutes == null) return 'In Progress';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  Future<void> _refresh() async {
    final gymId = ref.read(authProvider).gymId;
    if (gymId == null) return;
    ref.invalidate(todayAttendanceProvider(gymId));
    ref.read(memberListProvider(gymId).notifier).search(gymId, _searchController.text);
  }

  Future<void> _handleCheckIn(MemberModel member) async {
    final gymId = ref.read(authProvider).gymId;
    if (gymId == null) return;

    try {
      await ref.read(attendanceRepositoryProvider).checkIn(gymId, member.id);
      ref.invalidate(todayAttendanceProvider(gymId));
      _searchController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member.name} checked in successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _handleCheckOut(AttendanceModel record) async {
    final gymId = ref.read(authProvider).gymId;
    if (gymId == null) return;

    try {
      await ref.read(attendanceRepositoryProvider).checkOut(gymId, record.id);
      ref.invalidate(todayAttendanceProvider(gymId));
      if (!mounted) return;
      final name = record.memberName ?? 'Member';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name checked out successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gymId = ref.watch(authProvider.select((s) => s.gymId));
    if (gymId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Mark Attendance'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final membersAsync = ref.watch(memberListProvider(gymId));
    final todayAttendanceAsync = ref.watch(todayAttendanceProvider(gymId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSearchField(),
            const SizedBox(height: 12),
            _buildModeToggle(),
            const SizedBox(height: 16),
            if (_searchController.text.isNotEmpty) ...[
              _buildMemberResults(membersAsync),
              const SizedBox(height: 24),
            ],
            _buildAttendanceHeader(),
            const SizedBox(height: 12),
            _buildAttendanceContent(todayAttendanceAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      borderRadius: 16,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search by name or phone...',
          hintStyle: TextStyle(color: AppColors.textMuted),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () {
                    _searchController.clear();
                    final gymId = ref.read(authProvider).gymId;
                    if (gymId != null) {
                      ref
                          .read(memberListProvider(gymId).notifier)
                          .search(gymId, '');
                    }
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (value) {
          final gymId = ref.read(authProvider).gymId;
          if (gymId != null) {
            ref
                .read(memberListProvider(gymId).notifier)
                .search(gymId, value);
          }
          setState(() {});
        },
      ),
    );
  }

  Widget _buildModeToggle() {
    return GlassContainer(
      padding: const EdgeInsets.all(6),
      borderRadius: 16,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isCheckInMode = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isCheckInMode
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.login_rounded,
                      size: 18,
                      color: _isCheckInMode
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Check In',
                      style: TextStyle(
                        color: _isCheckInMode
                            ? AppColors.primary
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isCheckInMode = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isCheckInMode
                      ? AppColors.accent.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: !_isCheckInMode
                          ? AppColors.accent
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Check Out',
                      style: TextStyle(
                        color: !_isCheckInMode
                            ? AppColors.accent
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberResults(AsyncValue<List<MemberModel>> membersAsync) {
    return membersAsync.when(
      loading: () => Column(
        children: List.generate(3, (_) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: SkeletonCard(),
        )),
      ),
      error: (e, _) => GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Error loading members',
          style: TextStyle(color: AppColors.danger),
        ),
      ),
      data: (members) {
        if (members.isEmpty) {
          return GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'No members found',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            ),
          );
        }
        return GlassContainer(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: List.generate(members.length, (i) {
              final member = members[i];
              final isLast = i == members.length - 1;
              return Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _isCheckInMode
                        ? () => _handleCheckIn(member)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                member.initials,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
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
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  member.phone,
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isCheckInMode)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Check In',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: AppColors.border.withValues(alpha: 0.3),
                      indent: 54,
                    ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceHeader() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.today_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Text(
            "Today's Attendance",
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceContent(
      AsyncValue<List<AttendanceModel>> attendanceAsync) {
    return attendanceAsync.when(
      loading: () => Column(
        children: List.generate(4, (_) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: SkeletonCard(),
        )),
      ),
      error: (e, _) => GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Error: ${e.toString().replaceFirst('Exception: ', '')}',
            style: TextStyle(color: AppColors.danger, fontSize: 14),
          ),
        ),
      ),
      data: (records) {
        if (records.isEmpty) {
          return GlassContainer(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.fingerprint,
                      size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'No attendance records for today',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Check in members to see them here',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          children: List.generate(records.length, (i) {
            final record = records[i];
            final isCheckedIn = record.checkOut == null;
            final isCheckOutMode = !_isCheckInMode;
            final canTapCheckOut = isCheckOutMode && isCheckedIn;

            return Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: canTapCheckOut
                    ? () => _handleCheckOut(record)
                    : null,
                child: GlassContainer(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: (isCheckedIn
                                  ? AppColors.success
                                  : AppColors.textMuted)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            (record.memberName?.isNotEmpty == true
                                    ? record.memberName![0]
                                    : '?')
                                .toUpperCase(),
                            style: TextStyle(
                              color: isCheckedIn
                                  ? AppColors.success
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
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
                              record.memberName ?? 'Unknown Member',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.login_rounded,
                                    size: 11, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTime(record.checkIn),
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                if (record.checkOut != null) ...[
                                  const SizedBox(width: 12),
                                  Icon(Icons.logout_rounded,
                                      size: 11, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTime(record.checkOut!),
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDuration(record.durationMinutes),
                              style: TextStyle(
                                color: isCheckedIn
                                    ? AppColors.success
                                    : AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (isCheckedIn
                                  ? AppColors.success
                                  : AppColors.textMuted)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isCheckedIn ? 'Checked In' : 'Checked Out',
                          style: TextStyle(
                            color: isCheckedIn
                                ? AppColors.success
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      if (canTapCheckOut) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Check Out',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
