import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/ios_colors.dart';
import '../view_models/generate_view_model.dart';
import '../view_models/history_view_model.dart';
import '../view_models/settings_view_model.dart';
import 'generate/generate_screen.dart';
import 'history/history_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final GenerateViewModel generateViewModel;
  final HistoryViewModel historyViewModel;
  final SettingsViewModel settingsViewModel;

  const MainNavigationScreen({
    super.key,
    required this.generateViewModel,
    required this.historyViewModel,
    required this.settingsViewModel,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final CupertinoTabController _tabController = CupertinoTabController();

  @override
  void initState() {
    super.initState();
    widget.generateViewModel.init();
    widget.settingsViewModel.init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoTabScaffold(
      controller: _tabController,
      tabBar: CupertinoTabBar(
        backgroundColor: isDark ? const Color(0xE61C1C1E) : const Color(0xE6F8F8F8),
        activeColor: IosColors.statusGreen,
        inactiveColor: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
        iconSize: 22,
        onTap: (index) {
          HapticFeedback.selectionClick();
          if (index == 0) {
            widget.generateViewModel.init();
          } else if (index == 1) {
            widget.historyViewModel.loadEntries();
          } else if (index == 2) {
            widget.settingsViewModel.loadSettings();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.sparkles),
            activeIcon: Icon(CupertinoIcons.sparkles),
            label: 'Generate',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.clock),
            activeIcon: Icon(CupertinoIcons.clock_fill),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.gear_alt),
            activeIcon: Icon(CupertinoIcons.gear_alt_fill),
            label: 'Pengaturan',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return CupertinoTabView(
              builder: (context) => GenerateScreen(
                viewModel: widget.generateViewModel,
                onSaved: () {
                  widget.historyViewModel.loadEntries();
                  _tabController.index = 1;
                },
              ),
            );
          case 1:
            return CupertinoTabView(
              builder: (context) => HistoryScreen(
                viewModel: widget.historyViewModel,
              ),
            );
          case 2:
            return CupertinoTabView(
              builder: (context) => SettingsScreen(
                viewModel: widget.settingsViewModel,
              ),
            );
          default:
            return const SizedBox();
        }
      },
    );
  }
}
