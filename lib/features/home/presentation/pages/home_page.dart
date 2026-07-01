import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_button.dart';
import '../../../auth/domain/entities/user.dart' as app_user;
import '../../../auth/presentation/providers/user_profile_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';

class _ParticipatingContentItem {
  _ParticipatingContentItem({
    required this.id,
    required this.title,
    required this.tags,
    required this.icon,
  }) : isCompleted = false;

  final String id;
  final String title;
  final List<String> tags;
  final IconData icon;
  bool isCompleted;
}

class _MyChangeStatItem {
  const _MyChangeStatItem({
    required this.assetPath,
    required this.value,
    required this.label,
  });

  final String assetPath;
  final String value;
  final String label;
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({
    super.key,
    required this.onOpenBasket,
    required this.onOpenNotifications,
  });

  final VoidCallback onOpenBasket;
  final VoidCallback onOpenNotifications;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const int _pointValue = 120;
  static const int _discoveryScore = 68;
  static const int _discoveryLevel = 3;
  static const Color _cardBorderColor = Color(0xFFD9DDE4);
  static const Color _completedCardColor = Color(0xFFE7EEF8);

  static const List<_MyChangeStatItem> _myChangeStats = [
    _MyChangeStatItem(
      assetPath: 'assets/images/free-icon-notebook-9564703.png',
      value: '100일',
      label: '출석일수',
    ),
    _MyChangeStatItem(
      assetPath: 'assets/images/free-icon-time-9564719.png',
      value: '78회',
      label: '총 활동 수',
    ),
    _MyChangeStatItem(
      assetPath: 'assets/images/free-icon-book-9564615.png',
      value: '50회',
      label: '일기 작성',
    ),
  ];

  final List<_ParticipatingContentItem> _participatingContents = [
    _ParticipatingContentItem(
      id: '1',
      title: '오늘의 나 발견하러 가기',
      tags: ['셀프탐색', '오늘질문', '마음체크'],
      icon: Icons.favorite_border_rounded,
    ),
    _ParticipatingContentItem(
      id: '2',
      title: '마음에 남은 발자국 확인하기',
      tags: ['회고', '감정흔적'],
      icon: Icons.psychology_alt_outlined,
    ),
    _ParticipatingContentItem(
      id: '3',
      title: '일기쓰기',
      tags: ['기록습관', '감정정리', '하루마무리', '성장노트'],
      icon: Icons.edit_outlined,
    ),
    _ParticipatingContentItem(
      id: '4',
      title: '감정 기록하기',
      tags: ['감정일지', '패턴확인', '자기이해'],
      icon: Icons.auto_awesome_outlined,
    ),
  ];

  void _onReorderItem(int oldIndex, int newIndex) {
    final itemCount = _participatingContents.length;
    if (oldIndex >= itemCount || newIndex >= itemCount) return;

    setState(() {
      final movedItem = _participatingContents.removeAt(oldIndex);
      _participatingContents.insert(newIndex, movedItem);
    });
  }

