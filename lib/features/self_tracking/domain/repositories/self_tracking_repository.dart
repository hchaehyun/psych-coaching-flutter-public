import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/self_tracking_attendance.dart';
import '../entities/self_tracking_record.dart';
import '../entities/self_tracking_streak.dart';
import '../entities/today_self_tracking_status.dart';

abstract class SelfTrackingRepository {
  Future<Either<Failure, TodaySelfTrackingStatus>> getTodayRecord();

  Future<Either<Failure, SelfTrackingStreak>> getStreak();

  Future<Either<Failure, SelfTrackingAttendance>> getAttendance({
    required String fromLogicalDate,
    required String toLogicalDate,
  });

  Future<Either<Failure, SelfTrackingRecord>> saveTodayRecord({
    required int emotionCode,
    required double sleepHours,
    required int sleepQuality,
  });
}
