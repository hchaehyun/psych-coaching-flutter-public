import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/terms_urls.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_time_picker_dialog.dart';
import '../../../../core/widgets/github_grass_loading_indicator.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/profile_actions_provider.dart';
import '../../../settings/presentation/pages/terms_webview_page.dart';

enum _PermissionGuideType { phone, camera, photos }

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final TextEditingController _nicknameController = TextEditingController();

  int _stepIndex = 0;
  bool _isSubmitting = false;
  bool _isRequestingPermissions = false;

  bool _requiredServiceAccepted = false;
  bool _requiredPrivacyAccepted = false;
  bool _optionalMarketingAccepted = false;
  bool _optionalPushAccepted = false;

  PermissionStatus? _cameraPermissionStatus;
  PermissionStatus? _photosPermissionStatus;

  TimeOfDay _wakeUpTime = const TimeOfDay(hour: 7, minute: 0);

  @override
  void initState() {
    super.initState();
    _refreshPermissionStatuses();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  bool get _isAllAccepted {
    return _requiredServiceAccepted &&
        _requiredPrivacyAccepted &&
        _optionalMarketingAccepted &&
        _optionalPushAccepted;
  }

  bool get _hasRequiredTerms {
    return _requiredServiceAccepted && _requiredPrivacyAccepted;
  }

  String get _trimmedNickname => _nicknameController.text.trim();

  String get _wakeUpTimeText {
    final hour = _wakeUpTime.hour.toString().padLeft(2, '0');
    final minute = _wakeUpTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _onPrevious() async {
    if (_stepIndex == 0) {
      try {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (!mounted) return;
        context.go('/login');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('로그아웃에 실패했어요: $e')));
      }
      return;
    }

    setState(() {
      _stepIndex -= 1;
    });
  }

  void _onNext() {
    setState(() {
      _stepIndex += 1;
    });
  }

  Future<void> _pickWakeUpTime() async {
    final picked = await showCommonTimePickerDialog(
      context: context,
      initialTime: _wakeUpTime,
      title: '알림 받을 시간을 설정해주세요',
    );
    if (picked == null) return;

    setState(() {
      _wakeUpTime = picked;
    });
  }

  Future<void> _refreshPermissionStatuses() async {
    final cameraStatus = await Permission.camera.status;
    final photosStatus = await Permission.photos.status;
    if (!mounted) return;

    setState(() {
      _cameraPermissionStatus = cameraStatus;
      _photosPermissionStatus = photosStatus;
    });
  }

  bool _isPermissionGranted(PermissionStatus? status) {
    if (status == null) return false;
    return status.isGranted || status.isLimited;
  }

  bool _needsSettings(PermissionStatus? status) {
    if (status == null) return false;
    return status.isPermanentlyDenied || status.isRestricted;
  }

  PermissionStatus? _permissionStatusFor(_PermissionGuideType type) {
    switch (type) {
      case _PermissionGuideType.phone:
        return null;
      case _PermissionGuideType.camera:
        return _cameraPermissionStatus;
      case _PermissionGuideType.photos:
        return _photosPermissionStatus;
    }
  }

  Permission? _permissionFor(_PermissionGuideType type) {
    switch (type) {
      case _PermissionGuideType.phone:
        return null;
      case _PermissionGuideType.camera:
        return Permission.camera;
      case _PermissionGuideType.photos:
        return Permission.photos;
    }
  }

  String _permissionTitleFor(_PermissionGuideType type) {
    switch (type) {
      case _PermissionGuideType.phone:
        return '전화 연결';
      case _PermissionGuideType.camera:
        return '카메라';
      case _PermissionGuideType.photos:
        return '사진 접근';
    }
  }

  String _permissionBadgeLabelFor(_PermissionGuideType type) {
    if (type == _PermissionGuideType.phone) return '안내';

    final status = _permissionStatusFor(type);
    if (_isPermissionGranted(status)) return '허용됨';
    if (_needsSettings(status)) return '설정';
    return '선택';
  }

  void _showPermissionMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<PermissionStatus?> _requestPermission(
    _PermissionGuideType type, {
    bool openSettingsOnBlocked = false,
    bool showFeedback = false,
  }) async {
    final permission = _permissionFor(type);
    if (permission == null) return null;

    final currentStatus = await permission.status;
    if (_isPermissionGranted(currentStatus)) {
      await _refreshPermissionStatuses();
      return currentStatus;
    }

    if (_needsSettings(currentStatus)) {
      await _refreshPermissionStatuses();

      if (showFeedback) {
        _showPermissionMessage(
          '${_permissionTitleFor(type)} 권한은 기기 설정에서 변경할 수 있어요.',
        );
      }

      if (openSettingsOnBlocked) {
        final opened = await openAppSettings();
        if (!opened) {
          _showPermissionMessage('설정 앱을 열 수 없어요.');
        }
      }
      return currentStatus;
    }

    final result = await permission.request();
    await _refreshPermissionStatuses();

    if (showFeedback && !_isPermissionGranted(result)) {
      _showPermissionMessage(
        '${_permissionTitleFor(type)} 권한은 나중에 기기 설정에서 변경할 수 있어요.',
      );
    }

    return result;
  }

  Future<void> _requestSignupPermissionsAndProceed() async {
    if (_isRequestingPermissions) return;

    setState(() {
      _isRequestingPermissions = true;
    });

    try {
      await _requestPermission(_PermissionGuideType.camera);
      await _requestPermission(_PermissionGuideType.photos);

      if (!mounted) return;
      _onNext();
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingPermissions = false;
        });
      }
    }
  }

  Future<void> _onPermissionTilePressed(_PermissionGuideType type) async {
    if (type == _PermissionGuideType.phone) {
      _showPermissionMessage('전화 연결은 위기 상황 시 전화 앱으로 이동하며 별도 권한 요청은 없어요.');
      return;
    }

    await _requestPermission(
      type,
      openSettingsOnBlocked: true,
      showFeedback: true,
    );
  }

  Future<void> _submitOnboarding() async {
    final currentUser = ref.read(authStateProvider).valueOrNull;
    if (currentUser == null) {
      if (!mounted) return;
      context.go('/login');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(profileActionsProvider.notifier)
          .completeSignupOnboarding(
            uid: currentUser.uid,
            optionalMarketingAccepted: _optionalMarketingAccepted,
            optionalPushAccepted: _optionalPushAccepted,
            wakeUpTime: _wakeUpTimeText,
            nickname: _trimmedNickname.isEmpty ? null : _trimmedNickname,
          );

      if (!mounted) return;
      setState(() {
        _stepIndex = 4;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('회원가입 정보를 저장하지 못했어요: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _toggleAllTerms(bool value) {
    setState(() {
      _requiredServiceAccepted = value;
      _requiredPrivacyAccepted = value;
      _optionalMarketingAccepted = value;
      _optionalPushAccepted = value;
    });
  }

  void _updateConsent({required bool value, required String key}) {
    setState(() {
      switch (key) {
        case 'required_service':
          _requiredServiceAccepted = value;
          break;
        case 'required_privacy':
          _requiredPrivacyAccepted = value;
          break;
        case 'optional_marketing':
          _optionalMarketingAccepted = value;
          break;
        case 'optional_push':
          _optionalPushAccepted = value;
          break;
      }
    });
  }

  Widget _buildConsentTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isRequired = false,
    String? detailUrl,
    String? detailTitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Checkbox(
            value: value,
            onChanged: (nextValue) => onChanged(nextValue ?? false),
            shape: const CircleBorder(),
            activeColor: AppTheme.primaryColor,
          ),
          title: Text(
            isRequired ? '(필수) $title' : title,
            style: const TextStyle(fontSize: 15),
          ),
          trailing: detailUrl == null
              ? null
              : IconButton(
                  onPressed: () => _openTermsWebView(
                    title: detailTitle ?? title,
                    url: detailUrl,
                  ),
                  icon: Icon(Icons.chevron_right, color: Colors.grey[600]),
                ),
          onTap: detailUrl == null
              ? () => onChanged(!value)
              : () => _openTermsWebView(
                  title: detailTitle ?? title,
                  url: detailUrl,
                ),
        ),
      ],
    );
  }

  void _openTermsWebView({required String title, required String url}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TermsWebViewPage(title: title, url: url),
      ),
    );
  }

  Widget _buildTermsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '약관 동의',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '서비스 이용을 위해 약관 동의를 진행해주세요.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        _buildConsentTile(
          title: '약관 전체 동의',
          value: _isAllAccepted,
          onChanged: _toggleAllTerms,
        ),
        const Divider(height: 16),
        _buildConsentTile(
          title: '서비스 이용약관에 동의합니다',
          value: _requiredServiceAccepted,
          onChanged: (value) =>
              _updateConsent(value: value, key: 'required_service'),
          isRequired: true,
          detailTitle: '서비스 이용약관',
          detailUrl: TermsUrls.termsOfService,
        ),
        _buildConsentTile(
          title: '개인정보처리방침에 동의합니다',
          value: _requiredPrivacyAccepted,
          onChanged: (value) =>
              _updateConsent(value: value, key: 'required_privacy'),
          isRequired: true,
          detailTitle: '개인정보처리방침',
          detailUrl: TermsUrls.privacyPolicy,
        ),
        _buildConsentTile(
          title: '마케팅 정보 수신에 동의합니다',
          value: _optionalMarketingAccepted,
          onChanged: (value) =>
              _updateConsent(value: value, key: 'optional_marketing'),
          detailTitle: '마케팅 정보 수신 약관',
          detailUrl: TermsUrls.marketingConsent,
        ),
        _buildConsentTile(
          title: '푸시 알림 수신에 동의합니다',
          value: _optionalPushAccepted,
          onChanged: (value) =>
              _updateConsent(value: value, key: 'optional_push'),
          detailTitle: '푸시 알림 수신 약관',
          detailUrl: TermsUrls.pushConsent,
        ),
      ],
    );
  }

  Widget _buildNicknameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '닉네임 설정',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '사용할 닉네임을 입력해주세요.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _nicknameController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: '닉네임을 입력해주세요',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionGuideStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '권한 안내',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '작은결은 서비스 이용에 꼭 필요한 권한만 요청합니다. \n알림, 사진/카메라 등 선택 건한은 해당 기능을 사용할 때만 요청되며, \n동의하지 않아도 기본 기능은 이용할 수 있어요. \n권한은 언제든지 기기 설정에서 변경할 수 있습니다.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          _buildPermissionSectionTitle('필수 기능 안내'),
          const SizedBox(height: 12),
          _buildPermissionTile(
            type: _PermissionGuideType.phone,
            icon: Icons.call_outlined,
            title: '전화',
            description: '위기 상황 시 자살예방상담전화(109)로 연결을 도와드립니다.',
          ),
          const SizedBox(height: 24),
          _buildPermissionSectionTitle('선택 접근 권한'),
          const SizedBox(height: 12),
          _buildPermissionTile(
            type: _PermissionGuideType.camera,
            icon: Icons.photo_camera_outlined,
            title: '카메라',
            description: '실시간 사진 미션 수행 또는 일기 작성 시 사진 촬영을 위해 필요합니다.',
          ),
          const SizedBox(height: 12),
          _buildPermissionTile(
            type: _PermissionGuideType.photos,
            icon: Icons.photo_library_outlined,
            title: '사진',
            description: '실시간 사진 미션 수행 또는 일기 작성 시 사진 첨부를 위해 필요합니다.',
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '카메라와 사진 접근 권한은 허용하지 않아도 가입을 계속할 수 있어요. 필요한 시점에 다시 안내드릴 수 있습니다.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppTheme.primaryColor,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildPermissionTile({
    required _PermissionGuideType type,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return GestureDetector(
      onTap: () => _onPermissionTilePressed(type),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _permissionBadgeLabelFor(type),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWakeUpTimeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '알림 시간 설정',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '하루 시작 알림을 받을 시간을 설정해주세요.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          title: const Text('하루 시작 시간'),
          subtitle: Text(
            _wakeUpTime.format(context),
            style: const TextStyle(color: AppTheme.primaryColor),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: _pickWakeUpTime,
        ),
      ],
    );
  }

  Widget _buildCompleteStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppTheme.primaryColor,
            size: 72,
          ),
          const SizedBox(height: 24),
          Text(
            '만나서 반가워요!',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            '이제 작은결을 시작해볼까요?',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('시작하기'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_stepIndex) {
      case 0:
        return _buildTermsStep();
      case 1:
        return _buildPermissionGuideStep();
      case 2:
        return _buildNicknameStep();
      case 3:
        return _buildWakeUpTimeStep();
      default:
        return _buildCompleteStep();
    }
  }

  String _primaryButtonLabel() {
    if (_stepIndex == 2 && _trimmedNickname.isEmpty) {
      return '설정하지 않고 다음';
    }
    return '다음';
  }

  bool _canProceed() {
    if (_stepIndex == 0) return _hasRequiredTerms;
    if (_stepIndex == 1) return !_isRequestingPermissions;
    if (_stepIndex == 3) return !_isSubmitting;
    return true;
  }

  Future<void> _onPrimaryPressed() async {
    if (_stepIndex == 1) {
      await _requestSignupPermissionsAndProceed();
      return;
    }
    if (_stepIndex == 3) {
      await _submitOnboarding();
      return;
    }
    _onNext();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    if (authState.isLoading) {
      return const Scaffold(body: Center(child: GitHubGrassLoadingIndicator()));
    }

    if (user == null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('로그인이 필요해요.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('로그인으로 이동'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final showBottomButtons = _stepIndex < 4;
    final isBusy = _isSubmitting || _isRequestingPermissions;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showBottomButtons) ...[
                Text(
                  '${_stepIndex + 1} / 5',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 8),
              ],
              Expanded(child: _buildStepBody()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: showBottomButtons
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _canProceed() ? _onPrimaryPressed : null,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _primaryButtonLabel(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: isBusy ? null : _onPrevious,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '이전',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
