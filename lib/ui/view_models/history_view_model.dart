import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/repositories/logbook_repository.dart';
import '../../domain/models/logbook_entry_model.dart';
import '../../domain/models/recap_model.dart';

class HistoryViewModel extends ChangeNotifier {
  final LogbookRepository logbookRepository;

  HistoryViewModel({required this.logbookRepository});

  List<LogbookEntry>? _entries;
  bool _isLoading = false;
  String? _errorMessage;

  String _viewMode = 'calendar'; // 'calendar' | 'list'
  DateTime _currentMonth = DateTime.now();

  bool _isExporting = false;

  RecapModel? _recap;
  String? _recapLoadingPeriod; // 'weekly' | 'monthly' | null
  double _recapElapsed = 0.0;
  Timer? _recapTimer;
  int _recapStartTime = 0;

  // Getters
  List<LogbookEntry>? get entries => _entries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get viewMode => _viewMode;
  DateTime get currentMonth => _currentMonth;
  bool get isExporting => _isExporting;
  RecapModel? get recap => _recap;
  String? get recapLoadingPeriod => _recapLoadingPeriod;
  double get recapElapsed => _recapElapsed;

  void setViewMode(String mode) {
    if (_viewMode != mode) {
      _viewMode = mode;
      notifyListeners();
    }
  }

  void previousMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    notifyListeners();
  }

  void nextMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    notifyListeners();
  }

  void todayMonth() {
    _currentMonth = DateTime.now();
    notifyListeners();
  }

  Map<String, LogbookEntry> get entriesByDate {
    final map = <String, LogbookEntry>{};
    if (_entries == null) return map;
    for (final e in _entries!) {
      final parsed = e.parseDate();
      if (parsed != null) {
        final key = DateFormat('yyyy-MM-dd').format(parsed);
        map[key] = e;
      }
    }
    return map;
  }

  /// Builds a 7x5 or 7x6 calendar matrix (Monday to Sunday)
  List<List<DateTime>> getMonthMatrix() {
    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    // Monday is weekday 1 in Dart, Sunday is 7
    final firstWeekday = firstDay.weekday; // 1 = Mon, 7 = Sun
    final startDate = firstDay.subtract(Duration(days: firstWeekday - 1));

    final weeks = <List<DateTime>>[];
    var current = startDate;

    while (current.isBefore(lastDay) || weeks.isEmpty || current.month == month) {
      final week = <DateTime>[];
      for (int i = 0; i < 7; i++) {
        week.add(current);
        current = current.add(const Duration(days: 1));
      }
      weeks.add(week);
      if (current.month != month && weeks.length >= 4) {
        break;
      }
    }
    return weeks;
  }

  Future<void> loadEntries() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await logbookRepository.fetchEntries();
      _entries = list;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateEntry(int rowNumber, DraftFields draft) async {
    await logbookRepository.updateEntry(rowNumber, draft);
    await loadEntries();
  }

  Future<void> deleteEntry(int rowNumber) async {
    await logbookRepository.deleteEntry(rowNumber);
    await loadEntries();
  }

  Future<void> exportExcel() async {
    _isExporting = true;
    notifyListeners();

    try {
      final bytes = await logbookRepository.exportExcel();
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        final now = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
        final file = File('${dir.path}/Logbook_MagangHub_$now.xlsx');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
          text: 'Logbook MagangHub Kemnaker (Excel)',
        );
      }
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<void> generateRecap(String period) async {
    _recapLoadingPeriod = period;
    _recapElapsed = 0.0;
    _recapStartTime = DateTime.now().millisecondsSinceEpoch;
    _recapTimer?.cancel();

    _recapTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      _recapElapsed = (DateTime.now().millisecondsSinceEpoch - _recapStartTime) / 1000.0;
      notifyListeners();
    });
    notifyListeners();

    try {
      final res = await logbookRepository.generateRecap(period);
      _recap = res;
    } finally {
      _recapLoadingPeriod = null;
      _recapTimer?.cancel();
      _recapTimer = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _recapTimer?.cancel();
    super.dispose();
  }
}
