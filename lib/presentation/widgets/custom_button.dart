import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum CustomButtonVariant { primary, outline, text }

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CustomButtonVariant.primary,
    this.icon,
    this.iconAssetPath,
    this.iconColor,
    this.compact = false,
    this.loading = false,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final CustomButtonVariant variant;
  final IconData? icon;
  final String? iconAssetPath;
  final Color? iconColor;
  final bool compact;
  final bool loading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              height: compact ? 28 : 40,
              width: compact ? 28 : 40,
              child: CircularProgressIndicator(
                strokeWidth: compact ? 2.0 : 2.4,
                color: variant == CustomButtonVariant.primary
                    ? Colors.white
                    : AppColors.primary,
              ),
            )
          : Row(
              key: const ValueKey('content'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: compact ? 16 : 18),
                  SizedBox(width: compact ? 6 : 8),
                ] else if (iconAssetPath != null) ...[
                  SizedBox(
                    width: compact ? 18 : 26,
                    height: compact ? 18 : 26,
                    child: Image.asset(
                      iconAssetPath!,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  SizedBox(width: compact ? 6 : 8),
                ],
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: compact
                      ? Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        )
                      : null,
                ),
              ],
            ),
    );

    final Widget button;
    switch (variant) {
      case CustomButtonVariant.primary:
        button = ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: Size.fromHeight(compact ? 44 : 54),
            padding: compact ? const EdgeInsets.symmetric(horizontal: 10) : EdgeInsets.zero,
            backgroundColor: null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Ink(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Container(
              alignment: Alignment.center,
              height: compact ? 44 : 54,
              child: child,
            ),
          ),
        );
        break;
      case CustomButtonVariant.outline:
        button = OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: Size.fromHeight(compact ? 44 : 54),
            padding: compact ? const EdgeInsets.symmetric(horizontal: 10) : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: SizedBox(
            height: compact ? 44 : 54,
            child: Center(child: child),
          ),
        );
        break;
      case CustomButtonVariant.text:
        button = TextButton(
          onPressed: loading ? null : onPressed,
          style: TextButton.styleFrom(
            padding: compact ? const EdgeInsets.symmetric(horizontal: 10) : null,
          ),
          child: SizedBox(
            height: compact ? 44 : 54,
            child: Center(child: child),
          ),
        );
        break;
    }

    if (!fullWidth) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }
}
