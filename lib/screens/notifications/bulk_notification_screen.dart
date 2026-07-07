import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _loading = true;
  List<Map<String, dynamic>> _allMembers = [];
  List<Map<String, dynamic>> _filteredMembers = [];
  String _search = '';
  bool _showExpiring = false;
  int _expiringThreshold = 30;
  bool _showForm = false;
  bool _sending = false;
  final _titleController = TextEditingController(
    text: 'Membership Expiry Reminder',
  );
  final _bodyController = TextEditingController(
    text: 'Hi {name}, your {plan} plan is expiring in {days} days. '
        'Please renew to continue enjoying our services.',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMembers());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => _loading = true);
    try {
      final gid = ref.read(authProvider).gymId;
      if (gid == null) return;
      final repo = ref.read(notificationRepositoryProvider);
      final members = await repo.getAllMembersForNotification(gid);
      setState(() {
        _allMembers = members;
        _applyFilter();
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

  void _applyFilter() {
    List<Map<String, dynamic>> list = List.from(_allMembers);
    if (_showExpiring) {
      list = list.where((m) {
        final days = m['days_until_expiry'] as int?;
        return days != null && days <= _expiringThreshold;
      }).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((m) {
        final name = (m['name'] as String).toLowerCase();
        final phone = (m['phone'] as String).toLowerCase();
        return name.contains(q) || phone.contains(q);
      }).toList();
    }
    _filteredMembers = list;
  }

  void _onFilterChanged() {
    setState(() {
      _selectedIds.clear();
      _applyFilter();
    });
  }

  Future<void> _sendNotifications() async {
    if (_selectedIds.isEmpty) return;
    setState(() => _sending = true);
    try {
      final selected = _allMembers.where((m) => _selectedIds.contains(m['id'])).toList();
      final gid = ref.read(authProvider).gymId;
      if (gid == null) return;
      final repo = ref.read(notificationRepositoryProvider);
      final count = await repo.sendBulkNotifications(
        gid, selected, _titleController.text, _bodyController.text,
      );

      final phones = selected
          .map((m) => m['phone'] as String)
          .where((p) => p.isNotEmpty)
          .toList();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count notification(s) sent'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      setState(() => _sending = false);

      if (phones.isNotEmpty && mounted) {
        final sendVia = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Send via WhatsApp?', style: TextStyle(color: Colors.white)),
            content: Text(
              '$count in-app notifications sent.\n\n'
              'Also send via WhatsApp to ${phones.length} member(s)?',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'whatsapp'),
                child: const Text('Send WhatsApp'),
              ),
            ],
          ),
        );
        if (sendVia == 'whatsapp') {
          _openWhatsApp(phones);
        }
      }
      _selectedIds.clear();
      setState(() => _showForm = false);
      ref.invalidate(unreadCountProvider(gid));
    } catch (e) {
      setState(() => _sending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Send failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _openWhatsApp(List<String> phones) async {
    if (phones.isEmpty) return;
    final body = _bodyController.text
        .replaceAll('{name}', 'Member')
        .replaceAll('{days}', 'X')
        .replaceAll('{plan}', 'your plan');

    for (int i = 0; i < phones.length; i++) {
      final cleaned = phones[i].replaceAll(RegExp(r'[^0-9]'), '');
      if (cleaned.isNotEmpty) {
        final uri = Uri.parse('https://wa.me/$cleaned?text=${Uri.encodeComponent(body)}');
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (i < phones.length - 1) {
            await Future.delayed(const Duration(seconds: 2));
          }
        } catch (_) {}
      }
    }
  }

  String _daysLabel(int? days) {
    if (days == null) return 'N/A';
    if (days < 0) return 'Expired';
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    return '$days days';
  }

  Color _daysColor(int? days) {
    if (days == null) return AppColors.textSecondary;
    if (days < 0) return AppColors.danger;
    if (days <= 3) return Colors.orange;
    if (days <= 7) return Colors.amber;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Column(
                children: [
                  _buildToggleBar(),
                  _buildSearchBar(),
                  if (_showExpiring) _buildFilterBar(),
                  if (_showForm) _buildForm(),
                  if (_showForm && _selectedIds.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        '${_selectedIds.length} member(s) selected',
                        style: const TextStyle(
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
            ),
            if (_selectedIds.isNotEmpty)
              _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const Text(
            'Notify Members',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _loading ? null : _loadMembers,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_showExpiring) {
                  setState(() => _showExpiring = false);
                  _onFilterChanged();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_showExpiring ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'All Members',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_showExpiring) {
                  setState(() => _showExpiring = true);
                  _onFilterChanged();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _showExpiring ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Expiring',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        onChanged: (v) {
          _search = v;
          _onFilterChanged();
        },
        decoration: InputDecoration(
          hintText: 'Search by name or phone...',
          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Text('Expiring in:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
    final active = _expiringThreshold == days;
    return GestureDetector(
      onTap: () {
        setState(() => _expiringThreshold = days);
        _onFilterChanged();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
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

  Widget _buildForm() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Title', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Notification title',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Text('Message', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          TextField(
            controller: _bodyController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Use {name}, {days}, {plan} as placeholders',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.all(12),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            'Use {name}, {days}, {plan} as placeholders',
            style: TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildMemberList(ThemeData theme) {
    if (_filteredMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              _showExpiring ? 'No expiring members' : 'No members found',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _filteredMembers.length,
      itemBuilder: (context, i) {
        final m = _filteredMembers[i];
        final days = m['days_until_expiry'] as int?;
        final selected = _selectedIds.contains(m['id']);
        final status = m['status'] as String? ?? 'Active';
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                m['name'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (status != 'Active')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Inactive',
                                  style: TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              m['phone'] as String,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.fitness_center, size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              m['plan_name'] as String,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (days != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _daysColor(days).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _daysLabel(days),
                        style: TextStyle(
                          color: _daysColor(days),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${_selectedIds.length} selected',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                setState(() => _showForm = !_showForm);
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _showForm ? AppColors.success : AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              child: Text(
                _showForm ? 'Hide Form' : 'Compose',
                style: TextStyle(
                  color: _showForm ? AppColors.success : AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: _sending
                      ? null
                      : (_selectedIds.isNotEmpty
                          ? () {
                              if (!_showForm) setState(() => _showForm = true);
                              Future.microtask(() => _sendNotifications());
                            }
                          : null),
                  icon: _sending
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 16),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(_sending ? 'Sending...' : 'Send Now'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
