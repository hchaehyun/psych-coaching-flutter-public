import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 공통 앱바 컴포넌트
///
/// 사용 예시:
/// ```dart
/// Scaffold(
///   appBar: CommonAppBar(
///     title: '페이지 제목',
///     showBackButton: true,
///     actions: [
///       IconButton(icon: Icon(Icons.settings), onPressed: () {}),
///     ],
///   ),
///   body: ...,
/// )
/// ```
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final VoidCallback? onBackPressed;

  const CommonAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: _titleStyle),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? AppTheme.surfaceColor,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : leading,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  static const TextStyle _titleStyle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 18,
  );
}
