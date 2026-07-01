import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/settings/presentation/pages/account_management_page.dart';
import '../../features/settings/presentation/pages/open_source_copyright_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/notifications/presentation/pages/notification_page.dart';
import '../../features/self_tracking/presentation/pages/self_tracking_page.dart';
import '../../features/self_tracking/presentation/pages/self_tracking_streak_page.dart';
import '../../features/shell/presentation/pages/main_shell_page.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/user_profile_provider.dart';
import '../../features/self_tracking/presentation/providers/self_tracking_provider.dart';

part 'app_router.g.dart';

/// GoRouter가 auth 상태 변경 시 redirect를 재평가하도록 하는 Listenable
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });
    ref.listen(userProfileProvider, (previous, next) {
      notifyListeners();
    });
    ref.listen(selfTrackingTodayStatusProvider, (previous, next) {
      notifyListeners();
    });
  }
}

@riverpod
GoRouter appRouter(Ref ref) {
  final authChangeNotifier = _AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authChangeNotifier,
    redirect: (context, state) async {
      // redirect 시점에 최신 auth 상태를 read
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.valueOrNull != null;
      final currentPath = state.uri.toString();
      final isSplash = currentPath == '/splash';
      final isLoggingIn = currentPath == '/login';
      final isSelfTracking = currentPath == '/self-tracking';
      final isOnboarding = currentPath == '/onboarding';

      if (authState.isLoading) return null;

      // 스플래시 화면에서는 리다이렉트 하지 않음 (스플래시가 알아서 이동함)
      if (isSplash) return null;

      if (!isLoggedIn) {
        if (isLoggingIn) return null;
        return '/login';
      }

      // 로그인 상태에서 프로필 로드 후 분기
      User? userProfile;
      try {
        userProfile = await ref.read(userProfileProvider.future);
      } catch (e) {
        debugPrint('[Router] userProfile 로드 실패: $e');
        return null;
      }
      final currentUser = authState.valueOrNull;

      // 방어 로직: Auth UID와 Profile UID가 다르면(아직 로딩 전) 대기
      if (currentUser != null &&
          userProfile != null &&
          userProfile.uid != currentUser.uid) {
        return null; // 리다이렉트 보류 -> userProfileProvider 업데이트 시 다시 호출됨
      }

      final hasRequiredConsents = userProfile?.hasRequiredConsents ?? false;

      // 필수 약관 미동의 상태에서는 온보딩 우선
      if (!hasRequiredConsents && !isOnboarding) {
        debugPrint('[Router] 필수 약관 미동의 → /onboarding');
        return '/onboarding';
      }

      // 온보딩 화면에서는 내부 단계(완료 안내 포함)를 끝까지 진행할 수 있도록
      // 필수 약관 동의 직후 즉시 리다이렉트하지 않는다.
      if (isOnboarding) return null;

      bool hasRecord;
      try {
        final todayStatus = await ref.read(
          selfTrackingTodayStatusProvider.future,
        );
        hasRecord = todayStatus.exists;
      } catch (e) {
        debugPrint('[Router] selfTrackingTodayStatus 로드 실패: $e');
        return null;
      }

      // 로그인 상태에서 /login 접근 시 → 거울속 나 체크
      if (isLoggingIn) {
        debugPrint('[Router] /login → selfTrackingExists=$hasRecord');
        return hasRecord ? '/home' : '/self-tracking';
      }

      if (isSelfTracking && hasRecord) {
        debugPrint('[Router] /self-tracking → selfTrackingExists=$hasRecord');
        return '/home';
      }

      // 로그인 상태에서 /home 접근 시 → 거울속 나 체크
      if (!isSelfTracking && currentPath == '/home') {
        debugPrint('[Router] /home → selfTrackingExists=$hasRecord');
        if (!hasRecord) return '/self-tracking';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const AccountManagementPage(),
      ),
      GoRoute(
        path: '/open-source-copyright',
        builder: (context, state) => const OpenSourceCopyrightPage(),
      ),
      GoRoute(
        path: '/self-tracking',
        builder: (context, state) => const SelfTrackingPage(),
      ),
      GoRoute(
        path: '/self-tracking/streak',
        builder: (context, state) => const SelfTrackingStreakPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainShellPage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationPage(),
      ),
    ],
  );
}
