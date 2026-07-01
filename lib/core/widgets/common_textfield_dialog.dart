import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// TextField 입력이 필요한 다이얼로그 공통 컴포넌트.
///
/// 사용 예:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => CommonTextFieldDialog(
///     title: '새 루틴 추가',
///     hintText: '예: 물 한 잔 마시기',
///     primaryButtonText: '추가',
///     onSubmitted: (value) { ... },
///   ),
/// );
/// ```
class CommonTextFieldDialog extends StatefulWidget {
  final IconData? icon;
  final String title;
  final String? description;
  final String? hintText;
  final String? initialValue;
  final String primaryButtonText;
  final String secondaryButtonText;

  /// 입력값 검증 함수. null을 반환하면 유효, 문자열을 반환하면 에러 메시지.
  final String? Function(String)? validator;

  /// 제출 콜백. 입력값이 전달됨.
  final void Function(String value) onSubmitted;

  const CommonTextFieldDialog({
    super.key,
    this.icon,
    required this.title,
    this.description,
    this.hintText,
    this.initialValue,
    this.primaryButtonText = '확인',
    this.secondaryButtonText = '취소',
    this.validator,
    required this.onSubmitted,
  });

  @override
  State<CommonTextFieldDialog> createState() => _CommonTextFieldDialogState();
}

class _CommonTextFieldDialogState extends State<CommonTextFieldDialog> {
  late final TextEditingController _controller;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    // validator가 없으면 빈 문자열이 아닌 한 유효
    _isValid = _checkValidity(_controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _checkValidity(String value) {
    if (widget.validator != null) {
      return widget.validator!(value) == null;
    }
    return value.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 48, color: AppTheme.primaryColor),
              const SizedBox(height: 16),
            ],
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            if (widget.description != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _isValid = _checkValidity(value);
                });
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.secondaryButtonText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isValid
                        ? () {
                            Navigator.pop(context);
                            widget.onSubmitted(_controller.text);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.primaryButtonText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
