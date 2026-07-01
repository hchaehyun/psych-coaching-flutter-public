import 'package:riverpod/riverpod.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../datasources/user_remote_datasource.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepositoryImpl(ref.watch(userRemoteDataSourceProvider));
});

class UserProfileRepositoryImpl implements UserProfileRepository {
  final UserRemoteDataSource _remoteDataSource;

  UserProfileRepositoryImpl(this._remoteDataSource);

  @override
  Stream<User?> watchUserProfile(String uid) {
    return _remoteDataSource.getUserProfileStream(uid);
  }

  @override
  Stream<String?> watchLoginDeviceId(String uid) {
    return _remoteDataSource.getLoginDeviceIdStream(uid);
  }

  @override
  Future<void> syncUserOnSignIn({
    required String uid,
    required String? email,
    required String? displayName,
    required String? photoUrl,
    required String deviceId,
  }) {
    return _remoteDataSource.createOrUpdateUser(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      deviceId: deviceId,
    );
  }

  @override
  Future<void> updateProfile({
    required String uid,
    String? nickname,
    String? profileImageUrl,
  }) {
    return _remoteDataSource.updateUserProfile(
      uid: uid,
      nickname: nickname,
      profileImageUrl: profileImageUrl,
    );
  }

  @override
  Future<void> updateNickname({required String uid, required String nickname}) {
    return updateProfile(uid: uid, nickname: nickname);
  }

  @override
  Future<void> deleteNickname(String uid) {
    return _remoteDataSource.deleteNickname(uid);
  }

  @override
  Future<void> updateWakeUpTime({required String uid, required String time}) {
    return _remoteDataSource.updateWakeUpTime(uid, time);
  }

  @override
  Future<void> updateOptionalPushAccepted({
    required String uid,
    required bool accepted,
  }) {
    return _remoteDataSource.updateOptionalPushAccepted(uid, accepted);
  }

  @override
  Future<void> updateNotificationSettings({
    required String uid,
    bool? allNotificationsAccepted,
    bool? optionalPushAccepted,
    bool? inAppNotificationsAccepted,
    bool? optionalMarketingAccepted,
  }) {
    return _remoteDataSource.updateNotificationSettings(
      uid: uid,
      allNotificationsAccepted: allNotificationsAccepted,
      optionalPushAccepted: optionalPushAccepted,
      inAppNotificationsAccepted: inAppNotificationsAccepted,
      optionalMarketingAccepted: optionalMarketingAccepted,
    );
  }

  @override
  Future<void> completeSignupOnboarding({
    required String uid,
    required bool optionalMarketingAccepted,
    required bool optionalPushAccepted,
    required String wakeUpTime,
    String? nickname,
  }) {
    return _remoteDataSource.completeSignupOnboarding(
      uid: uid,
      optionalMarketingAccepted: optionalMarketingAccepted,
      optionalPushAccepted: optionalPushAccepted,
      wakeUpTime: wakeUpTime,
      nickname: nickname,
    );
  }
}
