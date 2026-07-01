import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/self_tracking_attendance.dart';
import '../../domain/entities/self_tracking_record.dart';
import '../../domain/entities/self_tracking_streak.dart';
import '../../domain/entities/today_self_tracking_status.dart';
import '../../domain/repositories/self_tracking_repository.dart';
import '../datasources/self_tracking_remote_datasource.dart';

final selfTrackingRepositoryProvider = Provider<SelfTrackingRepository>((ref) {
  return SelfTrackingRepositoryImpl(
    ref.watch(selfTrackingRemoteDataSourceProvider),
  );
});

class SelfTrackingRepositoryImpl implements SelfTrackingRepository {
  final SelfTrackingRemoteDataSource _remoteDataSource;

  SelfTrackingRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, TodaySelfTrackingStatus>> getTodayRecord() async {
    try {
      final result = await _remoteDataSource.getTodayRecord();
      return Right(result);
    } catch (e) {
      return Left(_mapFailure(e));
    }
  }

  @override
  Future<Either<Failure, SelfTrackingStreak>> getStreak() async {
    try {
      final result = await _remoteDataSource.getStreak();
      return Right(result);
    } catch (e) {
      return Left(_mapFailure(e));
    }
  }

  @override
  Future<Either<Failure, SelfTrackingAttendance>> getAttendance({
    required String fromLogicalDate,
    required String toLogicalDate,
  }) async {
    try {
      final result = await _remoteDataSource.getAttendance(
        fromLogicalDate: fromLogicalDate,
        toLogicalDate: toLogicalDate,
      );
      return Right(result);
    } catch (e) {
      return Left(_mapFailure(e));
    }
  }

  @override
  Future<Either<Failure, SelfTrackingRecord>> saveTodayRecord({
    required int emotionCode,
    required double sleepHours,
    required int sleepQuality,
  }) async {
    try {
      final result = await _remoteDataSource.saveTodayRecord(
        emotionCode: emotionCode,
        sleepHours: sleepHours,
        sleepQuality: sleepQuality,
      );
      return Right(result);
    } catch (e) {
      return Left(_mapFailure(e));
    }
  }

  Failure _mapFailure(Object error) {
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

    if (error is Failure) {
      return error;
    }

    return ServerFailure('거울속 나 데이터를 처리하지 못했어요.');
  }

  String _extractMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map &&
        data['message'] is String &&
        data['message'].isNotEmpty) {
      return data['message'] as String;
    }

    return '거울속 나 데이터를 처리하지 못했어요.';
  }
}
