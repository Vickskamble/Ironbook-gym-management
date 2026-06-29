import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width >= 768)
            _buildSidebar(context),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar:
          MediaQuery.of(context).size.width < 768
              ? _buildBottomNav(context)
              : null,
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(context, Icons.dashboard_rounded, 'Home', '/dashboard', location),
              _navItem(context, Icons.people_rounded, 'Members', '/members', location),
              _navItem(context, Icons.fitness_center_rounded, 'Plans', '/plans', location),
              _navItem(context, Icons.receipt_long_rounded, 'Payments', '/payments', location),
              _navItem(context, Icons.fingerprint, 'Attendance', '/attendance', location),
              _moreItem(context, location),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moreItem(BuildContext context, String location) {
    final active = location == '/settings' || location == '/expenses' || location == '/reports' || location == '/import-export' || location == '/notifications';
    return GestureDetector(
      onTap: () => _showMoreSheet(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.more_horiz_rounded,
            color: active ? AppColors.primary : AppColors.textMuted,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            'More',
            style: TextStyle(
              fontSize: 11,
              color: active ? AppColors.primary : AppColors.textMuted,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              _moreTile(ctx, Icons.receipt_rounded, 'Expenses', '/expenses'),
              _moreTile(ctx, Icons.bar_chart_rounded, 'Reports', '/reports'),
              _moreTile(ctx, Icons.file_upload_rounded, 'Import/Export', '/import-export'),
              _moreTile(ctx, Icons.notifications_rounded, 'Notifications', '/notifications'),
              const Divider(color: AppColors.border, height: 24),
              _moreTile(ctx, Icons.settings_rounded, 'Settings', '/settings'),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moreTile(BuildContext context, IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, String route, String current) {
    final active = current == route || current.startsWith('$route/');
    return GestureDetector(
      onTap: () => context.go(route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: active ? AppColors.primary : AppColors.textMuted,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: active ? AppColors.primary : AppColors.textMuted,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ).createShader(bounds),
              child: const Text('IronBook', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
            const SizedBox(height: 32),
            _sidebarItem(context, Icons.dashboard_rounded, 'Dashboard', '/dashboard', location),
            _sidebarItem(context, Icons.people_rounded, 'Members', '/members', location),
            _sidebarItem(context, Icons.fitness_center_rounded, 'Plans', '/plans', location),
            _sidebarItem(context, Icons.receipt_long_rounded, 'Payments', '/payments', location),
            _sidebarItem(context, Icons.fingerprint, 'Attendance', '/attendance', location),
            _sidebarItem(context, Icons.receipt_rounded, 'Expenses', '/expenses', location),
            _sidebarItem(context, Icons.bar_chart_rounded, 'Reports', '/reports', location),
            _sidebarItem(context, Icons.file_upload_rounded, 'Import/Export', '/import-export', location),
            const Spacer(),
            _sidebarItem(context, Icons.settings_rounded, 'Settings', '/settings', location),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sidebarItem(BuildContext context, IconData icon, String label, String route, String current) {
    final active = current == route || current.startsWith('$route/');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: active ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: active ? AppColors.primary : AppColors.textMuted, size: 22),
        title: Text(label, style: TextStyle(color: active ? AppColors.primary : AppColors.textSecondary, fontWeight: active ? FontWeight.w600 : FontWeight.w400, fontSize: 14)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () => context.go(route),
        dense: true,
      ),
    );
  }
}
