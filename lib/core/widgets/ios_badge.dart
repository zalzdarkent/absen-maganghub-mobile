import 'package:flutter/cupertino.dart';
import '../theme/ios_colors.dart';

enum IosBadgeVariant { success, warning, destructive, secondary, outline }

class IosBadge extends StatelessWidget {
  final String label;
  final IosBadgeVariant variant;
  final Widget? leading;
  final bool showDot;

  const IosBadge({
    super.key,
    required this.label,
    this.variant = IosBadgeVariant.secondary,
    this.leading,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    Color? border;
    Color dotColor = IosColors.statusGreen;

    switch (variant) {
      case IosBadgeVariant.success:
        bg = isDark
            ? IosColors.primary.withValues(alpha: 0.16)
            : IosColors.primary.withValues(alpha: 0.12);
        fg = IosColors.primary;
        border = isDark
            ? IosColors.primary.withValues(alpha: 0.32)
            : IosColors.primary.withValues(alpha: 0.22);
        dotColor = IosColors.primary;
        break;
      case IosBadgeVariant.warning:
        bg = isDark ? const Color(0x26FF9F0A) : const Color(0x1FFF9F0A);
        fg = isDark ? const Color(0xFFFF9F0A) : const Color(0xFFC97A00);
        border = isDark ? const Color(0x4DFF9F0A) : const Color(0x33FF9F0A);
        dotColor = const Color(0xFFFF9F0A);
        break;
      case IosBadgeVariant.destructive:
        bg = isDark ? const Color(0x26FF453A) : const Color(0x1FFF453A);
        fg = isDark ? const Color(0xFFFF453A) : const Color(0xFFD70015);
        border = isDark ? const Color(0x4DFF453A) : const Color(0x33FF453A);
        dotColor = const Color(0xFFFF453A);
        break;
      case IosBadgeVariant.outline:
        bg = const Color(0x00000000);
        fg = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);
        border = isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8);
        dotColor = const Color(0xFF8E8E93);
        break;
      case IosBadgeVariant.secondary:
        bg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
        fg = isDark ? const Color(0xFFEBEBF5) : const Color(0xFF1C1C1E);
        border = isDark ? const Color(0xFF38383A) : const Color(0xFFD1D1D6);
        dotColor = const Color(0xFF8E8E93);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
