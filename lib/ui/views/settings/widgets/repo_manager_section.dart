import 'package:flutter/cupertino.dart';
import '../../../../core/theme/ios_colors.dart';
import '../../../../core/widgets/ios_button.dart';
import '../../../../core/widgets/ios_card.dart';
import '../../../../core/widgets/ios_toast.dart';
import '../../../view_models/settings_view_model.dart';

class RepoManagerSection extends StatefulWidget {
  final SettingsViewModel viewModel;

  const RepoManagerSection({super.key, required this.viewModel});

  @override
  State<RepoManagerSection> createState() => _RepoManagerSectionState();
}

class _RepoManagerSectionState extends State<RepoManagerSection> {
  final TextEditingController _labelCtrl = TextEditingController();
  final TextEditingController _urlCtrl = TextEditingController();
  bool _showAddForm = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAdd() async {
    final rawUrl = _urlCtrl.text.trim();
    String label = _labelCtrl.text.trim();

    if (rawUrl.isEmpty) {
      IosToast.show(context, 'URL repository wajib diisi.', type: ToastType.warning);
      return;
    }

    // Auto-detect label from URL if user left it blank
    if (label.isEmpty) {
      final clean = rawUrl.replaceAll(RegExp(r'\.git/?$'), '');
      final parts = clean.split('/');
      if (parts.isNotEmpty && parts.last.isNotEmpty) {
        label = parts.last;
      } else {
        label = 'Repository ${widget.viewModel.settings.repositories.length + 1}';
      }
    }

    try {
      await widget.viewModel.addRepository(label, rawUrl);
      _labelCtrl.clear();
      _urlCtrl.clear();
      setState(() => _showAddForm = false);
      if (mounted) {
        IosToast.show(context, 'Repository "$label" berhasil ditambahkan!', type: ToastType.success);
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
    final repos = widget.viewModel.settings.repositories;
    final isAdding = widget.viewModel.isAddingRepo;

    return IosCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                    child: const Icon(CupertinoIcons.folder_badge_plus, size: 16, color: IosColors.statusGreen),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Repository Git (${repos.length})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              if (!_showAddForm)
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 28),
                  borderRadius: BorderRadius.circular(14),
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                  onPressed: () => setState(() => _showAddForm = true),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.plus, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Tambah',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Daftar repositori proyek magang (URL GitHub publik/privat). Bisa ditambahkan atau dihapus secara dinamis kapan saja.',
            style: TextStyle(
              fontSize: 12,
              color: IosColors.secondaryLabel(context),
            ),
          ),
          const SizedBox(height: 14),

          // Add Repo Form
          if (_showAddForm) ...[
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CupertinoTextField(
                    controller: _urlCtrl,
                    placeholder: 'URL GitHub (contoh: https://github.com/user/project)',
                    placeholderStyle: TextStyle(fontSize: 13, color: IosColors.tertiaryLabel(context)),
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA), width: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _labelCtrl,
                    placeholder: 'Label Repo opsional (contoh: Backend API)',
                    placeholderStyle: TextStyle(fontSize: 13, color: IosColors.tertiaryLabel(context)),
                    style: const TextStyle(fontSize: 13),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA), width: 0.8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        onPressed: () => setState(() => _showAddForm = false),
                        child: Text(
                          'Batal',
                          style: TextStyle(fontSize: 12, color: IosColors.secondaryLabel(context)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IosButton(
                        text: 'Simpan Repo',
                        variant: IosButtonVariant.primary,
                        size: IosButtonSize.small,
                        isLoading: isAdding,
                        onPressed: _handleAdd,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Repos list
          if (repos.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141416) : const Color(0xFFF9F9FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                  width: 0.8,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.folder_badge_plus,
                    size: 32,
                    color: IosColors.tertiaryLabel(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada repository',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: IosColors.secondaryLabel(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tambahkan repositori GitHub untuk sinkronisasi commit otomatis ke logbook.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: IosColors.tertiaryLabel(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: repos.length,
              separatorBuilder: (context, index) => Container(
                margin: const EdgeInsets.only(left: 12),
                height: 0.8,
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
              ),
              itemBuilder: (context, index) {
                final r = repos[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF21262D) : const Color(0xFFEAEFF5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(CupertinoIcons.folder, size: 14, color: IosColors.statusGreen),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.label,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              r.url,
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 11,
                                color: IosColors.secondaryLabel(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          showCupertinoDialog(
                            context: context,
                            builder: (ctx) => CupertinoAlertDialog(
                              title: const Text('Hapus Repository?'),
                              content: Text('Hapus "${r.label}" dari daftar repository?'),
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
                                    await widget.viewModel.deleteRepository(r.id);
                                    if (context.mounted) {
                                      IosToast.show(context, 'Repository "${r.label}" dihapus.', type: ToastType.info);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Icon(CupertinoIcons.trash, size: 16, color: IosColors.statusRed),
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
