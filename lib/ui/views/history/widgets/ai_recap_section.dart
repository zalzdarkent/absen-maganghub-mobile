import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/ios_colors.dart';
import '../../../../core/widgets/ios_button.dart';
import '../../../../core/widgets/ios_card.dart';
import '../../../../core/widgets/ios_toast.dart';
import '../../../view_models/history_view_model.dart';

class AiRecapSection extends StatefulWidget {
  final HistoryViewModel viewModel;

  const AiRecapSection({super.key, required this.viewModel});

  @override
  State<AiRecapSection> createState() => _AiRecapSectionState();
}

class _AiRecapSectionState extends State<AiRecapSection> {
  String _selectedPeriod = 'weekly'; // 'weekly' | 'monthly'

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final vm = widget.viewModel;
    final recap = vm.recap;
    final isLoading = vm.recapLoadingPeriod != null;
    final elapsed = vm.recapElapsed;

    final hasEntries = vm.entries != null && vm.entries!.isNotEmpty;

    return IosCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(CupertinoIcons.sparkles, size: 16, color: IosColors.statusGreen),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rekap AI Berkala',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Ringkasan mingguan/bulanan dari entri logbook kamu.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: IosColors.secondaryLabel(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Period Segmented Control & Generate Button
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141416) : const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPeriod = 'weekly'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _selectedPeriod == 'weekly'
                                  ? (isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white)
                                  : const Color(0x00000000),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _selectedPeriod == 'weekly' && !isDark
                                  ? [const BoxShadow(color: Color(0x1A000000), blurRadius: 4)]
                                  : null,
                            ),
                            child: Text(
                              'Mingguan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _selectedPeriod == 'weekly' ? FontWeight.bold : FontWeight.w500,
                                color: _selectedPeriod == 'weekly'
                                    ? (isDark ? CupertinoColors.white : CupertinoColors.black)
                                    : IosColors.secondaryLabel(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPeriod = 'monthly'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _selectedPeriod == 'monthly'
                                  ? (isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white)
                                  : const Color(0x00000000),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _selectedPeriod == 'monthly' && !isDark
                                  ? [const BoxShadow(color: Color(0x1A000000), blurRadius: 4)]
                                  : null,
                            ),
                            child: Text(
                              'Bulanan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _selectedPeriod == 'monthly' ? FontWeight.bold : FontWeight.w500,
                                color: _selectedPeriod == 'monthly'
                                    ? (isDark ? CupertinoColors.white : CupertinoColors.black)
                                    : IosColors.secondaryLabel(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IosButton(
                text: isLoading ? 'Menyusun…' : 'Generate Rekap',
                variant: IosButtonVariant.tinted,
                size: IosButtonSize.small,
                isLoading: isLoading,
                icon: const Icon(CupertinoIcons.wand_stars),
                onPressed: (!hasEntries || isLoading)
                    ? null
                    : () async {
                        try {
                          await vm.generateRecap(_selectedPeriod);
                          if (context.mounted) {
                            IosToast.show(context, 'Rekap AI selesai!', type: ToastType.success);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            IosToast.show(context, e.toString(), type: ToastType.error);
                          }
                        }
                      },
              ),
            ],
          ),

          if (isLoading) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141416) : const Color(0xFFF9F9FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  const CupertinoActivityIndicator(radius: 8),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'AI sedang menganalisis logbook…',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    '${elapsed.toStringAsFixed(1)}s',
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],

          // Display Generated Recap
          if (recap != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141416) : const Color(0xFFF9F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(CupertinoIcons.doc_text_fill, size: 14, color: IosColors.statusGreen),
                          const SizedBox(width: 6),
                          Text(
                            recap.rentang.isNotEmpty ? recap.rentang : 'Periode Magang',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (recap.totalHari > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${recap.totalHari} hari',
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Ringkasan
                  Text(
                    'RINGKASAN:',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: IosColors.secondaryLabel(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recap.ringkasan,
                    style: const TextStyle(fontSize: 12.5, height: 1.45),
                  ),
                  const SizedBox(height: 12),

                  // Highlights
                  if (recap.highlights.isNotEmpty) ...[
                    Text(
                      'HIGHLIGHTS:',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: IosColors.secondaryLabel(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (int i = 0; i < recap.highlights.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${i + 1}. ',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: IosColors.statusGreen),
                            ),
                            Expanded(
                              child: Text(
                                recap.highlights[i],
                                style: const TextStyle(fontSize: 12, height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],

                  // Kendala Teratasi
                  if (recap.kendalaTeratasi.isNotEmpty) ...[
                    Text(
                      'KENDALA TERATASI:',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: IosColors.secondaryLabel(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recap.kendalaTeratasi,
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Saran
                  if (recap.saran.isNotEmpty) ...[
                    Text(
                      'SARAN UNTUK PERIODE DEPAN:',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: IosColors.secondaryLabel(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recap.saran,
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Copy and Share actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(0, 30),
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                        borderRadius: BorderRadius.circular(15),
                        onPressed: () {
                          final text = recap.toFormattedText(period: _selectedPeriod);
                          Clipboard.setData(ClipboardData(text: text));
                          IosToast.show(context, 'Teks rekap disalin ke clipboard!', type: ToastType.success);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.doc_on_doc, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'Salin',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(0, 30),
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                        borderRadius: BorderRadius.circular(15),
                        onPressed: () {
                          final text = recap.toFormattedText(period: _selectedPeriod);
                          Share.share(text, subject: 'Rekap Logbook MagangHub');
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.share, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'Share',
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
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
