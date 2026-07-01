import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 앱의 메인 탭 정의
/// Dart enum은 기본적으로 .index 속성을 제공 (0부터 시작)
enum MainTab {
  home(label: '홈', icon: Icons.home_outlined, selectedIcon: Icons.home),
  journal(label: '일기', icon: Icons.book_outlined, selectedIcon: Icons.book),
  basket(
    label: '바구니',
    icon: Icons.shopping_basket_outlined,
    selectedIcon: Icons.shopping_basket,
  ),
  settings(
    label: '설정',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  );

  const MainTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// 공통 하단 네비게이션 바 컴포넌트
///
/// 사용 예시:
/// ```dart
/// Scaffold(
///   body: _pages[_currentIndex],
///   bottomNavigationBar: CommonBottomNavBar(
///     currentIndex: _currentIndex,
///     onTap: (index) => setState(() => _currentIndex = index),
///   ),
/// )
/// ```
class CommonBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CommonBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: AppTheme.surfaceColor,
      indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.15),
      destinations: MainTab.values.map((tab) {
        return NavigationDestination(
          icon: Icon(tab.icon),
          selectedIcon: Icon(tab.selectedIcon, color: AppTheme.primaryColor),
          label: tab.label,
        );
      }).toList(),
    );
  }
}
