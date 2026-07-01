import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../di/notification_di.dart';
import '../../domain/entities/app_notification.dart';

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
      NotificationsNotifier.new,
    );

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    if (user == null) return [];

    return _fetch();
  }

  Future<List<AppNotification>> _fetch() async {
    final result = await ref
        .read(appNotificationRepositoryProvider)
        .getNotifications();
    return result.fold((failure) => throw failure, (notifications) {
      return notifications;
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
    ref.invalidate(unreadNotificationCountProvider);
  }

  Future<AppNotification> markRead(AppNotification notification) async {
    if (notification.isRead) {
      return notification;
    }

    final result = await ref
        .read(appNotificationRepositoryProvider)
        .markRead(notification.id);
    final updated = result.fold((failure) => throw failure, (value) => value);
    final previous = state.valueOrNull ?? [];
    state = AsyncData([
      for (final item in previous)
        if (item.id == updated.id) updated else item,
    ]);
    ref.invalidate(unreadNotificationCountProvider);
    return updated;
  }

  Future<void> markAllRead() async {
    final result = await ref
        .read(appNotificationRepositoryProvider)
        .markAllRead();
    result.fold((failure) => throw failure, (_) {});

    final now = DateTime.now();
    final previous = state.valueOrNull ?? [];
    state = AsyncData([
      for (final item in previous)
        item.isRead ? item : item.copyWith(readAt: now),
    ]);
    ref.invalidate(unreadNotificationCountProvider);
  }

  Future<void> deleteNotification(AppNotification notification) async {
    final result = await ref
        .read(appNotificationRepositoryProvider)
        .deleteNotification(notification.id);
    result.fold((failure) => throw failure, (_) {});

    final previous = state.valueOrNull ?? [];
    state = AsyncData([
      for (final item in previous)
        if (item.id != notification.id) item,
    ]);
    ref.invalidate(unreadNotificationCountProvider);
  }
}

final dismissedNotificationIndicatorCountProvider = StateProvider<int>(
  (ref) => 0,
);

final notificationIndicatorVisibleProvider = Provider<bool>((ref) {
  final unreadCount = ref.watch(unreadNotificationCountProvider).valueOrNull;
  final dismissedCount = ref.watch(dismissedNotificationIndicatorCountProvider);
  if (unreadCount == null || unreadCount <= 0) return false;
  return unreadCount != dismissedCount;
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return 0;

  final result = await ref
      .watch(appNotificationRepositoryProvider)
      .getUnreadCount();
  return result.fold((failure) => throw failure, (count) => count);
});

String notificationErrorMessage(Object error) {
  if (error is Failure) {
    return error.message;
  }
  return '알림 데이터를 처리하지 못했어요.';
}
