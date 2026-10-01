import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/ios_colors.dart';
import '../../../../core/widgets/ios_button.dart';
import '../../../../core/widgets/ios_card.dart';
import '../../../../core/widgets/ios_character_counter.dart';
import '../../../../core/widgets/ios_modal.dart';
import '../../../../core/widgets/ios_toast.dart';
import '../../../view_models/generate_view_model.dart';
import 'manual_notes_modal.dart';

class DraftEditorSection extends StatefulWidget {
  final GenerateViewModel viewModel;
  final VoidCallback onSaved;

  const DraftEditorSection({
    super.key,
    required this.viewModel,
    required this.onSaved,
  });

  @override
  State<DraftEditorSection> createState() => _DraftEditorSectionState();
}

class _DraftEditorSectionState extends State<DraftEditorSection> {
  late TextEditingController _aktivitasCtrl;
  late TextEditingController _pembelajaranCtrl;
  late TextEditingController _kendalaCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.viewModel.draft;
    _aktivitasCtrl = TextEditingController(text: d?.aktivitas ?? '');
    _pembelajaranCtrl = TextEditingController(text: d?.pembelajaran ?? '');
    _kendalaCtrl = TextEditingController(text: d?.kendala ?? '');
  }

  @override
  void didUpdateWidget(covariant DraftEditorSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final d = widget.viewModel.draft;
    if (d != null) {
      if (_aktivitasCtrl.text != d.aktivitas) {
        _aktivitasCtrl.text = d.aktivitas;
      }
      if (_pembelajaranCtrl.text != d.pembelajaran) {
        _pembelajaranCtrl.text = d.pembelajaran;
      }
      if (_kendalaCtrl.text != d.kendala) {
        _kendalaCtrl.text = d.kendala;
      }
    }
  }

  @override
  void dispose() {
    _aktivitasCtrl.dispose();
    _pembelajaranCtrl.dispose();
    _kendalaCtrl.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    widget.viewModel.updateDraft(
      aktivitas: _aktivitasCtrl.text,
      pembelajaran: _pembelajaranCtrl.text,
      kendala: _kendalaCtrl.text,
    );
  }

  Future<void> _handleSave() async {
    final d = widget.viewModel.draft;
    if (d == null) return;

    if (!d.isCompliant) {
      IosToast.show(
        context,
        'Tiap field minimal 100 karakter agar compliant!',
        type: ToastType.error,
      );
      return;
    }

    try {
      await widget.viewModel.saveEntry();
      if (mounted) {
        IosToast.show(context, 'Logbook berhasil disimpan ke riwayat! ✨', type: ToastType.success);
        widget.onSaved();
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
    final vm = widget.viewModel;
    final draft = vm.draft;
    final isGenerating = vm.isGenerating;
    final commitCount = vm.commitCount;
    final activeProvider = vm.activeProvider;

    return IosCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Title & Provider Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: IosColors.statusGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.pencil_outline,
                      size: 16,
                      color: CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Draft Logbook',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),

              // iOS Styled AI Provider Switcher
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => vm.switchProvider('local'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: activeProvider == 'local'
                              ? (isDark ? const Color(0xFF3A3A3C) : CupertinoColors.white)
                              : const Color(0x00000000),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: activeProvider == 'local' && !isDark
                              ? [const BoxShadow(color: Color(0x1A000000), blurRadius: 4)]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.cube,
                              size: 12,
                              color: activeProvider == 'local' ? IosColors.statusGreen : IosColors.secondaryLabel(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Local LLM',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: activeProvider == 'local' ? FontWeight.bold : FontWeight.w500,
                                color: activeProvider == 'local'
                                    ? (isDark ? CupertinoColors.white : CupertinoColors.black)
                                    : IosColors.secondaryLabel(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => vm.switchProvider('cloud'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (activeProvider != 'local')
                              ? (isDark ? const Color(0xFF3A3A3C) : CupertinoColors.white)
                              : const Color(0x00000000),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: (activeProvider != 'local') && !isDark
                              ? [const BoxShadow(color: Color(0x1A000000), blurRadius: 4)]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.sparkles,
                              size: 12,
                              color: (activeProvider != 'local')
                                  ? IosColors.statusAmber
                                  : IosColors.secondaryLabel(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Cloud AI',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: (activeProvider != 'local')
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: (activeProvider != 'local')
                                    ? (isDark ? CupertinoColors.white : CupertinoColors.black)
                                    : IosColors.secondaryLabel(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Text(
            'Tiga bagian: aktivitas, pembelajaran, kendala. Model: ${activeProvider == 'local' ? 'Local LLM' : 'Big Pickle (OpenCode)'}.',
            style: TextStyle(
              fontSize: 12,
              color: IosColors.secondaryLabel(context),
            ),
          ),
          const SizedBox(height: 14),

          // Top Action Buttons
          Row(
            children: [
              Expanded(
                child: IosButton(
                  text: 'Tambah Catatan',
                  variant: IosButtonVariant.secondary,
                  size: IosButtonSize.small,
                  icon: const Icon(CupertinoIcons.doc_append),
                  onPressed: () {
                    IosModal.showBottomSheet(
                      context: context,
                      title: 'Tambah Catatan',
                      child: ManualNotesModal(viewModel: vm),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: IosButton(
                  text: isGenerating ? 'Menyusun…' : 'Buat Draft',
                  variant: IosButtonVariant.primary,
                  size: IosButtonSize.small,
                  isLoading: isGenerating,
                  icon: const Icon(CupertinoIcons.sparkles),
                  onPressed: isGenerating
                      ? null
                      : () async {
                          if (commitCount == 0) {
                            IosModal.showBottomSheet(
                              context: context,
                              title: 'Catatan Manual',
                              child: ManualNotesModal(viewModel: vm),
                            );
                            return;
                          }
                          try {
                            await vm.generateDraft();
                            if (context.mounted) {
                              IosToast.show(context, 'Draft berhasil dibuat!', type: ToastType.success);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              IosToast.show(context, e.toString(), type: ToastType.error);
                            }
                          }
                        },
                ),
              ),
            ],
          ),

          // Loading Progress State
          if (isGenerating) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF38383A) : const Color(0xFFD1D1D6),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  const CupertinoActivityIndicator(radius: 9),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vm.generateLabel,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Menganalisis commit & merangkai bahasa…',
                          style: TextStyle(
                            fontSize: 11,
                            color: IosColors.secondaryLabel(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${vm.elapsedSeconds.toStringAsFixed(1)}s',
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Empty states
          if (draft == null && !isGenerating && commitCount == 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x1AFF9F0A) : const Color(0x0FFF9F0A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: IosColors.statusAmber.withValues(alpha: 0.3), width: 0.8),
              ),
              child: Column(
                children: [
                  const Icon(CupertinoIcons.calendar_badge_plus, size: 30, color: IosColors.statusAmber),
                  const SizedBox(height: 8),
                  const Text(
                    'Tidak ada commit hari ini',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tetap bisa generate! Tulis catatan aktivitas non-ngoding (meeting, riset, dokumentasi) minimal 5 karakter.',
                    style: TextStyle(
                      fontSize: 12,
                      color: IosColors.secondaryLabel(context),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  IosButton(
                    text: 'Tulis Catatan & Generate',
                    variant: IosButtonVariant.tinted,
                    size: IosButtonSize.small,
                    onPressed: () {
                      IosModal.showBottomSheet(
                        context: context,
                        title: 'Tulis Catatan',
                        child: ManualNotesModal(viewModel: vm),
                      );
                    },
                  ),
                ],
              ),
            ),
          ] else if (draft == null && !isGenerating) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141416) : const Color(0xFFF9F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                  width: 0.8,
                ),
              ),
              child: Column(
                children: [
                  Icon(CupertinoIcons.doc_text, size: 30, color: IosColors.tertiaryLabel(context)),
                  const SizedBox(height: 8),
                  const Text(
                    'Belum ada draft logbook',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Klik "Buat Draft" untuk merangkum commit hari ini, atau "Tambah Catatan" untuk konteks meeting.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: IosColors.secondaryLabel(context),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          // Active Draft Form
          if (draft != null) ...[
            const SizedBox(height: 18),

            // Field 1: Aktivitas
            _buildFieldGroup(
              context: context,
              label: 'Aktivitas Harian',
              controller: _aktivitasCtrl,
              placeholder: 'Rincikan pekerjaan atau fitur yang dikembangkan hari ini…',
              count: _aktivitasCtrl.text.length,
              onChanged: _onFieldChanged,
            ),
            const SizedBox(height: 16),

            // Field 2: Pembelajaran
            _buildFieldGroup(
              context: context,
              label: 'Pembelajaran',
              controller: _pembelajaranCtrl,
              placeholder: 'Jelaskan wawasan teknis, konsep, atau skill baru yang didapat…',
              count: _pembelajaranCtrl.text.length,
              onChanged: _onFieldChanged,
            ),
            const SizedBox(height: 16),

            // Field 3: Kendala & Solusi
            _buildFieldGroup(
              context: context,
              label: 'Kendala & Solusi',
              controller: _kendalaCtrl,
              placeholder: 'Tuliskan kendala teknis atau "Tidak ada kendala berarti"…',
              count: _kendalaCtrl.text.length,
              onChanged: _onFieldChanged,
            ),

            const SizedBox(height: 12),

            // Autosave info
            if (vm.autoSavedAt != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(CupertinoIcons.clock, size: 12, color: IosColors.tertiaryLabel(context)),
                  const SizedBox(width: 4),
                  Text(
                    'tersimpan ${DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(vm.autoSavedAt!))}',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 11,
                      color: IosColors.secondaryLabel(context),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Bottom Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IosButton(
                  text: 'Ulangi',
                  variant: IosButtonVariant.secondary,
                  size: IosButtonSize.small,
                  icon: const Icon(CupertinoIcons.arrow_counterclockwise),
                  onPressed: isGenerating
                      ? null
                      : () async {
                          try {
                            await vm.regenerate();
                            if (context.mounted) {
                              IosToast.show(context, 'Draft di-generate ulang!', type: ToastType.success);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              IosToast.show(context, e.toString(), type: ToastType.error);
                            }
                          }
                        },
                ),
                const SizedBox(width: 8),
                IosButton(
                  text: 'Simpan Logbook',
                  variant: IosButtonVariant.primary,
                  size: IosButtonSize.small,
                  isLoading: vm.isSaving,
                  icon: const Icon(CupertinoIcons.checkmark_alt),
                  onPressed: vm.isSaving ? null : _handleSave,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldGroup({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required int count,
    required VoidCallback onChanged,
  }) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: IosColors.secondaryLabel(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: controller,
          maxLines: 5,
          minLines: 3,
          onChanged: (_) => onChanged(),
          placeholder: placeholder,
          placeholderStyle: TextStyle(
            fontSize: 13,
            color: IosColors.tertiaryLabel(context),
          ),
          style: const TextStyle(fontSize: 13.5, height: 1.45),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141416) : const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
              width: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 6),
        IosCharacterCounter(count: count),
      ],
    );
  }
}
