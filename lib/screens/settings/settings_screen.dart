import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/locale_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Appearance'),
          const SizedBox(height: 12),
          SwitchListTile(
            secondary: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: AppColors.primary, size: 22),
            ),
            title: const Text('Dark Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text(isDark ? 'Currently active' : 'Currently inactive', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            value: isDark,
            onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
          ),
          const SizedBox(height: 24),
          _buildSection('Language'),
          const SizedBox(height: 12),
          _buildLangTile('English', 'en', '🇬🇧', locale),
          _buildLangTile('हिन्दी', 'hi', '🇮🇳', locale),
          _buildLangTile('मराठी', 'mr', '🇮🇳', locale),
          const SizedBox(height: 24),
          _buildSection('Account'),
          const SizedBox(height: 12),
          _buildTile(Icons.person_rounded, 'Profile', 'Manage your profile', null),
          _buildTile(Icons.subscriptions_rounded, 'Subscription', 'View your plan', () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const _PricingScreen());
          }),
          _buildTile(Icons.info_outline_rounded, 'About', 'Version 1.0.0', null),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(width: 3, height: 16, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, String subtitle, VoidCallback? onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildLangTile(String name, String code, String flag, Locale currentLocale) {
    final selected = currentLocale.languageCode == code;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(flag, style: const TextStyle(fontSize: 28)),
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        trailing: selected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
        onTap: () => ref.read(localeProvider.notifier).setLocale(code),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _PricingScreen extends StatelessWidget {
  const _PricingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Subscription')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPlanCard('Free', '\u20b90', 'Basic features', ['Up to 50 members', 'Basic reports', 'Email support'], false, null),
          const SizedBox(height: 16),
          _buildPlanCard('Pro', '\u20b9499', '/month', ['Unlimited members', 'Advanced reports', 'Priority support', 'Export data', 'Attendance tracking'], true, () {}),
          const SizedBox(height: 16),
          _buildPlanCard('Enterprise', '\u20b91,999', '/month', ['Everything in Pro', 'Multiple gyms', 'Staff management', 'Custom branding', 'API access', 'Dedicated manager'], false, null),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String name, String price, String period, List<String> features, bool isPopular, VoidCallback? onTap) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isPopular ? const LinearGradient(colors: [AppColors.primary, AppColors.accent], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
        color: isPopular ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPopular ? Colors.transparent : AppColors.border),
        boxShadow: isPopular ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 5)] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: isPopular ? Colors.white : AppColors.textPrimary)),
              if (isPopular) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Popular', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: isPopular ? Colors.white : AppColors.primary)),
              Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(period, style: TextStyle(color: isPopular ? Colors.white70 : AppColors.textSecondary))),
            ],
          ),
          const SizedBox(height: 20),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 20, color: isPopular ? Colors.white : AppColors.success),
                const SizedBox(width: 10),
                Text(f, style: TextStyle(color: isPopular ? Colors.white70 : AppColors.textSecondary, fontSize: 14)),
              ],
            ),
          )),
          if (onTap != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPopular ? Colors.white : AppColors.primary,
                  foregroundColor: isPopular ? AppColors.primary : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Upgrade Now', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
