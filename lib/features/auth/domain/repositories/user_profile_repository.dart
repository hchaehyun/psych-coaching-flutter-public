import '../entities/user.dart';

abstract class UserProfileRepository {
  Stream<User?> watchUserProfile(String uid);

  Stream<String?> watchLoginDeviceId(String uid);

  Future<void> syncUserOnSignIn({
    required String uid,
    required String? email,
    required String? displayName,
    required String? photoUrl,
    required String deviceId,
  });

  Future<void> updateProfile({
    required String uid,
    String? nickname,
    String? profileImageUrl,
  });

  Future<void> updateNickname({required String uid, required String nickname});

  Future<void> deleteNickname(String uid);

  Future<void> updateWakeUpTime({required String uid, required String time});
  Future<void> updateOptionalPushAccepted({
    required String uid,
    required bool accepted,
  });
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
}
