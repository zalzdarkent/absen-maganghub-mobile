import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/ios_colors.dart';

class IosNavBarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const IosNavBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

class IosFloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<IosNavBarItem> items;

  const IosFloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bottomMargin = bottomPadding > 0 ? bottomPadding + 4 : 16.0;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: bottomMargin,
      ),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: isDark ? 0.45 : 0.12),
              blurRadius: 28,
              spreadRadius: -2,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: IosColors.statusGreen.withValues(alpha: isDark ? 0.09 : 0.05),
              blurRadius: 18,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xDD18181B)
                    : const Color(0xEEFFFFFF),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.14)
                      : CupertinoColors.black.withValues(alpha: 0.08),
                  width: 0.9,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final tabCount = items.length;
                  final itemWidth = totalWidth / tabCount;

                  return Stack(
                    children: [
                      // Active sliding glowing capsule pill
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        left: selectedIndex * itemWidth,
                        top: 0,
                        bottom: 0,
                        width: itemWidth,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                IosColors.statusGreen.withValues(
                                  alpha: isDark ? 0.20 : 0.15,
                                ),
                                IosColors.statusGreen.withValues(
                                  alpha: isDark ? 0.08 : 0.04,
                                ),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: IosColors.statusGreen.withValues(
                                alpha: isDark ? 0.40 : 0.28,
                              ),
                              width: 0.9,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: IosColors.statusGreen.withValues(
                                  alpha: isDark ? 0.22 : 0.12,
                                ),
                                blurRadius: 10,
                                spreadRadius: -1,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Navigation Items Row
                      Row(
                        children: items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final isSelected = selectedIndex == index;

                          return Expanded(
                            child: _NavBarItemWidget(
                              item: item,
                              isSelected: isSelected,
                              isDark: isDark,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onItemSelected(index);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItemWidget extends StatefulWidget {
  final IosNavBarItem item;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavBarItemWidget({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NavBarItemWidget> createState() => _NavBarItemWidgetState();
}

class _NavBarItemWidgetState extends State<_NavBarItemWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = IosColors.statusGreen;
    final inactiveColor = widget.isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF6C6C70);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed
            ? 0.92
            : (widget.isSelected ? 1.04 : 0.98),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with smooth switch & bounce
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Icon(
                widget.isSelected
                    ? (widget.item.activeIcon ?? widget.item.icon)
                    : widget.item.icon,
                key: ValueKey<String>(
                  '${widget.item.label}_${widget.isSelected}',
                ),
                size: widget.isSelected ? 20 : 19,
                color: widget.isSelected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 3),

            // Label with animated font weight and color
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 10.5,
                fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: widget.isSelected ? -0.2 : -0.1,
                color: widget.isSelected ? activeColor : inactiveColor,
              ),
              child: Text(
                widget.item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Micro neon dot indicator for active tab
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(top: 2),
              width: widget.isSelected ? 3.5 : 0,
              height: widget.isSelected ? 3.5 : 0,
              decoration: BoxDecoration(
                color: widget.isSelected ? activeColor : const Color(0x00000000),
                shape: BoxShape.circle,
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.9),
                          blurRadius: 4,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
