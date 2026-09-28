import 'package:flutter/cupertino.dart';
import '../../../../core/theme/ios_colors.dart';
import '../../../../core/widgets/ios_button.dart';
import '../../../../core/widgets/ios_card.dart';
import '../../../view_models/auth_view_model.dart';

class UserAccountSection extends StatelessWidget {
  final AuthViewModel authViewModel;
  final VoidCallback onLoggedOut;

  const UserAccountSection({
    super.key,
    required this.authViewModel,
    required this.onLoggedOut,
  });

  void _confirmLogout(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text(
          'Data logbook kamu tetap tersimpan aman di database SQLite HP ini. Kamu dapat masuk kembali kapan saja.',
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: false,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              await authViewModel.logout();
              onLoggedOut();
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = authViewModel.currentUser;
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final initial = user.displayName.isNotEmpty
        ? user.displayName.substring(0, 1).toUpperCase()
        : 'U';

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
                      color: IosColors.statusGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      CupertinoIcons.person_crop_circle_fill,
                      size: 16,
                      color: IosColors.statusGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Akun Pengguna',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 14),

          // User Info Tile
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141416) : const Color(0xFFF9F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                // Avatar Initials
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: IosColors.avatarGradient,
                    ),
                    border: Border.all(
                      color: IosColors.statusGreen.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: IosColors.statusGreen.withValues(alpha: 0.25),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: IosColors.statusGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.at,
                            size: 12,
                            color: IosColors.secondaryLabel(context),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            user.username,
                            style: TextStyle(
                              fontSize: 12,
                              color: IosColors.secondaryLabel(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(
                              fontSize: 12,
                              color: IosColors.secondaryLabel(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              user.email,
                              style: TextStyle(
                                fontSize: 12,
                                color: IosColors.secondaryLabel(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Logout Button
          IosButton(
            text: 'Keluar dari Akun',
            icon: const Icon(CupertinoIcons.square_arrow_left, size: 15),
            variant: IosButtonVariant.secondary,
            size: IosButtonSize.small,
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }
}