  void _toggleContentCompleted(String id, bool isCompleted) {
    setState(() {
      final index = _participatingContents.indexWhere((item) => item.id == id);
      if (index == -1) return;
      _participatingContents[index].isCompleted = isCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final heroHeight = (height * 0.42).clamp(240.0, 360.0);
    final progress = _discoveryScore / 100;
    final user = ref.watch(userProfileProvider).valueOrNull;
    final profileName = _resolveProfileName(user);
    final profileImageUrl = _resolveProfileImageUrl(user);
    final showNotificationDot = ref.watch(notificationIndicatorVisibleProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: _buildHeroAndProfile(
                      heroHeight,
                      progress,
                      profileName: profileName,
                      profileImageUrl: profileImageUrl,
                      showNotificationDot: showNotificationDot,
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedTabBarDelegate(
                    TabBar(
                      labelColor: AppTheme.primaryColor,
                      unselectedLabelColor: AppTheme.textSecondary,
                      indicatorColor: AppTheme.primaryColor,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: const [
                        Tab(text: '참여중인 콘텐츠'),
                        Tab(text: '나의 변화'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: [_buildParticipatingTab(), _buildMyChangeTab()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundActionButton({
    IconData? icon,
    String? assetPath,
    required String tooltip,
    required String label,
    int badgeCount = 0,
    bool showBadgeDot = false,
    VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onPressed ?? () {},
                constraints: const BoxConstraints.tightFor(
                  width: 44,
                  height: 44,
                ),
                padding: EdgeInsets.zero,
                icon: assetPath != null
                    ? Image.asset(
                        assetPath,
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                      )
                    : Icon(icon, color: AppTheme.textPrimary, size: 36),
              ),
              if (showBadgeDot)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                )
              else if (badgeCount > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppTheme.errorColor,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.all(Radius.circular(9)),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // 알림, 상점, 꾸미기
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroAndProfile(
    double heroHeight,
    double progress, {
    required String profileName,
    required String? profileImageUrl,
    required bool showNotificationDot,
  }) {
    final characterTopOffset = (heroHeight * 0.25).clamp(48.0, 84.0);

    return SizedBox(
      height: heroHeight + 132,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: characterTopOffset),
              child: Image.asset(
                'assets/images/alien_stay.png',
                height: heroHeight * 0.8,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(top: 0, left: 0, child: _buildPointBadge()),
          Positioned(
            top: 0,
            right: 0,
            child: Column(
              children: [
                _buildRoundActionButton(
                  assetPath: 'assets/images/free-icon-bells-17979527.png',
                  tooltip: '알림',
                  label: '알림',
                  showBadgeDot: showNotificationDot,
                  onPressed: widget.onOpenNotifications,
                ),
                const SizedBox(height: 10),
                _buildRoundActionButton(
                  assetPath: 'assets/images/free-icon-jewelry-17979558.png',
                  tooltip: '상점 이동',
                  label: '상점',
                ),
                const SizedBox(height: 10),
                _buildRoundActionButton(
                  assetPath: 'assets/images/free-icon-suit-17979605.png',
                  tooltip: '꾸미기 이동',
                  label: '꾸미기',
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _cardBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileAvatar(profileImageUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profileName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              '레벨$_discoveryLevel 마음 발견자',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$_discoveryScore%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            value: progress,
                            backgroundColor: AppTheme.primaryColor.withValues(
                              alpha: 0.15,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorderColor),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.favorite_rounded,
            size: 18,
            color: Color(0xFFE06A84),
          ),
          const SizedBox(width: 8),
          Text(
            '$_pointValue 포인트',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(String? profileImageUrl) {
    final hasProfileImage =
        profileImageUrl != null && profileImageUrl.trim().isNotEmpty;

    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.4),
          width: 2,
        ),
        color: const Color(0xFFE8EEF8),
      ),
      child: ClipOval(
        child: hasProfileImage
            ? Image.network(
                profileImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person_outline_rounded,
                    size: 36,
                    color: AppTheme.primaryColor,
                  );
                },
              )
            : const Icon(
                Icons.person_outline_rounded,
                size: 36,
                color: AppTheme.primaryColor,
              ),
      ),
    );
  }

  String _resolveProfileName(app_user.User? user) {
    if (user == null) return '회원';

    final nickname = user.nickname?.trim();
    if (nickname != null && nickname.isNotEmpty) {
      return nickname;
    }

    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    return '회원';
  }

  String? _resolveProfileImageUrl(app_user.User? user) {
    final url = user?.photoUrl?.trim();
    if (url == null || url.isEmpty) {
      return null;
    }
    return url;
  }

  Widget _buildParticipatingTab() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: _participatingContents.length + 1,
      onReorderItem: _onReorderItem,
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        if (index == _participatingContents.length) {
          return Container(
            key: const ValueKey('browse-more-contents'),
            alignment: Alignment.center,
            padding: const EdgeInsets.only(top: 8),
            child: CommonButton(
              label: '더 많은 콘텐츠 둘러보기 ->',
              onPressed: widget.onOpenBasket,
              variant: CommonButtonVariant.secondary,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          );
        }

        final item = _participatingContents[index];
        final isCompleted = item.isCompleted;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          key: ValueKey(item.id),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isCompleted ? _completedCardColor : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.reorder_rounded,
                      color: AppTheme.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                _buildContentStateButton(item: item, isCompleted: isCompleted),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: item.tags
                            .map((tag) => _buildTagChip(tag))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isCompleted ? '진행 완료' : '시작하기',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isCompleted
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContentStateButton({
    required _ParticipatingContentItem item,
    required bool isCompleted,
  }) {
    return Semantics(
      checked: isCompleted,
      button: true,
      label: '${item.title} ${isCompleted ? '진행 완료' : '시작하기'}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _toggleContentCompleted(item.id, !isCompleted),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isCompleted ? _completedCardColor : AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCompleted
                    ? const Color(0xFFC7D4E7)
                    : const Color(0xFFD8DEE8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                isCompleted ? Icons.check_rounded : item.icon,
                size: isCompleted ? 30 : 24,
                color: isCompleted
                    ? AppTheme.primaryColor
                    : AppTheme.textPrimary.withValues(alpha: 0.88),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4FA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '#$tag',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMyChangeTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/free-icon-profit-9564754.png',
              width: 52,
              height: 52,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                '지금까지 나에게 일어난 변화를\n확인해보세요.',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _myChangeStats.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: _buildMyChangeStatCard(_myChangeStats[i])),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMyChangeStatCard(_MyChangeStatItem item) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Center(
              child: Image.asset(
                item.assetPath,
                width: 42,
                height: 42,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            item.value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedTabBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppTheme.surfaceColor,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedTabBarDelegate oldDelegate) {
    return false;
  }
}
