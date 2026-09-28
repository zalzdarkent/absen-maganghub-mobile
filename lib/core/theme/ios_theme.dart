import 'package:flutter/cupertino.dart';
import 'ios_colors.dart';

class IosTheme {
  static CupertinoThemeData darkTheme() {
    return CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: IosColors.primary,
      primaryContrastingColor: IosColors.onPrimary,
      scaffoldBackgroundColor: IosColors.darkBackground,
      barBackgroundColor: const Color(0xCC1C1C1E), // Frosted glass translucency
      textTheme: const CupertinoTextThemeData(
        primaryColor: CupertinoColors.white,
      ),
    );
  }

  static CupertinoThemeData lightTheme() {
    return CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: IosColors.primary,
      primaryContrastingColor: IosColors.onPrimary,
      scaffoldBackgroundColor: IosColors.lightBackground,
      barBackgroundColor: const Color(0xCCF8F8F8),
      textTheme: const CupertinoTextThemeData(
        primaryColor: CupertinoColors.black,
      ),
    );
  }
}
