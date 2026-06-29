import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/constants/app_colors.dart';

class BulkNotificationScreen extends ConsumerStatefulWidget {
  const BulkNotificationScreen({super.key});

  @override
  ConsumerState<BulkNotificationScreen> createState() =>
      _BulkNotificationScreenState();
}

class _BulkNotificationScreenState
    extends ConsumerState<BulkNotificationScreen> {
  final Set<String> _selectedIds = {};
  int _maxDays = 7;
  bool _loading = true;
  List<Map<String, dynamic>> _members = [];
  String _title = 'Membership Expiry Reminder';
  final _bodyController = TextEditingController(
    text: 'Hi {name}, your {plan} plan is expiring in {days} days. '
        'Please renew to continue enjoying our services.',
  );
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMembers());
  }

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => _loading = true);
    try {
      final gid = ref.read(authProvider).gymId;
      if (gid == null) return;
      final repo = ref.read(notificationRepositoryProvider);
      final members = await repo.getExpiringMembersForNotification(
        gid,
        maxDays: _maxDays,
      );
      setState(() {
        _members = members;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _sendNotifications() async {
    if (_selectedIds.isEmpty) return;
    final selected = _members.where((m) => _selectedIds.contains(m['id'])).toList();
    final gid = ref.read(authProvider).gymId;
    if (gid == null) return;

    final repo = ref.read(notificationRepositoryProvider);
    final count = await repo.sendBulkNotifications(
      gid, selected, _title, _bodyController.text,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count notification(s) sent'),
          backgroundColor: AppColors.success,
        ),
      );
      _selectedIds.clear();
      setState(() => _showForm = false);
      ref.invalidate(unreadCountProvider);
    }
  }

  String _daysLabel(int days) {
    if (days < 0) return 'Expired';
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    return '$days days';
  }

  Color _daysColor(int days) {
    if (days < 0) return AppColors.danger;
    if (days <= 3) return Colors.orange;
    if (days <= 7) return Colors.amber;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Bulk Notification'),
        actions: [
          TextButton(
            onPressed: _showForm && _selectedIds.isNotEmpty ? null : _loadMembers,
            child: const Text('Refresh'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(theme),
          if (_showForm) _buildForm(theme),
          if (_showForm && _selectedIds.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                '${_selectedIds.length} member(s) selected',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(child: _loading ? _buildLoader() : _buildMemberList(theme)),
        ],
      ),
      bottomNavigationBar: _selectedIds.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _showForm ? _sendNotifications : () {
                      setState(() => _showForm = true);
                    },
                    icon: Icon(_showForm ? Icons.send : Icons.arrow_forward),
                    label: Text(_showForm ? 'Send Now' : 'Continue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildLoader() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildFilterBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Text('Expiring in:', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          _filterChip(7, '7 days'),
          const SizedBox(width: 6),
          _filterChip(15, '15 days'),
          const SizedBox(width: 6),
          _filterChip(30, '30 days'),
          const SizedBox(width: 6),
          _filterChip(365, 'All'),
        ],
      ),
    );
  }

  Widget _filterChip(int days, String label) {
    final active = _maxDays == days;
    return GestureDetector(
      onTap: () {
        setState(() => _maxDays = days);
        _loadMembers();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notification Title',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter title',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            controller: TextEditingController(text: _title)
              ..selection = TextSelection.fromPosition(
                TextPosition(offset: _title.length),
              ),
            onChanged: (v) => _title = v,
          ),
          const SizedBox(height: 12),
          Text('Message Body',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _bodyController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Use {name}, {days}, {plan} as placeholders',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            'Use {name}, {days}, {plan} as placeholders',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberList(ThemeData theme) {
    if (_members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppColors.success.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No expiring members', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _members.length,
      itemBuilder: (context, i) {
        final m = _members[i];
        final days = m['days_until_expiry'] as int;
        final selected = _selectedIds.contains(m['id']);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                if (selected) {
                  _selectedIds.remove(m['id']);
                } else {
                  _selectedIds.add(m['id']);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Checkbox(
                    value: selected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedIds.add(m['id']);
                        } else {
                          _selectedIds.remove(m['id']);
                        }
                      });
                    },
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['name'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              m['phone'] as String,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.fitness_center, size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              m['plan_name'] as String,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _daysColor(days).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _daysLabel(days),
                      style: TextStyle(
                        color: _daysColor(days),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
