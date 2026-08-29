import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/empty_state_widget.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymId = ref.watch(authProvider.select((s) => s.gymId));
    if (gymId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final notifAsync = ref.watch(notificationListProvider(gymId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: notifAsync.when(
          data: (notifs) => notifs.isEmpty
              ? const EmptyStateWidget(
                  title: 'No notifications',
                  message: "You're all caught up!",
                  icon: Icons.notifications_none_rounded,
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(notificationListProvider(gymId));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifs.length,
                    itemBuilder: (context, i) {
                    final n = notifs[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: n.isRead ? AppColors.surface : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: n.isRead ? AppColors.border : AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!n.isRead)
                              Container(
                                width: 8, height: 8,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              )
                            else
                              const SizedBox(width: 8),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n.title,
                                      style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14),
                                      maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(n.body,
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                      maxLines: 3, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  ),
                ),
          loading: () => const _NotificationsSkeleton(),
          error: (e, _) => const EmptyStateWidget(title: 'Error', message: 'Failed to load notifications'),
        ),
      ),
    );
  }
}

class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: List.generate(10, (_) => const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: _NotifItemSkeleton(),
        )),
      ),
    );
  }
}

class _NotifItemSkeleton extends StatelessWidget {
  const _NotifItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          SkeletonLoader(width: 40, height: 40, borderRadius: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 180, height: 13),
                SizedBox(height: 6),
                SkeletonLoader(width: 120, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
