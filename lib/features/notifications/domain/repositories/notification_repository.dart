import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_notification.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<AppNotification>>> getNotifications({
    int limit = 20,
    int? before,
  });

  Future<Either<Failure, int>> getUnreadCount();

  Future<Either<Failure, AppNotification>> markRead(String id);

  Future<Either<Failure, int>> markAllRead();

  Future<Either<Failure, void>> deleteNotification(String id);
}
