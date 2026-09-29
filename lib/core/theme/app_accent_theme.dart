import 'package:flutter/cupertino.dart';

enum AccentColorTheme {
  emerald,
  susanoo,
}

extension AccentColorThemeExtension on AccentColorTheme {
  String get id => name;

  String get title {
    switch (this) {
      case AccentColorTheme.emerald:
        return 'Emerald Green';
      case AccentColorTheme.susanoo:
        return 'Susanoo Sasuke';
    }
  }

  String get subtitle {
    switch (this) {
      case AccentColorTheme.emerald:
        return 'Hitam • Abu • Hijau';
      case AccentColorTheme.susanoo:
        return 'Hitam • Abu • Ungu Sasuke';
    }
  }

  Color get primary {
    switch (this) {
      case AccentColorTheme.emerald:
        return const Color(0xFF30D158);
      case AccentColorTheme.susanoo:
        // Glowing electric Susanoo chakra purple
        return const Color(0xFFA855F7);
    }
  }

  Color get onPrimary {
    switch (this) {
      case AccentColorTheme.emerald:
        return CupertinoColors.black;
      case AccentColorTheme.susanoo:
        return CupertinoColors.white;
    }
  }

  Color get primaryLight {
    switch (this) {
      case AccentColorTheme.emerald:
        return const Color(0xFF69F0AE);
      case AccentColorTheme.susanoo:
        return const Color(0xFFC084FC);
    }
  }

  Color get primaryDark {
    switch (this) {
      case AccentColorTheme.emerald:
        return const Color(0xFF00C853);
      case AccentColorTheme.susanoo:
        return const Color(0xFF7E22CE);
    }
  }

  List<Color> get avatarGradient {
    switch (this) {
      case AccentColorTheme.emerald:
        return const [Color(0xFF1E2922), Color(0xFF0F1511)];
      case AccentColorTheme.susanoo:
        return const [Color(0xFF26123D), Color(0xFF12081E)];
    }
  }

  List<Color> get squircleGradient {
    switch (this) {
      case AccentColorTheme.emerald:
        return const [
          Color(0xFF1E2922),
          Color(0xFF0F1511),
          Color(0xFF080C0A),
        ];
      case AccentColorTheme.susanoo:
        return const [
          Color(0xFF2B1342),
          Color(0xFF150921),
          Color(0xFF0C0514),
        ];
    }
  }

  static AccentColorTheme fromString(String? val) {
    if (val == 'susanoo') return AccentColorTheme.susanoo;
    return AccentColorTheme.emerald;
  }
}
