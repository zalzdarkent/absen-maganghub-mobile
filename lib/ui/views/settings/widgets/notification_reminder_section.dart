import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/ios_colors.dart';
import '../../../../core/widgets/ios_button.dart';
import '../../../../core/widgets/ios_card.dart';
import '../../../../core/widgets/ios_toast.dart';
import '../../../view_models/settings_view_model.dart';

class NotificationReminderSection extends StatelessWidget {
  final SettingsViewModel viewModel;

  const NotificationReminderSection({super.key, required this.viewModel});

  Future<void> _handleTestNotification(BuildContext context) async {
    HapticFeedback.mediumImpact();
    await viewModel.sendTestNotification();

    if (context.mounted) {
      if (viewModel.testNotifStatus != null &&
          viewModel.testNotifStatus!.contains('berhasil')) {
        IosToast.show(
          context,
          '🔔 Notifikasi tes dikirim! Periksa bar notifikasi HP Anda lalu ketuk.',
          type: ToastType.success,
        );
      } else {
        IosToast.show(
          context,
          viewModel.testNotifStatus ?? 'Gagal mengirim notifikasi tes.',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final isEnabled = viewModel.isDailyReminderEnabled;

    return IosCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? IosColors.statusAmber.withValues(alpha: 0.18)
                      : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CupertinoIcons.bell_fill,
                  size: 18,
                  color: isEnabled ? IosColors.statusAmber : IosColors.secondaryLabel(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pengingat Push Logbook',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Notifikasi setiap hari jam 15:00 WIB',
                      style: TextStyle(
                        fontSize: 12,
                        color: IosColors.secondaryLabel(context),
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: isEnabled,
                activeTrackColor: IosColors.primary,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  viewModel.toggleDailyReminder(val);
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Detail Card
          Container(
            padding: const EdgeInsets.all(12),
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
                Row(
                  children: [
                    Icon(
                      isEnabled ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.xmark_circle_fill,
                      size: 14,
                      color: isEnabled ? IosColors.statusGreen : IosColors.statusRed,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isEnabled
                          ? 'Pengingat Aktif: Jam 15:00 WIB Setiap Hari'
                          : 'Pengingat Sedang Nonaktif',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isEnabled ? IosColors.statusGreen : IosColors.statusRed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Ketika jam 15:00 tiba, HP akan menerima notifikasi push pengingat isi logbook. '
                  'Saat notifikasi diketuk, aplikasi MagangHub akan langsung otomatis terbuka.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: IosColors.secondaryLabel(context),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Action row for instant test
          Row(
            children: [
              Expanded(
                child: Text(
                  'Coba tes munculkan notifikasi sekarang:',
                  style: TextStyle(
                    fontSize: 12,
                    color: IosColors.secondaryLabel(context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IosButton(
                text: 'Kirim Tes Notifikasi',
                icon: const Icon(CupertinoIcons.paperplane_fill, size: 14),
                variant: IosButtonVariant.secondary,
                size: IosButtonSize.small,
                isLoading: viewModel.isSendingTestNotif,
                onPressed: () => _handleTestNotification(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
