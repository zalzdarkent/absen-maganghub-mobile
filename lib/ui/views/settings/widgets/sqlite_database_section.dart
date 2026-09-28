import 'package:flutter/cupertino.dart';
import '../../../../core/theme/ios_colors.dart';
import '../../../../core/widgets/ios_button.dart';
import '../../../../core/widgets/ios_card.dart';
import '../../../../core/widgets/ios_toast.dart';
import '../../../view_models/settings_view_model.dart';

class SqliteDatabaseSection extends StatelessWidget {
  final SettingsViewModel viewModel;

  const SqliteDatabaseSection({super.key, required this.viewModel});

  void _confirmReimport(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Sinkron Ulang Data Vercel?'),
        content: const Text(
          'Ini akan memuat dan menyinkronkan ulang 13 entri riwayat logbook dari file Excel Vercel (Logbook_MagangHub.xlsx) ke database SQLite di HP kamu.',
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: false,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              final count = await viewModel.reimportFromVercel();
              if (context.mounted) {
                IosToast.show(
                  context,
                  'Sukses! $count entri dari Excel Vercel tersimpan di SQLite HP.',
                  type: ToastType.success,
                );
              }
            },
            child: const Text('Ya, Sinkronkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final count = viewModel.sqliteEntryCount;

    return IosCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: IosColors.systemIndigo.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.circle_grid_hex_fill,
                      size: 16,
                      color: IosColors.systemIndigo,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Database Lokal (SQLite)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'maganghub_logbook.db',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            'Semua data riwayat logbook disimpan secara native di SQLite internal HP, mandiri tanpa ketergantungan cloud atau server laptop.',
            style: TextStyle(
              fontSize: 12,
              color: IosColors.secondaryLabel(context),
            ),
          ),
          const SizedBox(height: 14),

          // Info Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141416) : const Color(0xFFF9F9FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL LOGBOOK DI SQLITE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                        color: IosColors.secondaryLabel(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count Entri Terdata',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: IosColors.statusGreen,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: IosColors.statusGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: IosColors.statusGreen, width: 0.8),
                  ),
                  child: Text(
                    'SQLite OK',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: IosColors.statusGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          IosButton(
            text: 'Sinkronkan Ulang dari Excel Vercel',
            icon: const Icon(CupertinoIcons.arrow_2_circlepath, size: 14),
            variant: IosButtonVariant.secondary,
            size: IosButtonSize.small,
            isLoading: viewModel.isReimporting,
            onPressed: () => _confirmReimport(context),
          ),
        ],
      ),
    );
  }
}
