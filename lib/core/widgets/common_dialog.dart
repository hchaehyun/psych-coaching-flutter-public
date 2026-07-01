import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common_button.dart';

class CommonDialog extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String description;
  final String? primaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;

  const CommonDialog({
    super.key,
    this.icon,
    required this.title,
    required this.description,
    this.primaryButtonText,
    this.onPrimaryPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 80, color: AppTheme.primaryColor),
              const SizedBox(height: 24),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            if (primaryButtonText != null && onPrimaryPressed != null)
              CommonButton(
                label: primaryButtonText!,
                onPressed: onPrimaryPressed,
                variant: CommonButtonVariant.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            if (primaryButtonText != null && secondaryButtonText != null)
              const SizedBox(height: 12),
            if (secondaryButtonText != null && onSecondaryPressed != null)
              CommonButton(
                label: secondaryButtonText!,
                onPressed: onSecondaryPressed,
                variant: CommonButtonVariant.secondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
          ],
        ),
      ),
    );
  }
}
