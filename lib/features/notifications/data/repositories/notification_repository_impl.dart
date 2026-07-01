import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    ref.watch(notificationRemoteDataSourceProvider),
  );
});

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._remoteDataSource);

  final NotificationRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<AppNotification>>> getNotifications({
    int limit = 20,
    int? before,
  }) async {
    try {
      final result = await _remoteDataSource.getNotifications(
        limit: limit,
        before: before,
      );
      return Right(result);
    } catch (e) {
      return Left(_mapFailure(e));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      final result = await _remoteDataSource.getUnreadCount();
      return Right(result);
    } catch (e) {
      return Left(_mapFailure(e));
    }
  }

  @override
  Future<Either<Failure, AppNotification>> markRead(String id) async {
    try {
      final result = await _remoteDataSource.markRead(id);
      return Right(result);
    } catch (e) {
      return Left(_mapFailure(e));
    }
  }

  @override
  Future<Either<Failure, int>> markAllRead() async {
    try {
      final result = await _remoteDataSource.markAllRead();
      return Right(result);
    } catch (e) {
      return Left(_mapFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String id) async {
    try {
      await _remoteDataSource.deleteNotification(id);
      return const Right(null);
    } catch (e) {
      return Left(_mapFailure(e));
    }
  }

  Failure _mapFailure(Object error) {
    if (error is Failure) {
      return error;
    }

    if (error is DioException) {
      final message = _extractMessage(error);
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return NetworkFailure(message);
        default:
          return ServerFailure(message);
      }
    }

    return const ServerFailure('알림 데이터를 처리하지 못했어요.');
  }

  String _extractMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    return '알림 데이터를 처리하지 못했어요.';
  }
}
