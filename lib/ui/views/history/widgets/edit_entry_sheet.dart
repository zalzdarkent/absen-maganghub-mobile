import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/ios_colors.dart';
import '../../../../core/widgets/ios_button.dart';
import '../../../../core/widgets/ios_character_counter.dart';
import '../../../../core/widgets/ios_toast.dart';
import '../../../../domain/models/logbook_entry_model.dart';
import '../../../view_models/history_view_model.dart';

class EditEntrySheet extends StatefulWidget {
  final LogbookEntry entry;
  final HistoryViewModel viewModel;
  final ScrollController? scrollController;

  const EditEntrySheet({
    super.key,
    required this.entry,
    required this.viewModel,
    this.scrollController,
  });

  @override
  State<EditEntrySheet> createState() => _EditEntrySheetState();
}

class _EditEntrySheetState extends State<EditEntrySheet> {
  late TextEditingController _aktivitasCtrl;
  late TextEditingController _pembelajaranCtrl;
  late TextEditingController _kendalaCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _aktivitasCtrl = TextEditingController(text: widget.entry.aktivitas);
    _pembelajaranCtrl = TextEditingController(text: widget.entry.pembelajaran);
    _kendalaCtrl = TextEditingController(text: widget.entry.kendala);
  }

  @override
  void dispose() {
    _aktivitasCtrl.dispose();
    _pembelajaranCtrl.dispose();
    _kendalaCtrl.dispose();
    super.dispose();
  }

  void _handleCopyAll() {
    final text = '''
AKTIVITAS:
${_aktivitasCtrl.text.trim()}

PEMBELAJARAN:
${_pembelajaranCtrl.text.trim()}

KENDALA & SOLUSI:
${_kendalaCtrl.text.trim()}
'''.trim();

    Clipboard.setData(ClipboardData(text: text));
    IosToast.show(context, 'Seluruh isi logbook disalin ke clipboard!', type: ToastType.success);
  }

  void _copySection(String title, String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      IosToast.show(context, 'Teks $title masih kosong.', type: ToastType.warning);
      return;
    }
    Clipboard.setData(ClipboardData(text: trimmed));
    IosToast.show(context, '$title disalin ke clipboard!', type: ToastType.success);
  }

  Future<void> _handleSave() async {
    final akt = _aktivitasCtrl.text.trim();
    final pem = _pembelajaranCtrl.text.trim();
    final ken = _kendalaCtrl.text.trim();

    if (akt.length < 100 || pem.length < 100 || ken.length < 100) {
      IosToast.show(context, 'Tiap field minimal 100 karakter.', type: ToastType.error);
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.viewModel.updateEntry(
        widget.entry.rowNumber,
        DraftFields(aktivitas: akt, pembelajaran: pem, kendala: ken),
      );
      if (mounted) {
        Navigator.of(context).pop();
        IosToast.show(context, 'Entri berhasil diperbarui!', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        IosToast.show(context, e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _handleDelete() async {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Hapus Entri?'),
        content: Text(
          'Hapus entri #${widget.entry.no} tanggal ${widget.entry.tanggal}? Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Batal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Hapus'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await widget.viewModel.deleteEntry(widget.entry.rowNumber);
                if (mounted) {
                  Navigator.of(context).pop();
                  IosToast.show(context, 'Entri dihapus.', type: ToastType.info);
                }
              } catch (e) {
                if (mounted) {
                  IosToast.show(context, e.toString(), type: ToastType.error);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: SingleChildScrollView(
        controller: widget.scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#${widget.entry.no}',
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(CupertinoIcons.calendar, size: 14, color: IosColors.secondaryLabel(context)),
                const SizedBox(width: 4),
                Text(
                  widget.entry.tanggal,
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  minimumSize: Size.zero,
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(8),
                  onPressed: _handleCopyAll,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.doc_on_doc,
                        size: 13,
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Salin Semua',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Field 1: Aktivitas
            _buildInputGroup('Aktivitas Harian', _aktivitasCtrl),
            const SizedBox(height: 14),

            // Field 2: Pembelajaran
            _buildInputGroup('Pembelajaran', _pembelajaranCtrl),
            const SizedBox(height: 14),

            // Field 3: Kendala & Solusi
            _buildInputGroup('Kendala & Solusi', _kendalaCtrl),
            const SizedBox(height: 20),

            // Actions
            Row(
              children: [
                Expanded(
                  child: IosButton(
                    text: 'Hapus Entri',
                    variant: IosButtonVariant.destructive,
                    size: IosButtonSize.small,
                    icon: const Icon(CupertinoIcons.trash),
                    onPressed: _handleDelete,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: IosButton(
                    text: 'Simpan',
                    variant: IosButtonVariant.primary,
                    size: IosButtonSize.small,
                    isLoading: _saving,
                    icon: const Icon(CupertinoIcons.checkmark_alt),
                    onPressed: _handleSave,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputGroup(String label, TextEditingController controller) {
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
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              minimumSize: Size.zero,
              onPressed: () => _copySection(label, controller.text),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.doc_on_doc, size: 12, color: IosColors.statusGreen),
                  const SizedBox(width: 4),
                  Text(
                    'Salin',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: IosColors.statusGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        CupertinoTextField(
          controller: controller,
          maxLines: 4,
          minLines: 2,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 13.5, height: 1.4),
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
        const SizedBox(height: 5),
        IosCharacterCounter(count: controller.text.length),
      ],
    );
  }
}
