import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/terms_urls.dart';
import '../../../../core/widgets/common_app_bar.dart';
import '../../../../core/widgets/common_dialog.dart';
import '../../../../core/widgets/common_time_picker_dialog.dart';
import '../../../../core/widgets/github_grass_loading_indicator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user.dart' as app_user;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/profile_actions_provider.dart';
import '../../../auth/presentation/providers/user_profile_provider.dart';
import '../providers/journal_password_provider.dart';
import 'account_deletion_flow.dart';
import 'secondary_password_page.dart';
import 'terms_webview_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  static const int _mindSyncPercent = 68;
  static const int _pointValue = 120;
  static const String _currentAppVersion = '1.0.0';
  static const String _latestAppVersion = '1.0.0';
  static const double _chevronIconSize = 20;
  static const Color _cardBorderColor = Color(0xFFD9DDE4);

  @override
  Widget build(BuildContext context) {
    final passwordState = ref.watch(journalPasswordProvider);
    final userProfileState = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: const CommonAppBar(title: '설정'),
      body: passwordState.when(
        loading: () => const Center(child: GitHubGrassLoadingIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (password) {
          final hasPassword = password != null;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildProfileSection(userProfileState),
              const SizedBox(height: 24),
              _buildSectionHeader('계정 관리'),

              _buildSimpleTile('로그아웃', onTap: () => _showLogoutDialog(context)),
              _buildSimpleTile(
                '회원 탈퇴',
                onTap: () =>
                    showAccountDeletionFlow(context: context, ref: ref),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('보안 설정'),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '2차 비밀번호(일기장 잠금)',
                  style: TextStyle(fontSize: 16),
                ),
                subtitle: Text(
                  hasPassword ? '사용 중' : '사용 안 함',
                  style: TextStyle(
                    color: hasPassword ? AppTheme.primaryColor : Colors.grey,
                  ),
                ),
                trailing: _buildChevronIcon(),
                onTap: () async {
                  if (hasPassword) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SecondaryPasswordPage(
                          mode: PasswordMode.change,
                        ),
                        fullscreenDialog: true,
                      ),
                    );
                  } else {
                    final success = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SecondaryPasswordPage(
                          mode: PasswordMode.setup,
                        ),
                        fullscreenDialog: true,
                      ),
                    );

                    if (success == true && context.mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => CommonDialog(
                          icon: Icons.lock_outline,
                          title: '2차 비밀번호 설정 완료',
                          description: '2차 비밀번호 설정이 완료됐어요.\n이제 일기를 작성하러 가볼까요?',
                          primaryButtonText: '확인',
                          onPrimaryPressed: () => Navigator.pop(context),
                        ),
                      );
                    }
                  }
                },
              ),

              if (hasPassword)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    '잠금 해제',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                  trailing: _buildChevronIcon(color: Colors.red),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SecondaryPasswordPage(
                          mode: PasswordMode.remove,
                        ),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                ),
              const SizedBox(height: 32),

              _buildSectionHeader('알림 설정'),

              _buildNotificationSettingsSection(userProfileState),

              // 하루 시작 시간 설정
              userProfileState.when(
                data: (user) {
                  final wakeTime = user?.wakeUpTime ?? '07:00';
                  final parts = wakeTime.split(':');
                  final hour = int.tryParse(parts[0]) ?? 7;
                  final minute = parts.length > 1
                      ? (int.tryParse(parts[1]) ?? 0)
                      : 0;
                  final displayTime = TimeOfDay(
                    hour: hour,
                    minute: minute,
                  ).format(context);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      '하루 시작 시간',
                      style: TextStyle(fontSize: 16),
                    ),
                    subtitle: Text(
                      displayTime,
                      style: const TextStyle(color: AppTheme.primaryColor),
                    ),
                    trailing: _buildChevronIcon(),
                    onTap: () async {
                      final picked = await showCommonTimePickerDialog(
                        context: context,
                        initialTime: TimeOfDay(hour: hour, minute: minute),
                        title: '하루 시작 시간을 설정해주세요',
                      );
                      if (picked != null && user != null) {
                        final timeStr =
                            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                        try {
                          await ref
                              .read(profileActionsProvider.notifier)
                              .updateWakeUpTime(uid: user.uid, time: timeStr);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('시간 설정 저장에 실패했어요: $e')),
                          );
                        }
                      }
                    },
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, stackTrace) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('개인 정보 관리'),

              _buildSimpleTile(
                '개인정보 처리방침',
                onTap: () => _openTermsWebView(
                  title: '개인정보 처리방침',
                  url: TermsUrls.privacyPolicy,
                ),
              ),
              _buildSimpleTile(
                '푸시 알림 수신 동의',
                onTap: () => _openTermsWebView(
                  title: '푸시 알림 수신 동의',
                  url: TermsUrls.pushConsent,
                ),
              ),
              _buildSimpleTile(
                '마케팅 정보 수신 동의',
                onTap: () => _openTermsWebView(
                  title: '마케팅 정보 수신 동의',
                  url: TermsUrls.marketingConsent,
                ),
              ),
              _buildSimpleTile(
                '서비스 이용약관',
                onTap: () => _openTermsWebView(
                  title: '서비스 이용약관',
                  url: TermsUrls.termsOfService,
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('고객 지원'),

              _buildSimpleTile('공지사항', onTap: () {}),
              _buildSimpleTile('자주 묻는 질문', onTap: () {}),
              _buildSimpleTile('1:1 문의하기', onTap: _sendEmail),
              _buildSimpleTile('서비스 이용 가이드', trailing: _buildChevronIcon()),

              const SizedBox(height: 24),
              _buildSectionHeader('서비스 정보'),

              _buildAppVersionTile(),
              _buildSimpleTile(
                '오픈소스 및 저작권',
                onTap: () => context.push('/open-source-copyright'),
                trailing: _buildChevronIcon(),
              ),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildProfileSection(AsyncValue<app_user.User?> userProfileState) {
    return userProfileState.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        return _buildProfileCard(
          profileName: _resolveProfileName(user),
          profileImageUrl: _resolveProfileImageUrl(user),
        );
      },
      loading: () => _buildProfileCardPlaceholder(
        child: const GitHubGrassLoadingIndicator(),
      ),
      error: (e, _) => _buildProfileCardPlaceholder(
        child: const Text(
          '프로필 로드 실패',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required String profileName,
    required String? profileImageUrl,
  }) {
    final progress = _mindSyncPercent / 100;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/profile'),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildProfileAvatar(profileImageUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  '마음 동기화율',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              Text(
                                '$_mindSyncPercent%',
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
                              minHeight: 9,
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
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                      size: _chevronIconSize,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildPointSummary(),
        ],
      ),
    );
  }

  Widget _buildProfileCardPlaceholder({required Widget child}) {
    return Container(
      height: 152,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorderColor),
      ),
      child: child,
    );
  }

  Widget _buildProfileAvatar(String? profileImageUrl) {
    final resolvedProfileImageUrl = profileImageUrl?.trim();
    final hasProfileImage =
        resolvedProfileImageUrl != null && resolvedProfileImageUrl.isNotEmpty;

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
                resolvedProfileImageUrl,
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

  Widget _buildAppVersionTile() {
    final updateRequired = _isUpdateRequired(
      currentVersion: _currentAppVersion,
      latestVersion: _latestAppVersion,
    );

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('앱 버전', style: TextStyle(fontSize: 16)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (updateRequired) ...[
              const Text(
                '업데이트 필요',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              '현재버전 $_currentAppVersion · 최신버전 $_latestAppVersion',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
      trailing: _buildVersionStatusChip(updateRequired: updateRequired),
    );
  }

  Widget _buildVersionStatusChip({required bool updateRequired}) {
    final color = updateRequired ? Colors.red : AppTheme.primaryColor;
    final label = updateRequired ? '업데이트' : '최신';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  bool _isUpdateRequired({
    required String currentVersion,
    required String latestVersion,
  }) {
    return _compareVersions(latestVersion, currentVersion) > 0;
  }

  int _compareVersions(String a, String b) {
    final aParts = _parseVersionParts(a);
    final bParts = _parseVersionParts(b);
    final maxLength = aParts.length > bParts.length
        ? aParts.length
        : bParts.length;

    for (var i = 0; i < maxLength; i++) {
      final aPart = i < aParts.length ? aParts[i] : 0;
      final bPart = i < bParts.length ? bParts[i] : 0;
      if (aPart != bPart) {
        return aPart.compareTo(bPart);
      }
    }

    return 0;
  }

  List<int> _parseVersionParts(String version) {
    return version
        .split('.')
        .map((part) => int.tryParse(part.trim()) ?? 0)
        .toList();
  }

  Widget _buildPointSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '보유 포인트',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            '$_pointValue 포인트',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettingsSection(
    AsyncValue<app_user.User?> userProfileState,
  ) {
    return userProfileState.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        return Column(
          children: [
            _buildNotificationSwitch(
              title: '전체 알림 수신 설정',
              value: user.allNotificationsAccepted,
              onChanged: (value) => _updateNotificationSettings(
                user: user,
                allNotificationsAccepted: value,
              ),
            ),
            _buildNotificationSwitch(
              title: '푸시 알림',
              subtitle:
                  '앱 밖에서도 표시되는 알림입니다. 서비스 안내, 콘텐츠 이용기간 임박, 신규 기능 및 업데이트, 앱 장애 안내 등이 표시됩니다.',
              value: user.optionalPushAccepted,
              enabled: user.allNotificationsAccepted,
              onChanged: (value) => _updateNotificationSettings(
                user: user,
                optionalPushAccepted: value,
              ),
            ),
            _buildNotificationSwitch(
              title: '마케팅 알림 수신 동의',
              subtitle: '이벤트, 혜택, 프로모션 관련 마케팅 알림이 푸시와 인앱으로 표시됩니다.',
              value: user.optionalMarketingAccepted,
              enabled: user.allNotificationsAccepted,
              onChanged: (value) => _updateNotificationSettings(
                user: user,
                optionalMarketingAccepted: value,
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildNotificationSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? subtitle,
    bool enabled = true,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      activeThumbColor: AppTheme.primaryColor,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: enabled ? AppTheme.textPrimary : Colors.grey,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: enabled ? AppTheme.textSecondary : Colors.grey,
              ),
            ),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }

  Future<void> _updateNotificationSettings({
    required app_user.User user,
    bool? allNotificationsAccepted,
    bool? optionalPushAccepted,
    bool? optionalMarketingAccepted,
  }) async {
    try {
      await ref
          .read(profileActionsProvider.notifier)
          .updateNotificationSettings(
            uid: user.uid,
            allNotificationsAccepted: allNotificationsAccepted,
            optionalPushAccepted: optionalPushAccepted,
            optionalMarketingAccepted: optionalMarketingAccepted,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('알림 설정 저장에 실패했어요: $e')));
    }
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

  Widget _buildSimpleTile(
    String title, {
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: trailing ?? (onTap == null ? null : _buildChevronIcon()),
      onTap: onTap,
    );
  }

  Widget _buildChevronIcon({Color color = Colors.grey}) {
    return Icon(Icons.chevron_right, color: color, size: _chevronIconSize);
  }

  void _openTermsWebView({required String title, required String url}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TermsWebViewPage(title: title, url: url),
      ),
    );
  }

  Future<void> _sendEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'smallstep.operation@gmail.com',
      query: _encodeQueryParameters(<String, String>{'subject': '1:1 문의하기'}),
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        // Fallback or error handling
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('이메일 앱을 열 수 없습니다.')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (MapEntry<String, String> e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CommonDialog(
        icon: Icons.logout,
        title: '로그아웃 하시겠어요?',
        description: '다시 이용하시려면 로그인이 필요해요.',
        primaryButtonText: '로그아웃',
        onPrimaryPressed: () async {
          final messenger = ScaffoldMessenger.of(this.context);
          Navigator.pop(context); // Dialog 닫기
          try {
            await ref.read(authNotifierProvider.notifier).signOut();
          } catch (e) {
            if (!mounted) return;
            messenger.showSnackBar(SnackBar(content: Text('로그아웃에 실패했어요: $e')));
          }
        },
        secondaryButtonText: '취소',
        onSecondaryPressed: () => Navigator.pop(context),
      ),
    );
  }
}
