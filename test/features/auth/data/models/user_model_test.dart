import 'package:flutter_test/flutter_test.dart';
import 'package:psych_coaching_flutter/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel.fromFirestore', () {
    test('parses the existing Firestore field names', () {
      final acceptedAt = DateTime.utc(2026, 1, 2, 3, 4, 5);

      final user = UserModel.fromFirestore({
        'uid': 'user-1',
        'userEmail': 'user@example.com',
        'userName': 'User Name',
        'userNickname': 'Coach',
        'profileImageUrl': 'https://example.com/profile.jpg',
        'lastLoginDeviceId': 'device-1',
        'wakeUpTime': '08:30',
        'requiredServiceTermsAcceptedAt': acceptedAt.millisecondsSinceEpoch,
        'requiredPrivacyTermsAcceptedAt': acceptedAt.toIso8601String(),
        'allNotificationsAccepted': false,
        'optionalMarketingAccepted': true,
        'inAppNotificationsAccepted': false,
        'optionalPushAccepted': true,
      });

      expect(user.uid, 'user-1');
      expect(user.email, 'user@example.com');
      expect(user.displayName, 'User Name');
      expect(user.nickname, 'Coach');
      expect(user.photoUrl, 'https://example.com/profile.jpg');
      expect(user.deviceId, 'device-1');
      expect(user.wakeUpTime, '08:30');
      expect(user.requiredServiceTermsAcceptedAt, isNotNull);
      expect(user.requiredPrivacyTermsAcceptedAt, acceptedAt);
      expect(user.allNotificationsAccepted, isFalse);
      expect(user.optionalMarketingAccepted, isTrue);
      expect(user.inAppNotificationsAccepted, isFalse);
      expect(user.optionalPushAccepted, isTrue);
    });

    test('parses the profile object returned by GET /users', () {
      final response = {
        'user_id': 'C9YcMzrwxTc8s4CuULfLIK5LO213',
        'profile': {
          'admin': true,
          'allNotificationsAccepted': true,
          'allNotificationsUpdatedAt': '2026-06-11T06:51:57.378892Z',
          'createdAt': '2026-03-20T07:32:41.809Z',
          'inAppNotificationsAccepted': true,
          'inAppNotificationsUpdatedAt': '2026-06-11T06:51:58.938371Z',
          'lastLoginDeviceId': 'a6bb1bb4-755a-4de3-a64c-bae372c46a5b',
          'optionalMarketingAccepted': true,
          'optionalMarketingUpdatedAt': '2026-03-20T07:34:57.821402Z',
          'optionalPushAccepted': true,
          'optionalPushUpdatedAt': '2026-04-23T12:50:48.911655Z',
          'profileImageUrl': 'https://example.com/profile.jpg',
          'requiredPrivacyTermsAcceptedAt': '2026-03-20T07:34:57.821402Z',
          'requiredServiceTermsAcceptedAt': '2026-03-20T07:34:57.821402Z',
          'uid': 'C9YcMzrwxTc8s4CuULfLIK5LO213',
          'userEmail': 'hchaehyuninfit@gmail.com',
          'userName': '채현',
          'userNickname': '',
          'wakeUpTime': '09:00',
        },
      };
      final profile = Map<String, dynamic>.from(response['profile']! as Map);

      final user = UserModel.fromFirestore(profile);

      expect(user.uid, response['user_id']);
      expect(user.email, 'hchaehyuninfit@gmail.com');
      expect(user.displayName, '채현');
      expect(user.nickname, '');
      expect(user.photoUrl, 'https://example.com/profile.jpg');
      expect(user.deviceId, 'a6bb1bb4-755a-4de3-a64c-bae372c46a5b');
      expect(user.wakeUpTime, '09:00');
      expect(user.allNotificationsAccepted, isTrue);
      expect(
        user.allNotificationsUpdatedAt,
        DateTime.parse('2026-06-11T06:51:57.378892Z'),
      );
      expect(user.optionalMarketingAccepted, isTrue);
      expect(user.inAppNotificationsAccepted, isTrue);
      expect(user.optionalPushAccepted, isTrue);
      expect(
        user.requiredPrivacyTermsAcceptedAt,
        DateTime.parse('2026-03-20T07:34:57.821402Z'),
      );
    });
  });
}
