import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/error_handler.dart';

class DebugOverlay extends StatefulWidget {
  final Widget child;
  const DebugOverlay({super.key, required this.child});

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    ErrorHandler.logInfo('DebugOverlay', 'Debug overlay initialized');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (kDebugMode)
          Positioned(
            right: 8,
            bottom: 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.8),
                  onPressed: () => setState(() => _visible = !_visible),
                  child: Icon(
                    _visible ? Icons.close : Icons.bug_report,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (_visible) ...[
                  const SizedBox(height: 8),
                  _DebugLogPanel(),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _DebugLogPanel extends StatefulWidget {
  @override
  State<_DebugLogPanel> createState() => _DebugLogPanelState();
}

class _DebugLogPanelState extends State<_DebugLogPanel> {
  Timer? _refreshTimer;
  final ScrollController _scrollController = ScrollController();
  String _filterLevel = 'ALL';

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  List<DebugLog> get _filteredLogs {
    final logs = ErrorHandler.recentLogs;
    if (_filterLevel != 'ALL') {
      return logs.where((l) => l.level == _filterLevel).toList();
    }
    return logs;
  }

  @override
  Widget build(BuildContext context) {
    final logs = _filteredLogs;
    return Container(
      width: 380,
      height: 400,
      decoration: BoxDecoration(
        color: const Color(0xF00A0A0F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          Expanded(
            child: logs.isEmpty
                ? const Center(
                    child: Text(
                      'No logs yet',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(4),
                    itemCount: logs.length,
                    itemBuilder: (_, i) => _LogTile(log: logs[i]),
                  ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        color: AppColors.primary.withValues(alpha: 0.15),
      ),
      child: Row(
        children: [
          const Icon(Icons.bug_report, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text(
            'Debug Logs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '${ErrorHandler.logCount} total',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              ErrorHandler.clearLogs();
              setState(() {});
            },
            child: Icon(Icons.delete_outline, size: 16, color: Colors.white.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          _FilterChip(
            label: 'ALL',
            selected: _filterLevel == 'ALL',
            onTap: () => setState(() => _filterLevel = 'ALL'),
          ),
          _FilterChip(
            label: 'ERROR',
            selected: _filterLevel == 'ERROR',
            color: AppColors.danger,
            onTap: () => setState(() => _filterLevel = 'ERROR'),
          ),
          _FilterChip(
            label: 'WARN',
            selected: _filterLevel == 'WARN',
            color: Colors.orange,
            onTap: () => setState(() => _filterLevel = 'WARN'),
          ),
          _FilterChip(
            label: 'INFO',
            selected: _filterLevel == 'INFO',
            color: Colors.cyan,
            onTap: () => setState(() => _filterLevel = 'INFO'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 12, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(width: 4),
          Text(
            'Tap bug icon to toggle overlay',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? (color ?? AppColors.primary).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected
                ? (color ?? AppColors.primary).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final DebugLog log;
  const _LogTile({required this.log});

  Color get _levelColor {
    switch (log.level) {
      case 'ERROR':
        return AppColors.danger;
      case 'WARN':
        return Colors.orange;
      default:
        return Colors.cyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: log.level == 'ERROR'
            ? AppColors.danger.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: _levelColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  log.level,
                  style: TextStyle(
                    color: _levelColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                log.source,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 9,
                ),
              ),
              const Spacer(),
              Text(
                '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            log.message,
            style: TextStyle(
              color: log.level == 'ERROR' ? AppColors.danger.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
              fontFamily: 'monospace',
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (log.stackTrace != null && log.stackTrace!.isNotEmpty)
            GestureDetector(
              onTap: () => _showStackTrace(context),
              child: Text(
                'View stack trace...',
                style: TextStyle(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  fontSize: 9,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showStackTrace(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1A1A2E),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber, color: AppColors.danger, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Stack Trace',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: SelectableText(
                    log.stackTrace!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}