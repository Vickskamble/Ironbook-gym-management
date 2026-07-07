import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).signOut();
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _buildSection('APPEARANCE'),
            const SizedBox(height: 12),
            _buildSettingsItem(
              icon: Icons.dark_mode_rounded,
              iconColor: AppColors.primary,
              title: 'Dark Mode',
              subtitle: 'Always active',
            ),
            const SizedBox(height: 24),
            _buildSection('LANGUAGE'),
            const SizedBox(height: 12),
            _buildLangTile(
              'English',
              'en',
              '\u{1F1EC}\u{1F1E7}',
              locale.languageCode,
            ),
            const SizedBox(height: 8),
            _buildLangTile(
              'हिन्दी',
              'hi',
              '\u{1F1EE}\u{1F1F3}',
              locale.languageCode,
            ),
            const SizedBox(height: 8),
            _buildLangTile(
              'मराठी',
              'mr',
              '\u{1F1EE}\u{1F1F3}',
              locale.languageCode,
            ),
            const SizedBox(height: 24),
            _buildSection('ACCOUNT'),
            const SizedBox(height: 12),
            _buildSettingsItem(
              icon: Icons.person_rounded,
              iconColor: AppColors.primary,
              title: 'Profile',
              subtitle: 'Manage your profile',
              showChevron: true,
              onTap: () => context.push('/settings/profile'),
            ),
            _buildSettingsItem(
              icon: Icons.receipt_long_rounded,
              iconColor: AppColors.primary,
              title: 'Subscription',
              subtitle: 'View your plan',
              showChevron: true,
              onTap: () => context.push('/settings/pricing'),
            ),
            _buildSettingsItem(
              icon: Icons.info_outline_rounded,
              iconColor: AppColors.primary,
              title: 'About',
              subtitle: 'Version 1.0.0',
              showChevron: true,
            ),
            const SizedBox(height: 24),
            _buildSection('SUPPORT'),
            const SizedBox(height: 12),
            _buildSettingsItem(
              icon: Icons.bug_report_rounded,
              iconColor: AppColors.warning,
              title: 'Report Issue',
              subtitle: 'Submit a bug report or feedback',
              showChevron: true,
              onTap: () => context.push('/settings/report-issue'),
            ),
            const SizedBox(height: 24),
            _buildSection('SESSION'),
            const SizedBox(height: 12),
            _buildSettingsItem(
              icon: Icons.logout_rounded,
              iconColor: AppColors.danger,
              title: 'Logout',
              subtitle: 'Sign out of your account',
              isDestructive: true,
              onTap: _confirmLogout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool showChevron = false,
    bool isDestructive = false,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDestructive ? const Color(0x1AEF4444) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDestructive ? const Color(0x26EF4444) : AppColors.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? const Color(0x1AEF4444)
                        : iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDestructive
                              ? AppColors.danger
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing
                else if (showChevron)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white24,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLangTile(
    String name,
    String code,
    String flag,
    String currentCode,
  ) {
    final selected = currentCode == code;
    return Container(
      decoration: BoxDecoration(
        color: selected ? const Color(0x0A6366F1) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? const Color(0x406366F1) : AppColors.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => ref.read(localeProvider.notifier).setLocale(code),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6366F1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
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
