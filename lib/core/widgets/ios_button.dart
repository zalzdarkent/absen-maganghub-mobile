import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../theme/ios_colors.dart';

enum IosButtonVariant { primary, secondary, tinted, outline, destructive }

enum IosButtonSize { small, medium, large }

class IosButton extends StatelessWidget {
  final Widget? child;
  final String? text;
  final Widget? icon;
  final VoidCallback? onPressed;
  final IosButtonVariant variant;
  final IosButtonSize size;
  final bool isLoading;
  final String? loadingText;
  final bool isFullWidth;

  const IosButton({
    super.key,
    this.child,
    this.text,
    this.icon,
    this.onPressed,
    this.variant = IosButtonVariant.primary,
    this.size = IosButtonSize.medium,
    this.isLoading = false,
    this.loadingText,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    Color? border;

    switch (variant) {
      case IosButtonVariant.primary:
        bg = IosColors.primary;
        fg = IosColors.onPrimary;
        break;
      case IosButtonVariant.secondary:
        bg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
        fg = isDark ? CupertinoColors.white : CupertinoColors.black;
        break;
      case IosButtonVariant.tinted:
        bg = isDark
            ? IosColors.primary.withValues(alpha: 0.20)
            : IosColors.primary.withValues(alpha: 0.12);
        fg = IosColors.primary;
        break;
      case IosButtonVariant.outline:
        bg = const Color(0x00000000);
        fg = isDark ? CupertinoColors.white : CupertinoColors.black;
        border = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFC7C7CC);
        break;
      case IosButtonVariant.destructive:
        bg = isDark ? const Color(0x33FF453A) : const Color(0x22FF453A);
        fg = IosColors.statusRed;
        break;
    }

    double height;
    double fontSize;
    EdgeInsets padding;
    double radius;

    switch (size) {
      case IosButtonSize.small:
        height = 32;
        fontSize = 12;
        padding = const EdgeInsets.symmetric(horizontal: 12);
        radius = 16;
        break;
      case IosButtonSize.medium:
        height = 42;
        fontSize = 14;
        padding = const EdgeInsets.symmetric(horizontal: 18);
        radius = 21;
        break;
      case IosButtonSize.large:
        height = 50;
        fontSize = 16;
        padding = const EdgeInsets.symmetric(horizontal: 24);
        radius = 25;
        break;
    }

    final isActuallyDisabled = onPressed == null && !isLoading;

    Color buttonDisabledColor;
    if (isLoading) {
      if (variant == IosButtonVariant.outline) {
        buttonDisabledColor = const Color(0x00000000);
      } else {
        buttonDisabledColor = bg.withValues(alpha: 0.88);
      }
    } else {
      buttonDisabledColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    }

    return SizedBox(
      height: height,
      width: isFullWidth ? double.infinity : null,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(radius),
        color: bg,
        disabledColor: buttonDisabledColor,
        pressedOpacity: 0.65,
        onPressed: (isActuallyDisabled || isLoading)
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed?.call();
              },
        child: Container(
          padding: padding,
          alignment: Alignment.center,
          decoration: border != null
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(color: border, width: 1.0),
                )
              : null,
          child: isLoading
              ? Row(
                  mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CupertinoActivityIndicator(
                      color: fg,
                      radius: size == IosButtonSize.small ? 7 : (size == IosButtonSize.medium ? 9 : 10),
                    ),
                    if (loadingText != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        loadingText!,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: fg,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ],
                )
              : Row(
                  mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      IconTheme(
                        data: IconThemeData(color: fg, size: fontSize + 3),
                        child: icon!,
                      ),
                      if (text != null || child != null) const SizedBox(width: 6),
                    ],
                    if (text != null)
                      Text(
                        text!,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: isActuallyDisabled
                              ? (isDark ? const Color(0xFF636366) : const Color(0xFFAEAEC2))
                              : fg,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ?child,
                  ],
                ),
        ),
      ),
    );
  }
}
