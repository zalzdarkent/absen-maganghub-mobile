import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/ios_colors.dart';
import '../../../../core/widgets/ios_modal.dart';
import '../../../../core/widgets/ios_toast.dart';
import '../../../../domain/models/logbook_entry_model.dart';
import '../../../view_models/history_view_model.dart';
import 'edit_entry_sheet.dart';

const _weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

class IosCalendarGrid extends StatelessWidget {
  final HistoryViewModel viewModel;

  const IosCalendarGrid({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final currentMonth = viewModel.currentMonth;
    final weeks = viewModel.getMonthMatrix();
    final entriesByDate = viewModel.entriesByDate;

    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    final borderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? IosColors.darkSecondaryBackground : IosColors.lightSecondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // Weekday header
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141416) : const Color(0xFFF9F9FA),
                border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
              ),
              child: Row(
                children: _weekdays.map((wd) {
                  final isWeekend = wd == 'Sab' || wd == 'Min';
                  return Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      child: Text(
                        wd,
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isWeekend ? IosColors.tertiaryLabel(context) : IosColors.secondaryLabel(context),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Weeks grid
            for (int w = 0; w < weeks.length; w++) ...[
              if (w > 0) Container(height: 0.8, color: borderColor),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int d = 0; d < 7; d++) ...[
                    if (d > 0) Container(width: 0.8, height: 78, color: borderColor),
                    Expanded(
                      child: _buildDayCell(
                        context: context,
                        date: weeks[w][d],
                        currentMonth: currentMonth,
                        todayKey: todayKey,
                        entriesByDate: entriesByDate,
                        now: now,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell({
    required BuildContext context,
    required DateTime date,
    required DateTime currentMonth,
    required String todayKey,
    required Map<String, LogbookEntry> entriesByDate,
    required DateTime now,
  }) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final isCurrentMonth = date.month == currentMonth.month && date.year == currentMonth.year;
    final isToday = dateKey == todayKey;
    final isWeekend = date.weekday == 6 || date.weekday == 7;
    final isFuture = date.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59));
    final entry = entriesByDate[dateKey];
    final isMissingWorkday = isCurrentMonth && !isWeekend && !isFuture && !isToday && entry == null;

    Color cellBg;
    if (!isCurrentMonth) {
      cellBg = isDark ? const Color(0x00000000) : const Color(0x0A000000);
    } else if (entry != null) {
      cellBg = isDark ? const Color(0x2230D158) : const Color(0x1830D158);
    } else if (isMissingWorkday) {
      cellBg = isDark ? const Color(0x22FF9F0A) : const Color(0x15FF9F0A);
    } else {
      cellBg = const Color(0x00000000);
    }

    return GestureDetector(
      onTap: () {
        if (entry != null) {
          IosModal.showBottomSheet(
            context: context,
            title: 'Detail Logbook',
            child: EditEntrySheet(entry: entry, viewModel: viewModel),
          );
        } else if (isWeekend) {
          IosToast.show(context, '${DateFormat('d MMMM yyyy', 'id_ID').format(date)} (Akhir pekan)', type: ToastType.info);
        } else if (isMissingWorkday) {
          IosToast.show(context, 'Belum ada entri logbook untuk ${DateFormat('d MMMM', 'id_ID').format(date)}', type: ToastType.warning);
        } else if (!isFuture) {
          IosToast.show(context, 'Belum ada entri pada tanggal ini', type: ToastType.info);
        }
      },
      child: Container(
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        color: cellBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday
                        ? IosColors.statusGreen
                        : (entry != null && isCurrentMonth ? const Color(0x3330D158) : null),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 11,
                      fontWeight: isToday || entry != null ? FontWeight.bold : FontWeight.w500,
                      color: isToday
                          ? CupertinoColors.black
                          : (!isCurrentMonth
                              ? IosColors.tertiaryLabel(context)
                              : (isWeekend ? IosColors.secondaryLabel(context) : null)),
                    ),
                  ),
                ),
                if (entry != null)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: IosColors.statusGreen,
                      shape: BoxShape.circle,
                    ),
                  )
                else if (isMissingWorkday)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: IosColors.statusAmber,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            if (entry != null)
              Expanded(
                child: Text(
                  entry.aktivitas,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF1C1C1E),
                    height: 1.15,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else if (isMissingWorkday)
              Text(
                'Kosong',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 9,
                  color: IosColors.statusAmber.withValues(alpha: 0.8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
