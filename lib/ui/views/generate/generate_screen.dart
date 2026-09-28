import 'package:flutter/cupertino.dart';
import '../../../../core/theme/ios_colors.dart';
import '../../../../core/widgets/ios_badge.dart';
import '../../../../domain/models/status_model.dart';
import '../../view_models/generate_view_model.dart';
import 'widgets/commit_list_section.dart';
import 'widgets/draft_editor_section.dart';

class GenerateScreen extends StatelessWidget {
  final GenerateViewModel viewModel;
  final VoidCallback onSaved;

  const GenerateScreen({
    super.key,
    required this.viewModel,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final statusKind = viewModel.statusKind;
        final statusText = viewModel.statusText;

        IosBadgeVariant badgeVariant = IosBadgeVariant.secondary;
        switch (statusKind) {
          case StatusKind.ok:
            badgeVariant = IosBadgeVariant.success;
            break;
          case StatusKind.warn:
            badgeVariant = IosBadgeVariant.warning;
            break;
          case StatusKind.err:
            badgeVariant = IosBadgeVariant.destructive;
            break;
          case StatusKind.idle:
            badgeVariant = IosBadgeVariant.secondary;
            break;
        }

        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: IosColors.statusGreen,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    CupertinoIcons.book_fill,
                    size: 15,
                    color: CupertinoColors.black,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'MagangHub',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: IosColors.separator(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LOGBOOK',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            trailing: IosBadge(
              label: statusText,
              variant: badgeVariant,
              showDot: true,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 820;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    CupertinoSliverRefreshControl(
                      onRefresh: () => viewModel.loadStatus(),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Page Title
                            const Text(
                              'Buat Draft Logbook Harian',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Susun logbook harian otomatis dari commit Git atau catatan manual meeting.',
                              style: TextStyle(
                                fontSize: 13,
                                color: IosColors.secondaryLabel(context),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Content: Responsive 2-column on iPad/Desktop or vertical stack on Phone
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: CommitListSection(viewModel: viewModel),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 7,
                                    child: DraftEditorSection(
                                      viewModel: viewModel,
                                      onSaved: onSaved,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  CommitListSection(viewModel: viewModel),
                                  const SizedBox(height: 16),
                                  DraftEditorSection(
                                    viewModel: viewModel,
                                    onSaved: onSaved,
                                  ),
                                  const SizedBox(height: 96),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
