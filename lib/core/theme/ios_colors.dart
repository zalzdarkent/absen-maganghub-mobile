import 'package:flutter/cupertino.dart';
import 'app_accent_theme.dart';

class IosColors {
  // Dynamic Accent Theme State
  static final ValueNotifier<AccentColorTheme> accentThemeNotifier =
      ValueNotifier<AccentColorTheme>(AccentColorTheme.emerald);

  static AccentColorTheme get currentTheme => accentThemeNotifier.value;
  static bool get isSusanoo => currentTheme == AccentColorTheme.susanoo;

  static void setAccentTheme(AccentColorTheme theme) {
    if (accentThemeNotifier.value != theme) {
      accentThemeNotifier.value = theme;
    }
  }

  // Dynamic Theme Colors
  static Color get primary => currentTheme.primary;
  static Color get onPrimary => currentTheme.onPrimary;
  static Color get primaryLight => currentTheme.primaryLight;
  static Color get primaryDark => currentTheme.primaryDark;
  static List<Color> get avatarGradient => currentTheme.avatarGradient;
  static List<Color> get squircleGradient => currentTheme.squircleGradient;

  // Backwards-compatible statusGreen getter mapped to the active accent color
  static Color get statusGreen => primary;

  // Static reference colors
  static const Color pureGreen = Color(0xFF30D158);
  static const Color susanooPurple = Color(0xFFA855F7);

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
