import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/device_id_service.dart';

import '../../../../core/widgets/common_bottom_nav_bar.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../journal/presentation/pages/journal_page.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../settings/presentation/pages/settings_page.dart';

import '../../../shopping/presentation/pages/shopping_page.dart';
import '../../../auth/presentation/providers/user_profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/common_dialog.dart';

class MainShellPage extends ConsumerStatefulWidget {
  const MainShellPage({super.key});

  @override
  ConsumerState<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends ConsumerState<MainShellPage> {
  int _currentIndex = MainTab.home.index; // 기본값을 홈(메인)으로 설정
  bool _isHandlingDuplicate = false; // 중복 호출 방지 플래그
  Timer? _delayedCheckTimer;

  void _openBasketTab() {
    setState(() {
      _currentIndex = MainTab.basket.index;
    });
  }

  Future<void> _openNotifications() async {
    await context.push('/notifications');
    if (!mounted) return;

    final unreadCount =
        ref.read(unreadNotificationCountProvider).valueOrNull ?? 0;
    ref.read(dismissedNotificationIndicatorCountProvider.notifier).state =
        unreadCount;
  }

  @override
  void dispose() {
    _delayedCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 중복 로그인 감지: listen만 사용 (watch와 동시 사용하지 않음)
    ref.listen<AsyncValue<String?>>(duplicateLoginDeviceIdProvider, (
      previous,
      next,
    ) {
      debugPrint(
        '[DuplicateLogin] listen fired! previous=$previous, next=$next',
      );
      next.whenData((loginDeviceId) {
        debugPrint(
          '[DuplicateLogin] loginDeviceId changed: firestoreDeviceId=$loginDeviceId',
        );
        if (loginDeviceId != null && !_isHandlingDuplicate) {
          final isInitialLoad = previous == null || previous is AsyncLoading;

          if (isInitialLoad) {
            // 초기 로드: 3초 후 재검사 (signInWithGoogle()이 Firestore에 쓸 시간 확보)
            debugPrint('[DuplicateLogin] 초기 로드 감지 → 3초 후 재검사 예약');
            _delayedCheckTimer?.cancel();
            _delayedCheckTimer = Timer(const Duration(seconds: 3), () {
              _checkDuplicateLogin(loginDeviceId);
            });
          } else {
            // 사용 중 변경: 즉시 검사 (다른 기기에서 로그인한 실시간 감지)
            debugPrint('[DuplicateLogin] 실시간 변경 감지 → 즉시 검사');
            _checkDuplicateLogin(loginDeviceId);
          }
        }
      });
    });

    final pages = [
      HomePage(
        onOpenBasket: _openBasketTab,
        onOpenNotifications: _openNotifications,
      ), // 메인화면
      JournalPage(isActive: _currentIndex == MainTab.journal.index), // 일기
      const ShoppingPage(), // 바구니
      const SettingsPage(), // 설정
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: CommonBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  /// Firestore의 로그인 deviceId와 현재 기기 ID를 비교하여 중복 로그인 감지
  void _checkDuplicateLogin(String loginDeviceId) async {
    if (!mounted || _isHandlingDuplicate) return;

    final currentId = await ref.read(currentDeviceIdProvider.future);
    debugPrint(
      '[DuplicateLogin] 검사: firestoreDeviceId=$loginDeviceId vs currentDeviceId=$currentId',
    );

    if (mounted && loginDeviceId != currentId) {
      debugPrint('[DuplicateLogin] ⚠️ MISMATCH → 강제 로그아웃 팝업');
      _handleDuplicateLogin();
    } else {
      debugPrint('[DuplicateLogin] ✅ MATCH → 정상');
    }
  }

  void _handleDuplicateLogin() async {
    _isHandlingDuplicate = true;
    await showDialog(
      context: context,
      barrierDismissible: false, // 닫기 방지
      builder: (context) => CommonDialog(
        icon: Icons.error_outline,
        title: '다른 기기에서 로그인되었습니다',
        description: '정보 보호를 위해 현재 기기에서 로그아웃합니다.',
        primaryButtonText: '확인',
        onPrimaryPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          Navigator.pop(context);
          try {
            await ref.read(authNotifierProvider.notifier).signOut();
          } catch (e) {
            if (!mounted) return;
            messenger.showSnackBar(SnackBar(content: Text('로그아웃에 실패했어요: $e')));
          } finally {
            _isHandlingDuplicate = false;
          }
        },
      ),
    );
  }
}
