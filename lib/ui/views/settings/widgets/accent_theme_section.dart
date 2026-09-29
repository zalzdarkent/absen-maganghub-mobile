import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_accent_theme.dart';
import '../../../../core/theme/ios_colors.dart';
import '../../../../core/widgets/ios_card.dart';
import '../../../view_models/settings_view_model.dart';

class AccentThemeSection extends StatelessWidget {
  final SettingsViewModel viewModel;

  const AccentThemeSection({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final isSusanoo = viewModel.isSusanooTheme;
    final currentTheme = viewModel.accentTheme;

    return IosCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: IosColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      CupertinoIcons.paintbrush_fill,
                      size: 16,
                      color: IosColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Tema & Warna Aksen',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: IosColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: IosColors.primary.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: IosColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: IosColors.primary.withValues(alpha: 0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isSusanoo ? 'Susanoo' : 'Emerald',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: IosColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Master Switch Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141416) : const Color(0xFFF9F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Mode Susanoo Sasuke',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? CupertinoColors.white : CupertinoColors.black,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7E22CE), Color(0xFFA855F7)],
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'CHAKRA',
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: CupertinoColors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Aksen ungu khas Susanoo Sasuke (Hitam, Abu, Ungu)',
                        style: TextStyle(
                          fontSize: 12,
                          color: IosColors.secondaryLabel(context),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: isSusanoo,
                  activeTrackColor: const Color(0xFFA855F7),
                  onChanged: (val) {
                    HapticFeedback.mediumImpact();
                    viewModel.setAccentTheme(
                      val ? AccentColorTheme.susanoo : AccentColorTheme.emerald,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Dual Visual Theme Cards Selector
          Row(
            children: [
              // Emerald Option
              Expanded(
                child: _ThemeOptionCard(
                  title: 'Emerald Green',
                  subtitle: 'Hitam • Abu • Hijau',
                  accentColor: const Color(0xFF30D158),
                  isSelected: currentTheme == AccentColorTheme.emerald,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    viewModel.setAccentTheme(AccentColorTheme.emerald);
                  },
                ),
              ),
              const SizedBox(width: 10),
              // Susanoo Option
              Expanded(
                child: _ThemeOptionCard(
                  title: 'Susanoo Purple',
                  subtitle: 'Hitam • Abu • Ungu',
                  accentColor: const Color(0xFFA855F7),
                  isSelected: currentTheme == AccentColorTheme.susanoo,
                  isDark: isDark,
                  badgeText: 'SASUKE',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    viewModel.setAccentTheme(AccentColorTheme.susanoo);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Palette Swatches & Live Preview Demo Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181B) : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E5EA),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Palet Aktif:',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: IosColors.secondaryLabel(context),
                  ),
                ),
                const SizedBox(width: 8),
                // Color dots
                _SwatchDot(color: const Color(0xFF000000), label: 'Hitam', isDark: isDark),
                const SizedBox(width: 6),
                _SwatchDot(color: const Color(0xFF1C1C1E), label: 'Abu-abu', isDark: isDark),
                const SizedBox(width: 6),
                _SwatchDot(color: IosColors.primary, label: isSusanoo ? 'Ungu' : 'Hijau', isDark: isDark, isGlowing: true),
                const Spacer(),
                // Sample Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: IosColors.primary.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: IosColors.primary.withValues(alpha: 0.40),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    isSusanoo ? 'Susanoo UI' : 'Emerald UI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: IosColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool isSelected;
  final bool isDark;
  final String? badgeText;
  final VoidCallback onTap;

  const _ThemeOptionCard({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.isSelected,
    required this.isDark,
    this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? (isSelected ? const Color(0xFF222226) : const Color(0xFF141416))
              : (isSelected ? const Color(0xFFFFFFFF) : const Color(0xFFF9F9FA)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)),
            width: isSelected ? 1.6 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: isDark ? 0.28 : 0.15),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Swatch preview circle
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor,
                        accentColor.withValues(alpha: 0.5),
                        const Color(0xFF000000),
                      ],
                    ),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.45),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: CupertinoColors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                // Checkmark or badge
                if (isSelected)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.checkmark,
                      size: 12,
                      color: CupertinoColors.white,
                    ),
                  )
                else if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badgeText!,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.5,
                color: isSelected
                    ? accentColor
                    : IosColors.secondaryLabel(context),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwatchDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;
  final bool isGlowing;

  const _SwatchDot({
    required this.color,
    required this.label,
    required this.isDark,
    this.isGlowing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFC7C7CC),
          width: 0.8,
        ),
        boxShadow: isGlowing
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 6,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
    );
  }
}
