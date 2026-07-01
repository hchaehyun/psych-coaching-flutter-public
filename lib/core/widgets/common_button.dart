import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum CommonButtonVariant { primary, secondary }

class CommonButton extends StatelessWidget {
  const CommonButton({
    super.key,
    this.label,
    this.child,
    required this.onPressed,
    this.variant = CommonButtonVariant.primary,
    this.padding,
    this.textStyle,
    this.width,
    this.height,
  }) : assert(label != null || child != null);

  final String? label;
  final Widget? child;
  final VoidCallback? onPressed;
  final CommonButtonVariant variant;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final button = switch (variant) {
      CommonButtonVariant.primary => ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            child ??
            Text(
              label!,
              style:
                  textStyle ??
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
      ),
      CommonButtonVariant.secondary => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey[600],
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            child ??
            Text(
              label!,
              style:
                  textStyle ??
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
      ),
    };

    if (width == null && height == null) {
      return button;
    }

    return SizedBox(width: width, height: height, child: button);
  }
}
