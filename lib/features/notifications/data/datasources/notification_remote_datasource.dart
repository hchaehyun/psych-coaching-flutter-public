import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/app_notification.dart';

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
      return NotificationRemoteDataSourceImpl(ref.watch(dioProvider));
    });

abstract class NotificationRemoteDataSource {
  Future<List<AppNotification>> getNotifications({int limit = 20, int? before});

  Future<int> getUnreadCount();

  Future<AppNotification> markRead(String id);

  Future<int> markAllRead();

  Future<void> deleteNotification(String id);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<AppNotification>> getNotifications({
    int limit = 20,
    int? before,
  }) async {
    final queryParameters = <String, dynamic>{'limit': limit};
    if (before != null) {
      queryParameters['before'] = before;
    }

    final response = await _dio.get(
      '/notifications',
      queryParameters: queryParameters,
    );
    final data = _extractResponseData(response.data);
    if (data is! List) {
      throw Exception('Notification API response is missing list data');
    }

    return data.map((raw) => _parseNotification(_asMap(raw))).toList();
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await _dio.get('/notifications/unread-count');
    final data = _asMap(_extractResponseData(response.data));
    return _toInt(data['count']);
  }

  @override
  Future<AppNotification> markRead(String id) async {
    final response = await _dio.patch('/notifications/$id/read');
    return _parseNotification(_asMap(_extractResponseData(response.data)));
  }

  @override
  Future<int> markAllRead() async {
    final response = await _dio.patch('/notifications/read-all');
    final data = _asMap(_extractResponseData(response.data));
    return _toInt(data['updated']);
  }

  @override
  Future<void> deleteNotification(String id) async {
    await _dio.delete('/notifications/$id');
  }

  dynamic _extractResponseData(dynamic rawResponse) {
    final root = _asMap(rawResponse);
    if (root['success'] != true) {
      throw Exception('Notification API request failed');
    }
    return root['data'];
  }

  AppNotification _parseNotification(Map<String, dynamic> raw) {
    return AppNotification(
      id: raw['id'] as String? ?? '',
      userId: raw['user_id'] as String? ?? '',
      type: raw['type'] as String? ?? '',
      title: raw['title'] as String? ?? '',
      body: raw['body'] as String? ?? '',
      targetType: raw['target_type'] as String?,
      targetId: raw['target_id'] as String?,
      payload: _toStringKeyedMap(raw['payload']),
      dedupeKey: raw['dedupe_key'] as String?,
      createdAt: _toDateTime(raw['created_at']),
      readAt: _toDateTimeOrNull(raw['read_at']),
      deletedAt: _toDateTimeOrNull(raw['deleted_at']),
      expiresAt: _toDateTimeOrNull(raw['expires_at']),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw Exception('Expected a JSON object response');
  }

  Map<String, dynamic> _toStringKeyedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  DateTime _toDateTime(dynamic value) {
    final milliseconds = value is int ? value : int.tryParse('$value');
    if (milliseconds == null) {
      throw Exception('Expected epoch milliseconds for date field');
    }
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  DateTime? _toDateTimeOrNull(dynamic value) {
    if (value == null) return null;
    return _toDateTime(value);
  }
}
