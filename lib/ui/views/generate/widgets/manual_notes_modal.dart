import 'package:flutter/cupertino.dart';
import '../../../../core/theme/ios_colors.dart';
import '../../../../core/widgets/ios_button.dart';
import '../../../../core/widgets/ios_toast.dart';
import '../../../view_models/generate_view_model.dart';

class ManualNotesModal extends StatefulWidget {
  final GenerateViewModel viewModel;

  const ManualNotesModal({super.key, required this.viewModel});

  @override
  State<ManualNotesModal> createState() => _ManualNotesModalState();
}

class _ManualNotesModalState extends State<ManualNotesModal> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final text = _controller.text.trim();
    final hasCommits = widget.viewModel.commitCount > 0;

    if (text.length < 5 && !hasCommits) {
      IosToast.show(
        context,
        'Isi catatan minimal 5 karakter (tidak ada commit hari ini).',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      Navigator.of(context).pop();
      if (text.isEmpty && hasCommits) {
        await widget.viewModel.generateDraft();
      } else if (hasCommits) {
        await widget.viewModel.generateCombinedDraft(text);
      } else {
        await widget.viewModel.generateManualDraft(text);
      }
      if (mounted) {
        IosToast.show(context, 'Draft berhasil dibuat!', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        IosToast.show(context, e.toString(), type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final commitCount = widget.viewModel.commitCount;
    final commits = widget.viewModel.commits;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            commitCount == 0
                ? 'Tidak ada commit hari ini — tulis aktivitas non-ngoding (meeting, riset, dokumentasi) minimal 5 karakter untuk tetap generate.'
                : 'Tambahkan konteks meeting, riset, atau kendala di luar commit yang dikerjakan hari ini.',
            style: TextStyle(
              fontSize: 13,
              color: IosColors.secondaryLabel(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Commit summary if any
          if (commitCount > 0) ...[
            Row(
              children: [
                Icon(CupertinoIcons.chevron_left_slash_chevron_right, size: 14, color: IosColors.statusGreen),
                const SizedBox(width: 6),
                Text(
                  'Commit Hari Ini ($commitCount commit)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: IosColors.secondaryLabel(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final c in commits.take(3))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Text(
                            c.displaySha,
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: IosColors.statusGreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c.displayMessage,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (commitCount > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+ ${commitCount - 3} commit lainnya',
                        style: TextStyle(
                          fontSize: 11,
                          color: IosColors.secondaryLabel(context),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Textarea
          Text(
            'Catatan Tambahan',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: IosColors.secondaryLabel(context),
            ),
          ),
          const SizedBox(height: 6),
          CupertinoTextField(
            controller: _controller,
            maxLines: 5,
            minLines: 3,
            placeholder: commitCount == 0
                ? 'Contoh: Hari ini tidak ngoding — mengikuti meeting validasi data dengan user dan riset library Flutter...'
                : 'Contoh: Mengikuti meeting sprint review dan diskusi arsitektur modular...',
            placeholderStyle: TextStyle(
              fontSize: 13,
              color: IosColors.tertiaryLabel(context),
            ),
            style: const TextStyle(fontSize: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8),
                width: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 20),

          IosButton(
            text: commitCount == 0 ? 'Generate dari Catatan' : 'Gabung & Generate',
            icon: const Icon(CupertinoIcons.sparkles),
            isLoading: _submitting,
            isFullWidth: true,
            onPressed: _handleSubmit,
          ),
        ],
      ),
    );
  }
}
