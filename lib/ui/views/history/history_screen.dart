import 'package:flutter/cupertino.dart';
import '../../../../core/theme/ios_colors.dart';
import '../../../../core/widgets/ios_badge.dart';
import '../../../../core/widgets/ios_toast.dart';
import '../../view_models/history_view_model.dart';
import 'widgets/ai_recap_section.dart';
import 'widgets/ios_calendar_grid.dart';
import 'widgets/ios_heatmap_view.dart';
import 'widgets/ios_history_list_view.dart';
import 'widgets/ios_month_navigator.dart';

class HistoryScreen extends StatefulWidget {
  final HistoryViewModel viewModel;

  const HistoryScreen({super.key, required this.viewModel});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final entries = vm.entries ?? [];
        final count = entries.length;
        final viewMode = vm.viewMode;
        final isLoading = vm.isLoading;

        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    CupertinoIcons.clock_fill,
                    size: 15,
                    color: IosColors.statusGreen,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Riwayat Logbook',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (count > 0)
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(0, 28),
                    borderRadius: BorderRadius.circular(14),
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                    onPressed: vm.isExporting
                        ? null
                        : () async {
                            try {
                              await vm.exportExcel();
                              if (context.mounted) {
                                IosToast.show(context, 'File Excel siap di-share!', type: ToastType.success);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                IosToast.show(context, e.toString(), type: ToastType.error);
                              }
                            }
                          },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (vm.isExporting)
                          const CupertinoActivityIndicator(radius: 6)
                        else
                          const Icon(CupertinoIcons.arrow_down_doc_fill, size: 12, color: IosColors.statusGreen),
                        const SizedBox(width: 4),
                        Text(
                          vm.isExporting ? 'Ekspor…' : 'Excel',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? CupertinoColors.white : CupertinoColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                IosBadge(
                  label: '$count entri',
                  variant: IosBadgeVariant.secondary,
                ),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () => vm.loadEntries(),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // View Mode Switcher (Cupertino Sliding Segmented Control)
                        Center(
                          child: CupertinoSlidingSegmentedControl<String>(
                            groupValue: viewMode,
                            children: const {
                              'calendar': Padding(
                                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(CupertinoIcons.calendar, size: 14),
                                    SizedBox(width: 6),
                                    Text('Kalender', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              'list': Padding(
                                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(CupertinoIcons.list_bullet, size: 14),
                                    SizedBox(width: 6),
                                    Text('Daftar', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            },
                            onValueChanged: (val) {
                              if (val != null) vm.setViewMode(val);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (isLoading && vm.entries == null)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: CupertinoActivityIndicator(radius: 14),
                            ),
                          )
                        else if (viewMode == 'calendar') ...[
                          IosMonthNavigator(viewModel: vm),
                          const SizedBox(height: 12),
                          IosCalendarGrid(viewModel: vm),
                          const SizedBox(height: 16),
                          IosHeatmapView(entries: entries, year: vm.currentMonth.year),
                        ] else ...[
                          IosHistoryListView(viewModel: vm),
                        ],

                        const SizedBox(height: 18),
                        // AI Recap Card
                        AiRecapSection(viewModel: vm),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
