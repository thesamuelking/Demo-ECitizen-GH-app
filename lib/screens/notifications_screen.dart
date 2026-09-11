import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ghanaserve/providers/auth_provider.dart';
import 'package:ghanaserve/providers/notification_provider.dart';
import 'package:ghanaserve/theme/app_theme.dart';
import 'package:ghanaserve/widgets/app_back_button.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).valueOrNull?.user;
      if (user != null) {
        ref.read(appNotificationsProvider.notifier).loadForUser(
              user.id,
              forceRefresh: true,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifications =
        ref.watch(appNotificationsProvider).valueOrNull ?? const [];
    final unread = notifications.where((item) => !item.isRead).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Theme.of(context).colorScheme.surface,
            pinned: true,
            toolbarHeight: 76,
            leading: const AppBackButton(),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  unread == 0
                      ? 'You are all caught up'
                      : '$unread new notifications',
                  style:
                      GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            actions: [
              if (notifications.isNotEmpty)
                PopupMenuButton<String>(
                  tooltip: 'Notification actions',
                  icon: const Icon(Icons.more_horiz_rounded),
                  onSelected: (value) async {
                    final notifier =
                        ref.read(appNotificationsProvider.notifier);
                    if (value == 'read') await notifier.markAllAsRead();
                    if (value == 'clear') await notifier.clearAll();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'read',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.done_all_rounded),
                        title: Text('Mark all as read'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'clear',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_sweep_outlined),
                        title: Text('Clear all'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (notifications.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyNotifications(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _NotificationTile(
                      notification: notification,
                      onRead: () => ref
                          .read(appNotificationsProvider.notifier)
                          .markAsRead(notification.id),
                      onClear: () => ref
                          .read(appNotificationsProvider.notifier)
                          .clear(notification.id),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onRead;
  final VoidCallback onClear;

  const _NotificationTile({
    required this.notification,
    required this.onRead,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
        color: notification.isRead
          ? Theme.of(context).colorScheme.surface
          : (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF172A3A)
            : const Color(0xFFF0F7FF)),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: notification.isRead ? null : onRead,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4CC),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Center(
                  child: Text('🔔', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _relativeTime(notification.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                tooltip: 'Notification options',
                onSelected: (value) {
                  if (value == 'read') onRead();
                  if (value == 'clear') onClear();
                },
                itemBuilder: (context) => [
                  if (!notification.isRead)
                    const PopupMenuItem(
                      value: 'read',
                      child: Text('Mark as read'),
                    ),
                  const PopupMenuItem(
                    value: 'clear',
                    child: Text('Clear notification'),
                  ),
                ],
                icon:
                    const Icon(Icons.more_vert_rounded, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 54, color: AppColors.mutedLight),
          const SizedBox(height: 12),
          Text(
            'No notifications',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Important updates will appear here.',
            style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
