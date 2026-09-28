import 'package:flutter/cupertino.dart';
import '../../../core/theme/ios_colors.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/generate_view_model.dart';
import '../view_models/history_view_model.dart';
import '../view_models/settings_view_model.dart';
import 'auth/auth_screen.dart';
import 'generate/generate_screen.dart';
import 'history/history_screen.dart';
import 'settings/settings_screen.dart';
import 'widgets/ios_floating_nav_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  final GenerateViewModel generateViewModel;
  final HistoryViewModel historyViewModel;
  final SettingsViewModel settingsViewModel;
  final AuthViewModel authViewModel;
  final VoidCallback? onLoggedOut;

  const MainNavigationScreen({
    super.key,
    required this.generateViewModel,
    required this.historyViewModel,
    required this.settingsViewModel,
    required this.authViewModel,
    this.onLoggedOut,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late final PageController _pageController;
  int _selectedIndex = 0;

  static const List<IosNavBarItem> _navItems = [
    IosNavBarItem(
      icon: CupertinoIcons.sparkles,
      activeIcon: CupertinoIcons.sparkles,
      label: 'Generate',
    ),
    IosNavBarItem(
      icon: CupertinoIcons.clock,
      activeIcon: CupertinoIcons.clock_fill,
      label: 'Riwayat',
    ),
    IosNavBarItem(
      icon: CupertinoIcons.gear_alt,
      activeIcon: CupertinoIcons.gear_alt_fill,
      label: 'Pengaturan',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    widget.generateViewModel.init();
    widget.historyViewModel.loadEntries();
    widget.settingsViewModel.init();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_selectedIndex == index) {
      if (index == 0) {
        widget.generateViewModel.init();
      } else if (index == 1) {
        widget.historyViewModel.loadEntries();
      } else if (index == 2) {
        widget.settingsViewModel.loadSettings();
      }
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );

    if (index == 0) {
      widget.generateViewModel.init();
    } else if (index == 1) {
      widget.historyViewModel.loadEntries();
    } else if (index == 2) {
      widget.settingsViewModel.loadSettings();
    }
  }

  void _handleLogout() {
    widget.onLoggedOut?.call();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, anim, secAnim) => AuthScreen(
          authViewModel: widget.authViewModel,
          generateViewModel: widget.generateViewModel,
          historyViewModel: widget.historyViewModel,
          settingsViewModel: widget.settingsViewModel,
        ),
        transitionsBuilder: (context, anim, secAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: IosColors.darkBackground,
      child: Stack(
        children: [
          // Smooth Animated Page View with state preservation
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _KeepAliveTab(
                  child: GenerateScreen(
                    viewModel: widget.generateViewModel,
                    onSaved: () {
                      widget.historyViewModel.loadEntries();
                      _onTabSelected(1);
                    },
                  ),
                ),
                _KeepAliveTab(
                  child: HistoryScreen(
                    viewModel: widget.historyViewModel,
                  ),
                ),
                _KeepAliveTab(
                  child: SettingsScreen(
                    viewModel: widget.settingsViewModel,
                    authViewModel: widget.authViewModel,
                    onLoggedOut: _handleLogout,
                  ),
                ),
              ],
            ),
          ),

          // Floating Aesthetic Glassmorphic Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IosFloatingNavBar(
              selectedIndex: _selectedIndex,
              onItemSelected: _onTabSelected,
              items: _navItems,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeepAliveTab extends StatefulWidget {
  final Widget child;
  const _KeepAliveTab({required this.child});

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
