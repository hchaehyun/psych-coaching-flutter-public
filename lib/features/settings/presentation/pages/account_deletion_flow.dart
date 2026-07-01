import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_app_bar.dart';
import '../../../../core/widgets/common_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/user_profile_provider.dart';

Future<void> showAccountDeletionFlow({
  required BuildContext context,
  required WidgetRef ref,
  VoidCallback? onMoveToNotificationSettings,
}) async {
  await Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => _DeleteReasonPage(
        displayName: _resolveAccountDisplayName(ref),
        onDeleteConfirmed: (reason) =>
            _deleteAccount(context: context, ref: ref, deleteReason: reason),
        onMoveToNotificationSettings: onMoveToNotificationSettings ?? () {},
      ),
    ),
  );
}

String _resolveAccountDisplayName(WidgetRef ref) {
  final user = ref.read(userProfileProvider).valueOrNull;
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

Future<void> _deleteAccount({
  required BuildContext context,
  required WidgetRef ref,
  required String deleteReason,
}) async {
  final sanitizedReason = deleteReason.trim();
  if (sanitizedReason.isEmpty) return;

  try {
    // TODO: 탈퇴 사유 수집 API가 추가되면 sanitizedReason을 함께 전달.
    await ref.read(authNotifierProvider.notifier).deleteAccount();
  } catch (e) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => CommonDialog(
        title: '오류 발생',
        description: '탈퇴 처리에 실패했습니다.\n잠시 후 다시 시도해주세요.',
        primaryButtonText: '확인',
        onPrimaryPressed: () => Navigator.pop(context),
      ),
    );
  }
}

class _DeleteReasonPage extends StatefulWidget {
  final String displayName;
  final Future<void> Function(String deleteReason) onDeleteConfirmed;
  final VoidCallback onMoveToNotificationSettings;

  const _DeleteReasonPage({
    required this.displayName,
    required this.onDeleteConfirmed,
    required this.onMoveToNotificationSettings,
  });

  @override
  State<_DeleteReasonPage> createState() => _DeleteReasonPageState();
}

class _DeleteReasonPageState extends State<_DeleteReasonPage> {
  final TextEditingController _reasonController = TextEditingController();

  bool get _canSubmit => _reasonController.text.trim().isNotEmpty;

  Future<void> _showDeletePreventionDialog() async {
    final deleteReason = _reasonController.text.trim();
    if (deleteReason.isEmpty) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DeletePreventionDialog(
        onMoveToNotificationSettings: () {
          Navigator.pop(dialogContext);
          Navigator.pop(context);
          widget.onMoveToNotificationSettings();
        },
        onDeletePressed: () async {
          Navigator.pop(dialogContext);
          await widget.onDeleteConfirmed(deleteReason);
        },
        onCancelPressed: () {
          Navigator.pop(dialogContext);
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '탈퇴하기',
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final reasonFieldHeight = (constraints.maxHeight * 0.42)
                        .clamp(170.0, 320.0);

                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.displayName}님, 정말로 탈퇴하시겠어요?',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '계정을 삭제하면 일기, 진행했던 콘텐츠 기록 등\n모든 활동 정보가 삭제됩니다.',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 36),
                          Text(
                            '${widget.displayName}님이 계정을 탈퇴하려는 이유가 궁금해요.',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: reasonFieldHeight,
                            child: TextField(
                              controller: _reasonController,
                              autofocus: true,
                              expands: true,
                              maxLines: null,
                              minLines: null,
                              textAlignVertical: TextAlignVertical.top,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: '탈퇴 이유를 입력해주세요.',
                                alignLabelWithHint: true,
                                filled: true,
                                fillColor: AppTheme.surfaceColor,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1D1D1D),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _showDeletePreventionDialog : null,
                  child: const Text(
                    '제출',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: Color(0xFF8E8E8E)),
                  ),
                  child: const Text(
                    '취소',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeletePreventionDialog extends StatelessWidget {
  final VoidCallback onMoveToNotificationSettings;
  final VoidCallback onDeletePressed;
  final VoidCallback onCancelPressed;

  const _DeletePreventionDialog({
    required this.onMoveToNotificationSettings,
    required this.onDeletePressed,
    required this.onCancelPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF4D9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFFF3A100),
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '지금 힘든 상태라면,\n탈퇴 대신 잠시 알림을 끄는 것도 방법이에요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '탈퇴하면 모든 데이터는 즉시 삭제되며\n복구할 수 없습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.errorColor,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: onMoveToNotificationSettings,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFE8E8E8),
                  foregroundColor: AppTheme.textPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Color(0xFFD0D0D0)),
                  ),
                ),
                child: const Text(
                  '알림 끄러가기',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onDeletePressed,
                child: const Text(
                  '탈퇴하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: onCancelPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: Color(0xFF8E8E8E)),
                ),
                child: const Text(
                  '취소',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
