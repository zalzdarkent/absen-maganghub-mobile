import 'package:flutter/cupertino.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/ios_colors.dart';
import '../../../../core/widgets/ios_button.dart';
import '../../../../core/widgets/ios_card.dart';
import '../../../../core/widgets/ios_toast.dart';
import '../../../view_models/settings_view_model.dart';

class ServerConfigSection extends StatefulWidget {
  final SettingsViewModel viewModel;

  const ServerConfigSection({super.key, required this.viewModel});

  @override
  State<ServerConfigSection> createState() => _ServerConfigSectionState();
}

class _ServerConfigSectionState extends State<ServerConfigSection> {
  late TextEditingController _urlCtrl;
  bool _testing = false;
  bool? _connectionOk;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(
      text: widget.viewModel.serverUrl.isNotEmpty
          ? widget.viewModel.serverUrl
          : ApiConstants.defaultBaseUrl,
    );
  }

  @override
  void didUpdateWidget(covariant ServerConfigSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel.serverUrl != widget.viewModel.serverUrl &&
        widget.viewModel.serverUrl.isNotEmpty) {
      _urlCtrl.text = widget.viewModel.serverUrl;
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      IosToast.show(context, 'URL server tidak boleh kosong.', type: ToastType.error);
      return;
    }

    setState(() => _testing = true);
    try {
      await widget.viewModel.updateServerUrl(url);
      setState(() => _connectionOk = true);
      if (mounted) {
        IosToast.show(context, 'URL server berhasil disimpan!', type: ToastType.success);
      }
    } catch (e) {
      setState(() => _connectionOk = false);
      if (mounted) {
        IosToast.show(context, 'Gagal terhubung: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final isStandalone = widget.viewModel.isStandalone;

    return IosCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Mode Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isStandalone
                          ? IosColors.statusGreen.withValues(alpha: 0.15)
                          : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isStandalone ? CupertinoIcons.device_phone_portrait : CupertinoIcons.desktopcomputer,
                      size: 16,
                      color: isStandalone ? IosColors.statusGreen : IosColors.statusBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isStandalone ? 'Mode Mandiri (HP Saja)' : 'Mode Server Laptop',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isStandalone
                      ? IosColors.statusGreen.withValues(alpha: 0.15)
                      : IosColors.statusAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isStandalone ? IosColors.statusGreen : IosColors.statusAmber,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isStandalone ? IosColors.statusGreen : IosColors.statusAmber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isStandalone ? 'Aktif di HP' : 'Perlu Laptop',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isStandalone ? IosColors.statusGreen : IosColors.statusAmber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cupertino Segmented Control to switch mode
          CupertinoSlidingSegmentedControl<bool>(
            groupValue: isStandalone,
            children: {
              true: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(CupertinoIcons.device_phone_portrait, size: 14),
                    SizedBox(width: 6),
                    Text('Mandiri (HP Saja)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              false: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(CupertinoIcons.desktopcomputer, size: 14),
                    SizedBox(width: 6),
                    Text('Server Laptop', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            },
            onValueChanged: (val) {
              if (val != null) {
                widget.viewModel.toggleStandalone(val);
                IosToast.show(
                  context,
                  val ? 'Beralih ke Mode Mandiri (HP Saja)' : 'Beralih ke Mode Server Laptop',
                  type: ToastType.info,
                );
              }
            },
          ),
          const SizedBox(height: 14),

          // Content based on Mode
          if (isStandalone) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141416) : const Color(0xFFF8F9FA),
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
                      Icon(CupertinoIcons.checkmark_shield_fill, size: 14, color: IosColors.statusGreen),
                      const SizedBox(width: 6),
                      Text(
                        'Laptop Dimatikan? Tidak Masalah!',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: IosColors.statusGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureBullet(
                    CupertinoIcons.arrow_2_circlepath,
                    'Git Commits',
                    'Diambil langsung dari GitHub REST API publik/token.',
                    context,
                  ),
                  const SizedBox(height: 6),
                  _buildFeatureBullet(
                    CupertinoIcons.sparkles,
                    'AI LLM di Kantor',
                    'Terhubung langsung ke 192.168.13.155:3000 via Wi-Fi kantor.',
                    context,
                  ),
                  const SizedBox(height: 6),
                  _buildFeatureBullet(
                    CupertinoIcons.floppy_disk,
                    'Penyimpanan',
                    'Riwayat logbook & pengaturan tersimpan aman di internal HP.',
                    context,
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              'Aplikasi terhubung ke backend Express di laptop (server.js:4174). Pastikan laptop menyala.',
              style: TextStyle(
                fontSize: 12,
                color: IosColors.secondaryLabel(context),
              ),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _urlCtrl,
              placeholder: 'http://localhost:4174',
              placeholderStyle: TextStyle(
                fontSize: 13,
                color: IosColors.tertiaryLabel(context),
              ),
              style: const TextStyle(fontFamily: 'Courier', fontSize: 13),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141416) : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                  width: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildPresetChip('USB / ADB', 'http://127.0.0.1:4174', context, isDark),
                _buildPresetChip('Wi-Fi LAN', 'http://192.168.1.13:4174', context, isDark),
                _buildPresetChip('Emulator', 'http://10.0.2.2:4174', context, isDark),
                _buildPresetChip('Localhost', 'http://localhost:4174', context, isDark),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_connectionOk != null)
                  Row(
                    children: [
                      Icon(
                        _connectionOk! ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.xmark_circle_fill,
                        size: 14,
                        color: _connectionOk! ? IosColors.statusGreen : IosColors.statusRed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _connectionOk! ? 'Terhubung' : 'Gagal',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _connectionOk! ? IosColors.statusGreen : IosColors.statusRed,
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox(),
                IosButton(
                  text: 'Simpan & Tes Koneksi',
                  variant: IosButtonVariant.secondary,
                  size: IosButtonSize.small,
                  isLoading: _testing,
                  onPressed: _handleSave,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureBullet(IconData icon, String title, String desc, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: IosColors.secondaryLabel(context)),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 11.5,
                color: CupertinoTheme.of(context).textTheme.textStyle.color,
                height: 1.3,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: desc,
                  style: TextStyle(color: IosColors.secondaryLabel(context)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, String url, BuildContext context, bool isDark) {
    final isSelected = _urlCtrl.text.trim() == url;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, 26),
      onPressed: () {
        setState(() {
          _urlCtrl.text = url;
          _connectionOk = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? IosColors.statusGreen.withValues(alpha: 0.18)
              : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7)),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? IosColors.statusGreen
                : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? IosColors.statusGreen : IosColors.secondaryLabel(context),
          ),
        ),
      ),
    );
  }
}
