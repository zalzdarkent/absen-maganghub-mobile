import 'package:flutter/cupertino.dart';
import '../../core/theme/app_accent_theme.dart';
import '../../core/theme/ios_colors.dart';
import '../../data/repositories/settings_repository.dart';

class AppState extends ChangeNotifier {
  final SettingsRepository settingsRepository;

  String _serverUrl = '';
  int _currentTabIndex = 0;
  int _historyReloadKey = 0;
  AccentColorTheme _accentTheme = AccentColorTheme.emerald;

  AppState({required this.settingsRepository}) {
    _init();
  }

  String get serverUrl => _serverUrl;
  int get currentTabIndex => _currentTabIndex;
  int get historyReloadKey => _historyReloadKey;
  AccentColorTheme get accentTheme => _accentTheme;

  Future<void> _init() async {
    final savedUrl = await settingsRepository.getSavedServerUrl();
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _serverUrl = savedUrl;
    }
    final savedThemeStr = await settingsRepository.getAccentTheme();
    _accentTheme = AccentColorThemeExtension.fromString(savedThemeStr);
    IosColors.setAccentTheme(_accentTheme);
    notifyListeners();
  }

  Future<void> setAccentTheme(AccentColorTheme theme) async {
    if (_accentTheme == theme) return;
    _accentTheme = theme;
    IosColors.setAccentTheme(theme);
    await settingsRepository.setAccentTheme(theme.name);
    notifyListeners();
  }

  void setTabIndex(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  void notifyHistoryChanged() {
    _historyReloadKey++;
    notifyListeners();
  }

  Future<void> updateServerUrl(String newUrl) async {
    _serverUrl = newUrl;
    await settingsRepository.setSavedServerUrl(newUrl);
    notifyListeners();
  }
}
