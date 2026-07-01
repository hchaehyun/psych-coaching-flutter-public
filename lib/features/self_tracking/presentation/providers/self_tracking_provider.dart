import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show FutureProvider, Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../di/self_tracking_di.dart';
import '../../domain/entities/self_tracking_attendance.dart';
import '../../domain/entities/self_tracking_record.dart';
import '../../domain/entities/self_tracking_streak.dart';
import '../../domain/entities/today_self_tracking_status.dart';

part 'self_tracking_provider.g.dart';

@Riverpod(keepAlive: true)
Future<TodaySelfTrackingStatus> selfTrackingTodayStatus(Ref ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;

  if (user == null) {
    return const TodaySelfTrackingStatus(
      exists: false,
      logicalDate: '',
      record: null,
    );
  }

  final result = await ref
      .watch(appSelfTrackingRepositoryProvider)
      .getTodayRecord();
  return result.fold((failure) => throw failure, (status) => status);
}

@riverpod
bool todayRecordExists(Ref ref) {
  final todayStatus = ref.watch(selfTrackingTodayStatusProvider);
  final result = todayStatus.valueOrNull?.exists ?? false;
  debugPrint('[SelfTracking] todayRecordExists = $result');
  return result;
}

final selfTrackingStreakProvider = FutureProvider<SelfTrackingStreak>((
  ref,
) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    throw const AuthFailure('로그인이 필요해요.');
  }

  final result = await ref.watch(appSelfTrackingRepositoryProvider).getStreak();
  return result.fold((failure) => throw failure, (streak) => streak);
});

final selfTrackingAttendanceProvider =
    FutureProvider.family<SelfTrackingAttendance, SelfTrackingAttendanceRange>((
      ref,
      range,
    ) async {
      final authState = ref.watch(authStateProvider);
      final user = authState.valueOrNull;
      if (user == null) {
        throw const AuthFailure('로그인이 필요해요.');
      }

      final result = await ref
          .watch(appSelfTrackingRepositoryProvider)
          .getAttendance(
            fromLogicalDate: range.fromLogicalDate,
            toLogicalDate: range.toLogicalDate,
          );
      return result.fold(
        (failure) => throw failure,
        (attendance) => attendance,
      );
    });

@riverpod
Future<SelfTrackingRecord> saveSelfTracking(
  Ref ref, {
  required int emotionCode,
  required double sleepHours,
  required int sleepQuality,
}) async {
  final authState = ref.read(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) {
    throw const AuthFailure('로그인이 필요해요.');
  }

  final result = await ref
      .read(appSelfTrackingRepositoryProvider)
      .saveTodayRecord(
        emotionCode: emotionCode,
        sleepHours: sleepHours,
        sleepQuality: sleepQuality,
      );

  final record = result.fold((failure) => throw failure, (value) => value);

  ref.invalidate(selfTrackingTodayStatusProvider);
  ref.invalidate(selfTrackingStreakProvider);
  ref.invalidate(selfTrackingAttendanceProvider);
  await ref.read(selfTrackingTodayStatusProvider.future);
  debugPrint('[SelfTracking] 기록 저장 완료: logicalDate=${record.logicalDate}');

  return record;
}
