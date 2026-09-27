import 'package:flutter/cupertino.dart';
import '../theme/ios_colors.dart';

class IosCharacterCounter extends StatelessWidget {
  final int count;
  final int minLength;
  final int maxLength;

  const IosCharacterCounter({
    super.key,
    required this.count,
    this.minLength = 100,
    this.maxLength = 5000,
  });

  String get label {
    if (count < minLength) return '$count/$minLength — minimal $minLength';
    if (count > maxLength) return '$count/$maxLength — kepanjangan!';
    return '$count ✓ cukup';
  }

  Color get color {
    if (count < minLength) return IosColors.statusAmber;
    if (count > maxLength) return IosColors.statusRed;
    return IosColors.statusGreen;
  }

  double get progress {
    if (count <= 0) return 0.0;
    return (count / minLength).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final trackBg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Container(
            height: 4,
            color: trackBg,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
