import 'package:flutter/cupertino.dart';
import 'ios_colors.dart';

class IosTheme {
  static CupertinoThemeData darkTheme() {
    return const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: IosColors.statusGreen, // MagangHub emerald accent
      primaryContrastingColor: CupertinoColors.black,
      scaffoldBackgroundColor: IosColors.darkBackground,
      barBackgroundColor: Color(0xCC1C1C1E), // Frosted glass translucency
      textTheme: CupertinoTextThemeData(
        primaryColor: CupertinoColors.white,
      ),
    );
  }

  static CupertinoThemeData lightTheme() {
    return const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: IosColors.statusGreen,
      primaryContrastingColor: CupertinoColors.white,
      scaffoldBackgroundColor: IosColors.lightBackground,
      barBackgroundColor: Color(0xCCF8F8F8),
      textTheme: CupertinoTextThemeData(
        primaryColor: CupertinoColors.black,
      ),
    );
  }
}
