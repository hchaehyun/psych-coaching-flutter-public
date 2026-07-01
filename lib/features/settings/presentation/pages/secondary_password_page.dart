import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/common_dialog.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/journal_password_provider.dart';

enum PasswordMode {
  setup, // New password (input -> confirm)
  verify, // Check existing password (input once)
  change, // Change password (verify old -> input new -> confirm new)
  remove, // Remove password (verify old -> confirm removal)
}

class SecondaryPasswordPage extends ConsumerStatefulWidget {
  final PasswordMode mode;
  final VoidCallback? onSuccess;

  const SecondaryPasswordPage({super.key, required this.mode, this.onSuccess});

  @override
  ConsumerState<SecondaryPasswordPage> createState() =>
      _SecondaryPasswordPageState();
}

class _SecondaryPasswordPageState extends ConsumerState<SecondaryPasswordPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // State for multi-step flows
  String?
  _firstInput; // Used for setup/change to store the first password entry
  bool _isConfirming =
      false; // True if we are in the "confirm" step of setup/change
  bool _isVerifyingOld =
      false; // True if we are verifying old password before change/remove

  // Display texts
  String _title = '';
  String _description = '';

  @override
  void initState() {
    super.initState();
    _initializeState();

    // Auto-show keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _initializeState() {
    switch (widget.mode) {
      case PasswordMode.setup:
        _title = '2차 비밀번호 설정';
        _description = '사용하시려는 2차 비밀번호 4자리를 설정해주세요.';
        _isConfirming = false;
        break;
      case PasswordMode.verify:
        _title = '비밀번호 입력';
        _description = '현재 비밀번호를 입력해주세요.';
        break;
      case PasswordMode.change:
      case PasswordMode.remove:
        _title = '비밀번호 확인';
        _description = '현재 사용 중인 비밀번호를 입력해주세요.';
        _isVerifyingOld = true;
        break;
    }
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleComplete() async {
    final input = _controller.text;
    if (input.length != 4) return;

    if (_isVerifyingOld || widget.mode == PasswordMode.verify) {
      // Verify Logic
      final notifier = ref.read(journalPasswordProvider.notifier);
      if (notifier.verifyPassword(input)) {
        if (widget.mode == PasswordMode.verify) {
          // Just verifying
          widget.onSuccess?.call();
          if (mounted) context.pop(true);
        } else if (widget.mode == PasswordMode.remove) {
          // Remove Logic
          await notifier.removePassword();
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('비밀번호가 해제되었습니다.')));
            widget.onSuccess?.call();
            context.pop(true);
          }
        } else if (widget.mode == PasswordMode.change) {
          // Proceed to Setup New
          setState(() {
            _isVerifyingOld = false;
            _title = '새 비밀번호 설정';
            _description = '새로운 비밀번호 4자리를 입력해주세요.';
            _controller.clear();
          });
        }
      } else {
        // Fail
        _showError('비밀번호가 일치하지 않습니다.');
        _controller.clear();
      }
      return;
    }

    // Setup or Change (New Password Phase)
    if (!_isConfirming) {
      // First entry of new password
      setState(() {
        _firstInput = input;
        _isConfirming = true;
        _title = '비밀번호 확인';
        _description = '비밀번호를 한 번 더 입력해주세요.';
        _controller.clear();
      });
    } else {
      // Confirmation entry
      if (input == _firstInput) {
        // Success
        await ref.read(journalPasswordProvider.notifier).setPassword(input);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('비밀번호가 설정되었습니다.')));
          widget.onSuccess?.call();
          context.pop(true);
        }
      } else {
        // Mismatch
        _showError('비밀번호가 일치하지 않습니다. 처음부터 다시 시도해주세요.');
        // Reset to first step of setup
        setState(() {
          _isConfirming = false;
          _firstInput = null;
          _title = widget.mode == PasswordMode.setup
              ? '2차 비밀번호 설정'
              : '새 비밀번호 설정';
          _description = '사용하시려는 2차 비밀번호 4자리를 설정해주세요.';
          _controller.clear();
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
    // Shake animation could be added here
  }

  void _handleClose() {
    if (widget.mode == PasswordMode.setup) {
      showDialog(
        context: context,
        builder: (context) => CommonDialog(
          icon: Icons.lock_open,
          title: '아직 2차 비밀번호가\n설정되지 않았어요!',
          description: '설정을 완료하면 일기가 잠금 처리되어\n더 안전하게 보호돼요.',
          primaryButtonText: '2차 비밀번호 설정하기',
          onPrimaryPressed: () => Navigator.pop(context),
          secondaryButtonText: '나중에 하기',
          onSecondaryPressed: () {
            Navigator.pop(context); // Close dialog
            context.pop(); // Close page
          },
        ),
      );
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Hidden TextField for Input
            Opacity(
              opacity: 0.0,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  setState(() {}); // Rebuild UI to update boxes
                  if (value.length == 4) {
                    // Slight delay for visual feedback
                    Future.delayed(
                      const Duration(milliseconds: 100),
                      _handleComplete,
                    );
                  }
                },
              ),
            ),

            Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: _handleClose,
                        icon: const Icon(Icons.close, size: 28),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        _title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Input Boxes
                      GestureDetector(
                        onTap: () => _focusNode.requestFocus(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            final text = _controller.text;
                            final filled = index < text.length;
                            return Container(
                              width: 60,
                              height: 60,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: filled
                                    ? Colors.white
                                    : Colors.transparent,
                                border: Border.all(
                                  color: filled
                                      ? AppTheme.primaryColor
                                      : Colors.grey[400]!,
                                  width: filled ? 2 : 1.5,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: filled
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: filled
                                    ? const Text(
                                        '*',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          height:
                                              1.3, // Adjust for asterisk vertical alignment
                                          color: AppTheme.textPrimary,
                                        ),
                                      )
                                    : null,
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                // Bottom Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 이전 버튼은 두 번째 단계(확인)에서만 표시하거나, 검증 단계가 아닐 때 표시
                      // setup 모드에서는 _isConfirming일 때만 보이도록 함 (첫 화면에선 안보이게)
                      if ((widget.mode == PasswordMode.setup ||
                              widget.mode == PasswordMode.change) &&
                          _isConfirming) ...[
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () {
                            if (_isConfirming &&
                                widget.mode == PasswordMode.setup) {
                              // Go back to input step
                              setState(() {
                                _isConfirming = false;
                                _firstInput = null;
                                _title = '2차 비밀번호 설정';
                                _description = '사용하시려는 2차 비밀번호 4자리를 설정해주세요.';
                                _controller.clear();
                              });
                            } else {
                              context.pop();
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '이전',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Avoid keyboard overlap
                SizedBox(
                  height: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
