import 'package:flutter/cupertino.dart';
import '../../../../core/theme/ios_colors.dart';
import '../../../../core/widgets/ios_card.dart';
import '../../../../core/widgets/ios_modal.dart';
import '../../../view_models/generate_view_model.dart';
import 'commit_diff_modal.dart';

class CommitListSection extends StatelessWidget {
  final GenerateViewModel viewModel;

  const CommitListSection({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final repos = viewModel.repositories;
    final selectedIds = viewModel.selectedRepoIds;
    final commits = viewModel.commits;
    final count = viewModel.commitCount;
    final isLoading = viewModel.isLoadingCommits;

    return IosCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        CupertinoIcons.chevron_left_slash_chevron_right,
                        size: 16,
                        color: IosColors.statusGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Commit Hari Ini',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          isLoading
                              ? 'Memuat sinkron Git…'
                              : (repos.isEmpty ? '0 repo terdaftar' : '$count commit • sinkron Git'),
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 11,
                            color: IosColors.secondaryLabel(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 30),
                  borderRadius: BorderRadius.circular(15),
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                  onPressed: isLoading ? null : () => viewModel.loadStatus(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoading)
                        const CupertinoActivityIndicator(radius: 6)
                      else
                        Icon(
                          CupertinoIcons.arrow_clockwise,
                          size: 13,
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        'Refresh',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Multi-repo selector pills
          if (repos.length > 1) ...[
            Container(
              height: 0.8,
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: isDark ? const Color(0xFF141416) : const Color(0xFFF9F9FA),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: repos.map((r) {
                        final active = selectedIds.contains(r.id);
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: isLoading ? null : () => viewModel.toggleRepo(r.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: active
                                    ? IosColors.statusGreen
                                    : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: active
                                      ? IosColors.statusGreen
                                      : (isDark ? const Color(0xFF38383A) : const Color(0xFFD1D1D6)),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (active) ...[
                                    const Icon(CupertinoIcons.checkmark, size: 11, color: CupertinoColors.black),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    r.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: active
                                          ? CupertinoColors.black
                                          : (isDark ? CupertinoColors.white : CupertinoColors.black),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (selectedIds.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Gabung ${selectedIds.length} repo → 1 draft',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 10,
                          color: IosColors.secondaryLabel(context),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          Container(
            height: 0.8,
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
          ),

          // Commits list or empty state
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: CupertinoActivityIndicator(radius: 12),
              ),
            )
          else if (repos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.folder_badge_plus,
                    size: 34,
                    color: IosColors.tertiaryLabel(context),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Belum Ada Repository Git',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Daftarkan repository Git di menu Pengaturan > Kelola Git Repo untuk sinkronisasi commit otomatis, atau kamu tetap dapat menyusun logbook menggunakan tombol Catatan Manual di bawah.',
                    style: TextStyle(
                      fontSize: 12,
                      color: IosColors.secondaryLabel(context),
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (count == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  Icon(
                    viewModel.errorMessage != null
                        ? CupertinoIcons.exclamationmark_triangle
                        : CupertinoIcons.tray,
                    size: 32,
                    color: viewModel.errorMessage != null
                        ? IosColors.statusRed
                        : IosColors.tertiaryLabel(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    viewModel.errorMessage != null
                        ? (viewModel.statusText == 'server terputus'
                            ? 'Server Backend Tidak Terhubung'
                            : 'Gagal Memuat Git Commit')
                        : 'Belum ada commit hari ini',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: viewModel.errorMessage != null ? IosColors.statusRed : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    viewModel.errorMessage != null
                        ? (viewModel.statusText == 'server terputus'
                            ? 'Pastikan backend Express (port 4174) berjalan dan cek URL di Pengaturan.'
                            : '${viewModel.errorMessage}')
                        : 'Tetap bisa buat logbook! Gunakan tombol Tambah Catatan di bawah.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: IosColors.secondaryLabel(context),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (viewModel.errorMessage != null) ...[
                    const SizedBox(height: 10),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      color: IosColors.statusGreen,
                      borderRadius: BorderRadius.circular(8),
                      minimumSize: const Size(0, 30),
                      onPressed: () => viewModel.loadStatus(),
                      child: const Text(
                        'Coba Lagi',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: CupertinoColors.black),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: commits.length,
              separatorBuilder: (context, index) => Container(
                margin: const EdgeInsets.only(left: 48),
                height: 0.8,
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
              ),
              itemBuilder: (context, index) {
                final commit = commits[index];
                return CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  onPressed: () {
                    IosModal.showBottomSheet(
                      context: context,
                      title: 'Diff Commit',
                      child: CommitDiffModal(
                        commit: commit,
                        viewModel: viewModel,
                      ),
                    );
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF21262D) : const Color(0xFFEAEFF5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          commit.displaySha,
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: IosColors.statusGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              commit.displayMessage,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                if (commit.repoLabel != null) ...[
                                  Text(
                                    '${commit.repoLabel!} • ',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: IosColors.statusBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                Text(
                                  commit.author ?? 'intern',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: IosColors.secondaryLabel(context),
                                  ),
                                ),
                                if (commit.stats != null) ...[
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      commit.stats!.split(',').take(2).join(', '),
                                      style: TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 10,
                                        color: IosColors.secondaryLabel(context),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
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
        ],
      ),
    );
  }
}
