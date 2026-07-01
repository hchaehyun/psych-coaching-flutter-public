class User {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? nickname;
  final String? deviceId;

  /// 하루 시작 시간 (HH:mm 형식, 예: "07:00")
  /// 이 시간을 기준으로 "오늘"의 날짜 경계를 결정한다.
  final String? wakeUpTime;
  final DateTime? requiredServiceTermsAcceptedAt;
  final DateTime? requiredPrivacyTermsAcceptedAt;
  final bool allNotificationsAccepted;
  final DateTime? allNotificationsUpdatedAt;
  final bool optionalMarketingAccepted;
  final DateTime? optionalMarketingUpdatedAt;
  final bool inAppNotificationsAccepted;
  final DateTime? inAppNotificationsUpdatedAt;
  final bool optionalPushAccepted;
  final DateTime? optionalPushUpdatedAt;

  const User({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.nickname,
    this.deviceId,
    this.wakeUpTime,
    this.requiredServiceTermsAcceptedAt,
    this.requiredPrivacyTermsAcceptedAt,
    this.allNotificationsAccepted = true,
    this.allNotificationsUpdatedAt,
    this.optionalMarketingAccepted = false,
    this.optionalMarketingUpdatedAt,
    this.inAppNotificationsAccepted = true,
    this.inAppNotificationsUpdatedAt,
    this.optionalPushAccepted = false,
    this.optionalPushUpdatedAt,
  });

  bool get hasRequiredConsents {
    return requiredServiceTermsAcceptedAt != null &&
        requiredPrivacyTermsAcceptedAt != null;
  }
}
