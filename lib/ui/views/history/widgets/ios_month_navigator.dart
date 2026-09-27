import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/ios_colors.dart';
import '../../../view_models/history_view_model.dart';

class IosMonthNavigator extends StatelessWidget {
  final HistoryViewModel viewModel;

  const IosMonthNavigator({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final currentMonth = viewModel.currentMonth;
    final monthTitle = DateFormat('MMMM yyyy', 'id_ID').format(currentMonth);

    // Count entries in this month
    final entries = viewModel.entries ?? [];
    final monthEntriesCount = entries.where((e) {
      final d = e.parseDate();
      if (d == null) return false;
      return d.year == currentMonth.year && d.month == currentMonth.month;
    }).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              monthTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '$monthEntriesCount entri tercatat bulan ini',
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 11,
                color: IosColors.secondaryLabel(context),
              ),
            ),
          ],
        ),

        Row(
          children: [
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(0, 30),
              borderRadius: BorderRadius.circular(15),
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
              onPressed: () => viewModel.previousMonth(),
              child: const Icon(CupertinoIcons.chevron_left, size: 14),
            ),
            const SizedBox(width: 4),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(0, 30),
              borderRadius: BorderRadius.circular(15),
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
              onPressed: () => viewModel.todayMonth(),
              child: Text(
                'Hari Ini',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
            ),
            const SizedBox(width: 4),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(0, 30),
              borderRadius: BorderRadius.circular(15),
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
              onPressed: () => viewModel.nextMonth(),
              child: const Icon(CupertinoIcons.chevron_right, size: 14),
            ),
          ],
        ),
      ],
    );
  }
}
