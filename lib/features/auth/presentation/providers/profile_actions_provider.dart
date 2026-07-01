import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../di/auth_di.dart';
import 'user_profile_provider.dart';

part 'profile_actions_provider.g.dart';

/// 유저 프로필 관련 write-side 액션을 관리하는 Provider
/// Presentation Layer에서 Repository를 직접 호출하지 않도록 중간 계층 역할
@riverpod
class ProfileActions extends _$ProfileActions {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncValue.loading();
    try {
      await action();
      ref.invalidate(userProfileProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String uid,
    String? nickname,
    String? profileImageUrl,
  }) async {
    await _run(() {
      return ref
          .read(appUserProfileRepositoryProvider)
          .updateProfile(
            uid: uid,
            nickname: nickname,
            profileImageUrl: profileImageUrl,
          );
    });
  }

  Future<void> updateNickname({
    required String uid,
    required String nickname,
  }) async {
    await updateProfile(uid: uid, nickname: nickname);
  }

  Future<void> updateProfileImageUrl({
    required String uid,
    required String profileImageUrl,
  }) async {
    await updateProfile(uid: uid, profileImageUrl: profileImageUrl);
  }

  Future<void> deleteNickname(String uid) async {
    await _run(() {
      return ref.read(appUserProfileRepositoryProvider).deleteNickname(uid);
    });
  }

  Future<void> updateWakeUpTime({
    required String uid,
    required String time,
  }) async {
    await _run(() {
      return ref
          .read(appUserProfileRepositoryProvider)
          .updateWakeUpTime(uid: uid, time: time);
    });
  }

  Future<void> updateOptionalPushAccepted({
    required String uid,
    required bool accepted,
  }) async {
    await updateNotificationSettings(uid: uid, optionalPushAccepted: accepted);
  }

  Future<void> updateNotificationSettings({
    required String uid,
    bool? allNotificationsAccepted,
    bool? optionalPushAccepted,
    bool? inAppNotificationsAccepted,
    bool? optionalMarketingAccepted,
  }) async {
    await _run(() {
      return ref
          .read(appUserProfileRepositoryProvider)
          .updateNotificationSettings(
            uid: uid,
            allNotificationsAccepted: allNotificationsAccepted,
            optionalPushAccepted: optionalPushAccepted,
            inAppNotificationsAccepted: inAppNotificationsAccepted,
            optionalMarketingAccepted: optionalMarketingAccepted,
          );
    });
  }

  Future<void> completeSignupOnboarding({
    required String uid,
    required bool optionalMarketingAccepted,
    required bool optionalPushAccepted,
    required String wakeUpTime,
    String? nickname,
  }) async {
    await _run(() {
      return ref
          .read(appUserProfileRepositoryProvider)
          .completeSignupOnboarding(
            uid: uid,
            optionalMarketingAccepted: optionalMarketingAccepted,
            optionalPushAccepted: optionalPushAccepted,
            wakeUpTime: wakeUpTime,
            nickname: nickname,
          );
    });
  }
}
