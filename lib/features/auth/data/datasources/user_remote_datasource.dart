import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';
part 'user_remote_datasource.g.dart';

abstract class UserRemoteDataSource {
  Future<void> createOrUpdateUser({
    required String uid,
    required String? email,
    required String? displayName,
    required String? photoUrl,
    required String deviceId,
  });
  Future<bool> userExists(String uid);
  Stream<UserModel?> getUserProfileStream(String uid);
  Stream<String?> getLoginDeviceIdStream(String uid);
  Future<void> updateUserProfile({
    required String uid,
    String? nickname,
    String? profileImageUrl,
  });
  Future<void> deleteNickname(String uid);

  /// 하루 시작 시간 업데이트 (HH:mm 형식)
  Future<void> updateWakeUpTime(String uid, String time);
  Future<void> updateOptionalPushAccepted(String uid, bool accepted);
  Future<void> updateNotificationSettings({
    required String uid,
    bool? allNotificationsAccepted,
    bool? optionalPushAccepted,
    bool? inAppNotificationsAccepted,
    bool? optionalMarketingAccepted,
  });
  Future<void> completeSignupOnboarding({
    required String uid,
    required bool optionalMarketingAccepted,
    required bool optionalPushAccepted,
    required String wakeUpTime,
    String? nickname,
  });
  Future<void> deleteUserData(String uid);
}

