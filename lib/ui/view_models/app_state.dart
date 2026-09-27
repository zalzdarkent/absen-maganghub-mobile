import 'package:flutter/cupertino.dart';
import '../../data/repositories/settings_repository.dart';

class AppState extends ChangeNotifier {
  final SettingsRepository settingsRepository;

  String _serverUrl = '';
  int _currentTabIndex = 0;
  int _historyReloadKey = 0;

  AppState({required this.settingsRepository}) {
    _init();
  }

  String get serverUrl => _serverUrl;
  int get currentTabIndex => _currentTabIndex;
  int get historyReloadKey => _historyReloadKey;

  Future<void> _init() async {
    final savedUrl = await settingsRepository.getSavedServerUrl();
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _serverUrl = savedUrl;
    }
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
