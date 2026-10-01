import 'package:flutter/cupertino.dart';
import '../../../../core/theme/ios_colors.dart';
import '../../../../core/widgets/ios_card.dart';
import '../../../../core/widgets/ios_modal.dart';
import '../../../../domain/models/logbook_entry_model.dart';
import '../../../view_models/history_view_model.dart';
import 'edit_entry_sheet.dart';

class IosHistoryListView extends StatelessWidget {
  final HistoryViewModel viewModel;

  const IosHistoryListView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final entries = viewModel.entries ?? [];

    if (entries.isEmpty) {
      return IosCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Column(
          children: [
            Icon(CupertinoIcons.search, size: 36, color: IosColors.tertiaryLabel(context)),
            const SizedBox(height: 10),
            const Text(
              'Belum ada entri logbook',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Buat draft pertama kamu di tab Generate.',
              style: TextStyle(fontSize: 12, color: IosColors.secondaryLabel(context)),
            ),
          ],
        ),
      );
    }

    // Sort descending by rowNumber / date
    final sorted = List<LogbookEntry>.from(entries)..sort((a, b) => b.no.compareTo(a.no));

    return IosCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sorted.length,
        separatorBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(left: 16),
          height: 0.8,
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
        ),
        itemBuilder: (context, index) {
          final entry = sorted[index];
          return CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            onPressed: () {
              IosModal.showBottomSheet(
                context: context,
                title: 'Detail Logbook',
                builder: (modalCtx, scrollController) => EditEntrySheet(
                  entry: entry,
                  viewModel: viewModel,
                  scrollController: scrollController,
                ),
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: IosColors.statusGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#${entry.no}',
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            entry.tanggal,
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${entry.aktivitas.length} char',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 10,
                              color: IosColors.secondaryLabel(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        entry.aktivitas,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (entry.pembelajaran.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Pembelajaran: ${entry.pembelajaran}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: IosColors.secondaryLabel(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: IosColors.tertiaryLabel(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
