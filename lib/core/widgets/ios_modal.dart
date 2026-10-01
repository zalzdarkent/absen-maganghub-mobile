import 'package:flutter/cupertino.dart';
import '../theme/ios_colors.dart';

class IosModal {
  static Future<T?> showBottomSheet<T>({
    required BuildContext context,
    Widget? child,
    Widget Function(BuildContext context, ScrollController scrollController)? builder,
    String? title,
    Widget? trailing,
    bool isDismissible = true,
    double initialChildSize = 0.85,
    double minChildSize = 0.4,
    double maxChildSize = 0.95,
  }) {
    assert(child != null || builder != null, 'Either child or builder must be provided');
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final bg = isDark ? IosColors.darkSecondaryBackground : IosColors.lightSecondaryBackground;

    return showCupertinoModalPopup<T>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: initialChildSize,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    // Drag Handle Bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 8),
                        width: 36,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    if (title != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.4,
                              ),
                            ),
                            if (trailing != null)
                              trailing
                            else
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  'Tutup',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: IosColors.statusGreen,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        height: 0.8,
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                      ),
                    ],
                    Expanded(
                      child: builder != null ? builder(context, scrollController) : child!,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
