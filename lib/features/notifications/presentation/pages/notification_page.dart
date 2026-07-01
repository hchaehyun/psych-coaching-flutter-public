import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_app_bar.dart';
import '../../../../core/widgets/github_grass_loading_indicator.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notification_provider.dart';

class NotificationPage extends ConsumerStatefulWidget {
  const NotificationPage({super.key});

  @override
  ConsumerState<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends ConsumerState<NotificationPage> {
  static const int _initialVisibleCount = 5;
  static const int _loadMoreCount = 10;

  int _visibleNotificationCount = _initialVisibleCount;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final unreadNotificationCount =
        (state.valueOrNull ?? const <AppNotification>[])
            .where((notification) => !notification.isRead)
            .length;

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: CommonAppBar(
        title: '알림',
        showBackButton: true,
        actions: [_HeaderUnreadBadge(count: unreadNotificationCount)],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE3E3E3), width: 0.5)),
        ),
        child: state.when(
          loading: () => const Center(child: GitHubGrassLoadingIndicator()),
          error: (error, _) => _NotificationErrorView(
            message: notificationErrorMessage(error),
            onRetry: () => ref.read(notificationsProvider.notifier).refresh(),
          ),
          data: (notifications) {
            final visibleNotifications = notifications
                .take(_visibleNotificationCount)
                .toList(growable: false);
            final hasMore = _visibleNotificationCount < notifications.length;

            return RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: _refreshNotifications,
              child: notifications.isEmpty
                  ? const _EmptyNotificationView()
                  : _NotificationListView(
                      notifications: visibleNotifications,
                      hasMore: hasMore,
                      onLoadMore: _loadMoreNotifications,
                      onOpenNotification: (notification) =>
                          _openNotification(context, notification),
                    ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _visibleNotificationCount = _initialVisibleCount;
    });
    await ref.read(notificationsProvider.notifier).refresh();
  }

  void _loadMoreNotifications() {
    setState(() {
      _visibleNotificationCount += _loadMoreCount;
    });
  }

  Future<void> _openNotification(
    BuildContext context,
    AppNotification notification,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final route = notification.payload['route'];

    try {
      await ref.read(notificationsProvider.notifier).markRead(notification);
      if (!context.mounted) return;
      if (route is String && route.isNotEmpty) {
        context.push(route);
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(notificationErrorMessage(e))),
      );
    }
  }
}

class _HeaderUnreadBadge extends StatelessWidget {
  const _HeaderUnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kToolbarHeight,
      child: Center(
        child: count > 0
            ? Container(
                height: 22,
                constraints: const BoxConstraints(minWidth: 22),
                padding: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _NotificationListView extends StatelessWidget {
  const _NotificationListView({
    required this.notifications,
    required this.hasMore,
    required this.onLoadMore,
    required this.onOpenNotification,
  });

  final List<AppNotification> notifications;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final ValueChanged<AppNotification> onOpenNotification;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.surfaceColor,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(38, 28, 38, 28),
        itemCount: notifications.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == notifications.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Center(
                child: OutlinedButton(
                  onPressed: onLoadMore,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: const BorderSide(color: Color(0xFFDADDE2)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('더보기'),
                ),
              ),
            );
          }

          final notification = notifications[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == notifications.length - 1 ? 0 : 30,
            ),
            child: _NotificationTile(
              notification: notification,
              onTap: () => onOpenNotification(notification),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final foregroundColor = isUnread
        ? const Color(0xFF333840)
        : const Color(0xFFA6AAB0);
    final metaColor = isUnread
        ? const Color(0xFF898E96)
        : const Color(0xFFB9BDC3);
    final imageAsset = _notificationImageAsset(notification);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _notificationCategory(notification),
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: metaColor,
                    ),
                  ),
                  if (isUnread) ...[
                    const SizedBox(width: 8),
                    const _UnreadDot(),
                  ],
                  const Spacer(),
                  Text(
                    _formatNotificationTime(notification.createdAt),
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: metaColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      notification.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.22,
                        fontWeight: FontWeight.w800,
                        color: foregroundColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 28,
                    color: metaColor,
                  ),
                ],
              ),
              if (imageAsset != null) ...[
                const SizedBox(height: 18),
                Opacity(
                  opacity: isUnread ? 1 : 0.58,
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFC),
                      border: Border.all(color: const Color(0xFFE1E3E6)),
                    ),
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.contain,
                      height: 124,
                    ),
                  ),
                ),
              ],
              if (notification.body.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  notification.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: metaColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppTheme.errorColor,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _EmptyNotificationView extends StatelessWidget {
  const _EmptyNotificationView();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.surfaceColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 7),
                  Image.asset(
                    'assets/images/noti_none.png',
                    width: 88,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '아직 알림이 없어요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '새로운 소식이 오면 여기서 바로 알려드릴게요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF777777),
                    ),
                  ),
                  const Spacer(flex: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationErrorView extends StatelessWidget {
  const _NotificationErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            IconButton(
              tooltip: '다시 시도',
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatNotificationTime(DateTime value) {
  final local = value.toLocal();
  final difference = DateTime.now().difference(local);

  if (difference.isNegative || difference.inMinutes < 1) {
    return '방금 전';
  }
  if (difference.inHours < 1) {
    return '${difference.inMinutes}분 전';
  }
  if (difference.inDays < 1) {
    return '${difference.inHours}시간 전';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays}일 전';
  }

  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.month}월 ${local.day}일 $hour:$minute';
}

String _notificationCategory(AppNotification notification) {
  final category = notification.payload['category'];
  if (category is String && category.trim().isNotEmpty) {
    return category;
  }

  return switch (notification.type) {
    'content' => '콘텐츠',
    'journal' => '일기',
    'self_tracking' => '마음체크',
    _ => '알림',
  };
}

String? _notificationImageAsset(AppNotification notification) {
  final imageAsset = notification.payload['imageAsset'];
  if (imageAsset is String && imageAsset.trim().isNotEmpty) {
    return imageAsset;
  }
  return null;
}
