import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/member_provider.dart';
import '../../models/member_model.dart';
import '../../models/attendance_model.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  static const _avatarGradients = [
    [Color(0xFF6C63FF), Color(0xFF9C5CFF)],
    [Color(0xFF00D68F), Color(0xFF0CBCB0)],
    [Color(0xFFFFB020), Color(0xFFFF7849)],
    [Color(0xFFFF6B9D), Color(0xFFA855F7)],
    [Color(0xFF34D399), Color(0xFF059669)],
  ];

  @override
  Widget build(BuildContext context) {
    final gymId = ref.watch(authProvider.select((s) => s.gymId));
    if (gymId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final attendanceAsync = ref.watch(todayAttendanceProvider(gymId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: attendanceAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.danger))),
          data: (records) {
            return Column(
              children: [
                _buildStatsRow(records),
                const SizedBox(height: 12),
                _buildQrBanner(),
                const SizedBox(height: 14),
                _buildMarkAttendanceButton(gymId),
                const SizedBox(height: 16),
                Expanded(
                  child: records.isEmpty ? _buildEmptyState() : _buildAttendanceList(records),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsRow(List<AttendanceModel> records) {
    final todayCount = records.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('$todayCount', 'Today', const Color(0xFF10B981))),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('$todayCount', 'This Week', const Color(0xFF6366F1))),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('$todayCount', 'This Month', AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildQrBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => context.push('/attendance/qr-scanner'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0x336366F1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x266366F1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.qr_code_scanner_rounded, size: 18, color: Color(0xFF818CF8)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Enable QR scan for faster check-ins',
                    style: TextStyle(color: const Color(0xFF818CF8), fontSize: 12)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF818CF8),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text('Open Scanner',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarkAttendanceButton(String gymId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton.icon(
          onPressed: () => _showMemberPicker(gymId),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Mark Attendance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            shadowColor: AppColors.primary.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.fingerprint_rounded, size: 36, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          const Text('No Records Yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          Text('Mark attendance manually or set up QR scan.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(List<AttendanceModel> records) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: records.length,
      itemBuilder: (context, i) => _buildAttendanceCard(records[i], i),
    );
  }

  Widget _buildAttendanceCard(AttendanceModel record, int index) {
    final checkInTime = '${record.checkIn.hour.toString().padLeft(2, '0')}:${record.checkIn.minute.toString().padLeft(2, '0')}';
    final duration = record.durationMinutes != null ? '${record.durationMinutes}m' : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: null,
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
                      (record.memberName?.isNotEmpty == true ? record.memberName![0] : '?').toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.memberName ?? 'Unknown',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 11, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(checkInTime,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          if (duration != null) ...[
                            const SizedBox(width: 8),
                            Text(duration,
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text('Present',
                      style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w700, fontSize: 10)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMemberPicker(String gymId) {
    final selectedIds = <String>{};
    String searchQuery = '';
    List<MemberModel> allMembers = [];
    List<MemberModel> filteredMembers = [];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final membersAsync = ref.watch(memberListProvider(gymId));
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Select Members',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                            GestureDetector(
                              onTap: () => Navigator.pop(sheetContext),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          onChanged: (v) {
                            searchQuery = v.toLowerCase();
                            setSheetState(() {
                              filteredMembers = allMembers.where((m) =>
                                m.name.toLowerCase().contains(searchQuery) ||
                                m.phone.contains(searchQuery)
                              ).toList();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search members...',
                            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: membersAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (members) {
                        if (allMembers.isEmpty) {
                          allMembers = members;
                          filteredMembers = members;
                        }
                        if (filteredMembers.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.people_outline_rounded, size: 40, color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 16),
                                Text(searchQuery.isEmpty ? 'No members found' : 'No matches found',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                              ],
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: filteredMembers.length,
                          itemBuilder: (ctx, i) {
                            final m = filteredMembers[i];
                            final isSelected = selectedIds.contains(m.id);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  setSheetState(() {
                                    if (isSelected) {
                                      selectedIds.remove(m.id);
                                    } else {
                                      selectedIds.add(m.id);
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (v) {
                                          setSheetState(() {
                                            if (v == true) {
                                              selectedIds.add(m.id);
                                            } else {
                                              selectedIds.remove(m.id);
                                            }
                                          });
                                        },
                                        activeColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      ),
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          gradient: LinearGradient(
                                            colors: _avatarGradients[allMembers.indexOf(m) % _avatarGradients.length],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(m.name[0].toUpperCase(),
                                              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(m.name,
                                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                const Icon(Icons.phone_rounded, size: 11, color: AppColors.textMuted),
                                                const SizedBox(width: 4),
                                                Text(m.phone,
                                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (selectedIds.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border(top: BorderSide(color: AppColors.border)),
                      ),
                      child: SafeArea(
                        child: SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final repo = ref.read(attendanceRepositoryProvider);
                              final results = await Future.wait(
                                selectedIds.map((id) async {
                                  try {
                                    await repo.checkIn(gymId, id);
                                    return true;
                                  } catch (_) {
                                    return false;
                                  }
                                }),
                              );
                              final success = results.where((r) => r).length;
                              final failed = selectedIds.length - success;
                              ref.invalidate(todayAttendanceProvider(gymId));
                              if (sheetContext.mounted) Navigator.pop(sheetContext);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$success member(s) checked in${failed > 0 ? ', $failed failed' : ''}'),
                                    backgroundColor: failed > 0 ? AppColors.warning : const Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.checklist_rounded, size: 18),
                            label: Text('Mark Attendance (${selectedIds.length})',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
