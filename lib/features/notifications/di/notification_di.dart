import 'package:riverpod/riverpod.dart';

import '../data/repositories/notification_repository_impl.dart'
    as data_notification;
import '../domain/repositories/notification_repository.dart';

final appNotificationRepositoryProvider = Provider<NotificationRepository>((
  ref,
) {
  return ref.watch(data_notification.notificationRepositoryProvider);
});
