import 'package:flutter/cupertino.dart';
import '../../../../core/theme/ios_colors.dart';
import '../../../../core/widgets/ios_button.dart';
import '../../../../core/widgets/ios_card.dart';
import '../../../../core/widgets/ios_toast.dart';
import '../../../view_models/settings_view_model.dart';

class AboutSection extends StatefulWidget {
  final SettingsViewModel viewModel;

  const AboutSection({super.key, required this.viewModel});

  @override
  State<AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<AboutSection> {
  bool _testingAutoDraft = false;

  Future<void> _handleTestAutoDraft() async {
    setState(() => _testingAutoDraft = true);
    try {
      await widget.viewModel.triggerAutoDraft();
      if (mounted) {
        IosToast.show(
          context,
          'Draft otomatis dibuat! Buka tab Generate untuk melihat.',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        IosToast.show(context, e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _testingAutoDraft = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Daily Reminder & Cron Card
        IosCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(CupertinoIcons.bell_fill, size: 16, color: IosColors.statusAmber),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Pengingat & Auto-Draft (16:00 WIB)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Server backend otomatis menyusun draft pada jam 16:00 WIB setiap hari kerja.',
                style: TextStyle(fontSize: 12, color: IosColors.secondaryLabel(context)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Uji coba auto-draft sekarang:',
                    style: TextStyle(fontSize: 12, color: IosColors.secondaryLabel(context)),
                  ),
                  IosButton(
                    text: 'Tes Auto-Draft',
                    variant: IosButtonVariant.secondary,
                    size: IosButtonSize.small,
                    isLoading: _testingAutoDraft,
                    onPressed: _handleTestAutoDraft,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // About Info Card
        IosCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: IosColors.statusGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(CupertinoIcons.book_fill, size: 20, color: CupertinoColors.black),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MagangHub Logbook',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.4),
                        ),
                        Text(
                          'Sistem Logbook Otomatis Berbasis Git & AI',
                          style: TextStyle(fontSize: 11.5, color: IosColors.secondaryLabel(context)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Container(height: 0.8, color: borderColor),

              _buildInfoRow(context, 'Versi Aplikasi', '1.0.0+1 (iOS Style)'),
              Container(height: 0.8, color: borderColor),
              _buildInfoRow(context, 'Pengembang', 'Alif Fadillah Ummar'),
              Container(height: 0.8, color: borderColor),
              _buildInfoRow(context, 'Engine AI', 'Local LLM & Google Gemini Cloud'),
              Container(height: 0.8, color: borderColor),
              _buildInfoRow(context, 'Format Ekspor', 'Excel MagangHub Kemnaker (.xlsx)'),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Center(
          child: Text(
            '© ${DateTime.now().year} Alif Fadillah Ummar. All rights reserved.',
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 11,
              color: IosColors.tertiaryLabel(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              color: IosColors.secondaryLabel(context),
            ),
          ),
        ],
      ),
    );
  }
}
