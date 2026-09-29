import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/ios_colors.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/settings_view_model.dart';
import 'widgets/about_section.dart';
import 'widgets/accent_theme_section.dart';
import 'widgets/ai_provider_section.dart';
import 'widgets/notification_reminder_section.dart';
import 'widgets/repo_manager_section.dart';
import 'widgets/user_account_section.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsViewModel viewModel;
  final AuthViewModel authViewModel;
  final VoidCallback onLoggedOut;

  const SettingsScreen({
    super.key,
    required this.viewModel,
    required this.authViewModel,
    required this.onLoggedOut,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, authViewModel]),
      builder: (context, _) {
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    CupertinoIcons.gear_alt_fill,
                    size: 15,
                    color: IosColors.statusGreen,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Pengaturan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 28),
              onPressed: () {
                HapticFeedback.lightImpact();
                viewModel.toggleAccentTheme();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: IosColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: IosColors.primary.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      viewModel.isSusanooTheme
                          ? CupertinoIcons.flame_fill
                          : CupertinoIcons.sparkles,
                      size: 12,
                      color: IosColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      viewModel.isSusanooTheme ? 'Susanoo' : 'Emerald',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: IosColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () => viewModel.loadSettings(),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        UserAccountSection(
                          authViewModel: authViewModel,
                          onLoggedOut: onLoggedOut,
                        ),
                        const SizedBox(height: 16),
                        AccentThemeSection(viewModel: viewModel),
                        const SizedBox(height: 16),
                        AiProviderSection(viewModel: viewModel),
                        const SizedBox(height: 16),
                        RepoManagerSection(viewModel: viewModel),
                        const SizedBox(height: 16),
                        NotificationReminderSection(viewModel: viewModel),
                        const SizedBox(height: 16),
                        AboutSection(viewModel: viewModel),
                        const SizedBox(height: 96),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
