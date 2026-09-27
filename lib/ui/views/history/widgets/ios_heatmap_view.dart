import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/ios_colors.dart';
import '../../../../core/widgets/ios_card.dart';
import '../../../../domain/models/logbook_entry_model.dart';

class IosHeatmapView extends StatelessWidget {
  final List<LogbookEntry> entries;
  final int year;

  const IosHeatmapView({
    super.key,
    required this.entries,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    // Build entry count per date
    final entryDates = <String, int>{};
    for (final e in entries) {
      final parsed = e.parseDate();
      if (parsed != null && parsed.year == year) {
        final key = DateFormat('yyyy-MM-dd').format(parsed);
        entryDates[key] = (entryDates[key] ?? 0) + 1;
      }
    }

    // Generate weekly columns for the last 16 weeks (~4 months) or full year scrollable
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 7 * 18)); // 18 weeks

    final weeks = <List<DateTime>>[];
    var cur = startDate.subtract(Duration(days: startDate.weekday - 1));

    while (cur.isBefore(now.add(const Duration(days: 7)))) {
      final week = <DateTime>[];
      for (int i = 0; i < 7; i++) {
        week.add(cur);
        cur = cur.add(const Duration(days: 1));
      }
      weeks.add(week);
    }

    return IosCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(CupertinoIcons.flame_fill, size: 14, color: IosColors.statusOrange),
                  const SizedBox(width: 6),
                  Text(
                    'Aktivitas Logbook $year',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${entryDates.length} hari aktif',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: IosColors.statusGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: weeks.map((week) {
                return Column(
                  children: week.map((date) {
                    final key = DateFormat('yyyy-MM-dd').format(date);
                    final hasEntry = entryDates.containsKey(key);
                    final isFuture = date.isAfter(now);

                    Color dotColor;
                    if (isFuture) {
                      dotColor = const Color(0x00000000);
                    } else if (hasEntry) {
                      dotColor = IosColors.statusGreen;
                    } else {
                      dotColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
                    }

                    return Container(
                      margin: const EdgeInsets.all(1.8),
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: dotColor,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Kurang',
                style: TextStyle(
                  fontSize: 10,
                  color: IosColors.secondaryLabel(context),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 3),
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: IosColors.statusGreen.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 3),
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: IosColors.statusGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Aktif',
                style: TextStyle(
                  fontSize: 10,
                  color: IosColors.secondaryLabel(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
