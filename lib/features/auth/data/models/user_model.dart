import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.uid,
    super.email,
    super.displayName,
    super.photoUrl,
    super.nickname,
    super.deviceId,
    super.wakeUpTime,
    super.requiredServiceTermsAcceptedAt,
    super.requiredPrivacyTermsAcceptedAt,
    super.allNotificationsAccepted,
    super.allNotificationsUpdatedAt,
    super.optionalMarketingAccepted,
    super.optionalMarketingUpdatedAt,
    super.inAppNotificationsAccepted,
    super.inAppNotificationsUpdatedAt,
    super.optionalPushAccepted,
    super.optionalPushUpdatedAt,
  });

  factory UserModel.fromFirebase(auth.User user) {
    return UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      uid: _readString(data, const ['uid', 'user_id']) ?? '',
      email: _readString(data, const ['userEmail']),
      displayName: _readString(data, const ['userName']),
      nickname: _readString(data, const ['userNickname']),
      photoUrl: _readString(data, const ['profileImageUrl']),
      deviceId: _readString(data, const ['lastLoginDeviceId']),
      wakeUpTime: _readString(data, const ['wakeUpTime']),
      requiredServiceTermsAcceptedAt: _toDateTime(
        _read(data, const ['requiredServiceTermsAcceptedAt']),
      ),
      requiredPrivacyTermsAcceptedAt: _toDateTime(
        _read(data, const ['requiredPrivacyTermsAcceptedAt']),
      ),
      allNotificationsAccepted:
          _readBool(data, const ['allNotificationsAccepted']) ?? true,
      allNotificationsUpdatedAt: _toDateTime(
        _read(data, const ['allNotificationsUpdatedAt']),
      ),
      optionalMarketingAccepted:
          _readBool(data, const ['optionalMarketingAccepted']) ?? false,
      optionalMarketingUpdatedAt: _toDateTime(
        _read(data, const ['optionalMarketingUpdatedAt']),
      ),
      inAppNotificationsAccepted:
          _readBool(data, const ['inAppNotificationsAccepted']) ?? true,
      inAppNotificationsUpdatedAt: _toDateTime(
        _read(data, const ['inAppNotificationsUpdatedAt']),
      ),
      optionalPushAccepted:
          _readBool(data, const ['optionalPushAccepted']) ?? false,
      optionalPushUpdatedAt: _toDateTime(
        _read(data, const ['optionalPushUpdatedAt']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'nickname': nickname,
      'wakeUpTime': wakeUpTime,
    };
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) {
      if (value.trim().isEmpty) return null;
      final milliseconds = int.tryParse(value);
      if (milliseconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(milliseconds);
      }
      return DateTime.tryParse(value);
    }
    return null;
  }

  static dynamic _read(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key)) return data[key];
    }
    return null;
  }

  static String? _readString(Map<String, dynamic> data, List<String> keys) {
    final value = _read(data, keys);
    if (value == null) return null;
    return '$value';
  }

  static bool? _readBool(Map<String, dynamic> data, List<String> keys) {
    final value = _read(data, keys);
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return null;
  }
}