@riverpod
UserRemoteDataSource userRemoteDataSource(Ref ref) {
  return UserRemoteDataSourceImpl(
    firestore: FirebaseFirestore.instance,
    dio: ref.watch(dioProvider),
  );
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final FirebaseFirestore _firestore;
  final Dio _dio;

  UserRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required Dio dio,
  }) : _firestore = firestore,
       _dio = dio;

  @override
  Future<void> createOrUpdateUser({
    required String uid,
    required String? email,
    required String? displayName,
    required String? photoUrl,
    required String deviceId,
  }) async {
    final docRef = _firestore.collection('users').doc(uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'uid': uid,
        'userEmail': email ?? '',
        'userName': displayName ?? '',
        'userNickname': '', // 초기 닉네임은 비워둠
        'profileImageUrl': photoUrl ?? '',
        'lastLoginDeviceId': deviceId,
        'wakeUpTime': '07:00', // 기본 하루 시작 시간
        'allNotificationsAccepted': true,
        'inAppNotificationsAccepted': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // 기존 유저가 있다면 최신 정보로 업데이트 (닉네임 제외)
      final data = doc.data();
      final updates = <String, dynamic>{};

      if (email != null && data?['userEmail'] != email) {
        updates['userEmail'] = email;
      }
      if (displayName != null && data?['userName'] != displayName) {
        updates['userName'] = displayName;
      }
      if (photoUrl != null && data?['profileImageUrl'] != photoUrl) {
        updates['profileImageUrl'] = photoUrl;
      }

      // 항상 현재 기기 ID로 업데이트 (중복 로그인 체크용)
      if (data?['lastLoginDeviceId'] != deviceId) {
        updates['lastLoginDeviceId'] = deviceId;
      }
      if (data != null &&
          !data.containsKey('profileImageUrl') &&
          photoUrl != null) {
        updates['profileImageUrl'] = photoUrl;
      }
      if (data != null && !data.containsKey('userNickname')) {
        updates['userNickname'] = '';
      }
      if (data != null && !data.containsKey('allNotificationsAccepted')) {
        updates['allNotificationsAccepted'] = true;
      }
      if (data != null && !data.containsKey('inAppNotificationsAccepted')) {
        updates['inAppNotificationsAccepted'] = true;
      }

      if (updates.isNotEmpty) {
        await docRef.update(updates);
      }
    }
  }

  @override
  Future<bool> userExists(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists;
  }

  @override
  Stream<UserModel?> getUserProfileStream(String uid) {
    return Stream.fromFuture(_getCurrentUserProfile(uid));
  }

  @override
  Stream<String?> getLoginDeviceIdStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      final deviceId = doc.data()?['lastLoginDeviceId'];
      if (deviceId == null || '$deviceId'.isEmpty) return null;
      return '$deviceId';
    });
  }

  Future<UserModel?> _getCurrentUserProfile(String uid) async {
    final response = await _dio.get('/users');
    final data = _extractResponseData(response.data);
    if (data == null) return null;

    final profileData = _extractProfileData(data);
    final responseUid = profileData['uid'];
    if (responseUid == null || '$responseUid'.isEmpty) {
      profileData['uid'] = _extractUserId(data) ?? uid;
    }

    return UserModel.fromFirestore(profileData);
  }

  @override
  Future<void> updateUserProfile({
    required String uid,
    String? nickname,
    String? profileImageUrl,
  }) async {
    final updates = <String, dynamic>{};

    if (nickname != null) {
      updates['userNickname'] = nickname;
    }
    if (profileImageUrl != null) {
      updates['profileImageUrl'] = profileImageUrl;
    }

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
    }
  }

  @override
  Future<void> deleteNickname(String uid) async {
    await _firestore.collection('users').doc(uid).update({'userNickname': ''});
  }

  @override
  Future<void> updateWakeUpTime(String uid, String time) async {
    await _firestore.collection('users').doc(uid).update({'wakeUpTime': time});
  }

  @override
  Future<void> updateOptionalPushAccepted(String uid, bool accepted) async {
    await updateNotificationSettings(uid: uid, optionalPushAccepted: accepted);
  }

  @override
  Future<void> updateNotificationSettings({
    required String uid,
    bool? allNotificationsAccepted,
    bool? optionalPushAccepted,
    bool? inAppNotificationsAccepted,
    bool? optionalMarketingAccepted,
  }) async {
    final now = Timestamp.now();
    final updates = <String, dynamic>{};

    if (allNotificationsAccepted != null) {
      updates['allNotificationsAccepted'] = allNotificationsAccepted;
      updates['allNotificationsUpdatedAt'] = now;
    }
    if (optionalPushAccepted != null) {
      updates['optionalPushAccepted'] = optionalPushAccepted;
      updates['optionalPushUpdatedAt'] = now;
    }
    if (inAppNotificationsAccepted != null) {
      updates['inAppNotificationsAccepted'] = inAppNotificationsAccepted;
      updates['inAppNotificationsUpdatedAt'] = now;
    }
    if (optionalMarketingAccepted != null) {
      updates['optionalMarketingAccepted'] = optionalMarketingAccepted;
      updates['optionalMarketingUpdatedAt'] = now;
    }

    if (updates.isEmpty) return;

    await _firestore.collection('users').doc(uid).update({...updates});
  }

  @override
  Future<void> completeSignupOnboarding({
    required String uid,
    required bool optionalMarketingAccepted,
    required bool optionalPushAccepted,
    required String wakeUpTime,
    String? nickname,
  }) async {
    final now = Timestamp.now();
    final updates = <String, dynamic>{
      'requiredServiceTermsAcceptedAt': now,
      'requiredPrivacyTermsAcceptedAt': now,
      'allNotificationsAccepted': true,
      'allNotificationsUpdatedAt': now,
      'optionalMarketingAccepted': optionalMarketingAccepted,
      'optionalMarketingUpdatedAt': now,
      'inAppNotificationsAccepted': true,
      'inAppNotificationsUpdatedAt': now,
      'optionalPushAccepted': optionalPushAccepted,
      'optionalPushUpdatedAt': now,
      'wakeUpTime': wakeUpTime,
    };

    final trimmedNickname = nickname?.trim() ?? '';
    if (trimmedNickname.isNotEmpty) {
      updates['userNickname'] = trimmedNickname;
    }

    await _firestore
        .collection('users')
        .doc(uid)
        .set(updates, SetOptions(merge: true));
  }

  /// TODO: 회원탈퇴 시 30일 유예 기능 도입 시 이 메서드는 사용하지 않음 (서버에서 삭제 처리).
  @override
  Future<void> deleteUserData(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  dynamic _extractResponseData(dynamic rawResponse) {
    final root = _asMap(rawResponse);
    if (!root.containsKey('success')) {
      return root;
    }

    if (root['success'] != true) {
      final message = root['message'] ?? root['error'];
      throw Exception(
        message is String && message.isNotEmpty
            ? message
            : 'User API request failed',
      );
    }
    return root['data'];
  }

  Map<String, dynamic> _extractProfileData(dynamic rawData) {
    final root = _asMap(rawData);
    final profile = root['profile'];
    if (profile == null) return root;
    return _asMap(profile);
  }

  String? _extractUserId(dynamic rawData) {
    final root = _asMap(rawData);
    final userId = root['user_id'] ?? root['uid'];
    if (userId == null || '$userId'.isEmpty) return null;
    return '$userId';
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw Exception('Expected a JSON object response');
  }
}
