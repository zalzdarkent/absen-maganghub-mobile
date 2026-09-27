import 'package:flutter/cupertino.dart';

class IosColors {
  // Apple System Tint Colors
  static const Color systemBlue = CupertinoColors.systemBlue;
  static const Color systemGreen = CupertinoColors.systemGreen;
  static const Color systemIndigo = CupertinoColors.systemIndigo;
  static const Color systemOrange = CupertinoColors.systemOrange;
  static const Color systemPink = CupertinoColors.systemPink;
  static const Color systemPurple = CupertinoColors.systemPurple;
  static const Color systemRed = CupertinoColors.systemRed;
  static const Color systemTeal = CupertinoColors.systemTeal;
  static const Color systemYellow = CupertinoColors.systemYellow;

  // Custom MagangHub Apple Dark Tones
  static const Color darkBackground = Color(0xFF000000); // Pure Apple OLED black
  static const Color darkSecondaryBackground = Color(0xFF1C1C1E); // Apple system card
  static const Color darkTertiaryBackground = Color(0xFF2C2C2E); // Elevated card / modal
  static const Color darkGroupedBackground = Color(0xFF0D1117); // Sleek subtle abyss
  static const Color darkSeparator = Color(0xFF38383A);
  static const Color darkBorder = Color(0xFF24303C);

  // Light Tones
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSecondaryBackground = Color(0xFFFFFFFF);
  static const Color lightTertiaryBackground = Color(0xFFE5E5EA);
  static const Color lightSeparator = Color(0xFFC6C6C8);

  // Status Colors
  static const Color statusGreen = Color(0xFF30D158);
  static const Color statusAmber = Color(0xFFFF9F0A);
  static const Color statusOrange = Color(0xFFFF9500);
  static const Color statusRed = Color(0xFFFF453A);
  static const Color statusBlue = Color(0xFF0A84FF);

  static Color background(BuildContext context) {
    return CupertinoTheme.of(context).brightness == Brightness.dark
        ? darkBackground
        : lightBackground;
  }

  static Color card(BuildContext context) {
    return CupertinoTheme.of(context).brightness == Brightness.dark
        ? darkSecondaryBackground
        : lightSecondaryBackground;
  }

  static Color cardElevated(BuildContext context) {
    return CupertinoTheme.of(context).brightness == Brightness.dark
        ? darkTertiaryBackground
        : lightSecondaryBackground;
  }

  static Color separator(BuildContext context) {
    return CupertinoTheme.of(context).brightness == Brightness.dark
        ? darkSeparator
        : lightSeparator;
  }

  static Color label(BuildContext context) {
    return CupertinoColors.label.resolveFrom(context);
  }

  static Color secondaryLabel(BuildContext context) {
    return CupertinoColors.secondaryLabel.resolveFrom(context);
  }

  static Color tertiaryLabel(BuildContext context) {
    return CupertinoColors.tertiaryLabel.resolveFrom(context);
  }
}
