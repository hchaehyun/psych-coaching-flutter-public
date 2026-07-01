import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/self_tracking_attendance.dart';
import '../../domain/entities/self_tracking_record.dart';
import '../../domain/entities/self_tracking_streak.dart';
import '../../domain/entities/today_self_tracking_status.dart';

part 'self_tracking_remote_datasource.g.dart';

@riverpod
SelfTrackingRemoteDataSource selfTrackingRemoteDataSource(Ref ref) {
  return SelfTrackingRemoteDataSourceImpl(ref.watch(dioProvider));
}

class SelfTrackingRemoteDataSourceImpl implements SelfTrackingRemoteDataSource {
  SelfTrackingRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<TodaySelfTrackingStatus> getTodayRecord() async {
    final response = await _dio.get('/self-tracking/today');
    final data = _extractResponseData(response.data);

    return TodaySelfTrackingStatus(
      exists: data['exists'] as bool? ?? false,
      logicalDate: data['logical_date'] as String? ?? '',
      record: _parseRecordOrNull(data['record']),
    );
  }

  @override
  Future<SelfTrackingStreak> getStreak() async {
    final response = await _dio.get('/self-tracking/streak');
    final data = _extractResponseData(response.data);

    return SelfTrackingStreak(
      logicalDate: data['logical_date'] as String? ?? '',
      checkedInToday: data['checked_in_today'] as bool? ?? false,
      currentStreakDays: _toInt(data['current_streak_days']),
      longestStreakDays: _toInt(data['longest_streak_days']),
      totalAttendanceDays: _toInt(data['total_attendance_days']),
      lastAttendedLogicalDate:
          data['last_attended_logical_date'] as String? ?? '',
      streakState: SelfTrackingStreakState.fromJson(
        data['streak_state'] as String? ?? '',
      ),
    );
  }

  @override
  Future<SelfTrackingAttendance> getAttendance({
    required String fromLogicalDate,
    required String toLogicalDate,
  }) async {
    final response = await _dio.get(
      '/self-tracking/attendance',
      queryParameters: {'from': fromLogicalDate, 'to': toLogicalDate},
    );
    final data = _extractResponseData(response.data);

    return SelfTrackingAttendance(
      fromLogicalDate: data['from_logical_date'] as String? ?? '',
      toLogicalDate: data['to_logical_date'] as String? ?? '',
      attendanceDates: _toStringSet(data['attendance_dates']),
    );
  }

  @override
  Future<SelfTrackingRecord> saveTodayRecord({
    required int emotionCode,
    required double sleepHours,
    required int sleepQuality,
  }) async {
    final response = await _dio.put(
      '/self-tracking/today',
      data: {
        'emotion_code': emotionCode,
        'sleep_hours': sleepHours,
        'sleep_quality': sleepQuality,
      },
    );

    return _parseRecord(_extractResponseData(response.data));
  }

  Map<String, dynamic> _extractResponseData(dynamic rawResponse) {
    final root = _asMap(rawResponse);
    if (root['success'] != true) {
      throw Exception('Self tracking API request failed');
    }

    final data = root['data'];
    if (data is! Map) {
      throw Exception('Self tracking API response is missing data');
    }

    return Map<String, dynamic>.from(data);
  }

  SelfTrackingRecord? _parseRecordOrNull(dynamic rawRecord) {
    if (rawRecord == null) return null;
    return _parseRecord(_asMap(rawRecord));
  }

  SelfTrackingRecord _parseRecord(Map<String, dynamic> rawRecord) {
    return SelfTrackingRecord(
      userId: rawRecord['user_id'] as String? ?? '',
      logicalDate: rawRecord['logical_date'] as String? ?? '',
      emotionCode: _toInt(rawRecord['emotion_code']),
      emotionLabel: rawRecord['emotion_label'] as String? ?? '',
      sleepHours: _toDouble(rawRecord['sleep_hours']),
      sleepQuality: _toInt(rawRecord['sleep_quality']),
      recordedAt: _toDateTime(rawRecord['recorded_at']),
      updatedAt: _toDateTime(rawRecord['updated_at']),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw Exception('Expected a JSON object response');
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  Set<String> _toStringSet(dynamic value) {
    if (value is! List) return const {};
    return value.whereType<String>().toSet();
  }

  DateTime _toDateTime(dynamic value) {
    final milliseconds = value is int ? value : int.tryParse('$value');
    if (milliseconds == null) {
      throw Exception('Expected epoch milliseconds for date field');
    }
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }
}

abstract class SelfTrackingRemoteDataSource {
  Future<TodaySelfTrackingStatus> getTodayRecord();

  Future<SelfTrackingStreak> getStreak();

  Future<SelfTrackingAttendance> getAttendance({
    required String fromLogicalDate,
    required String toLogicalDate,
  });

  Future<SelfTrackingRecord> saveTodayRecord({
    required int emotionCode,
    required double sleepHours,
    required int sleepQuality,
  });
}
