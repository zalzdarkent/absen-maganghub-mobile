import 'package:flutter/cupertino.dart';
import '../../../../core/theme/ios_colors.dart';
import '../../../../core/widgets/ios_button.dart';
import '../../../../core/widgets/ios_card.dart';
import '../../../../core/widgets/ios_toast.dart';
import '../../../view_models/settings_view_model.dart';

class AiProviderSection extends StatefulWidget {
  final SettingsViewModel viewModel;

  const AiProviderSection({super.key, required this.viewModel});

  @override
  State<AiProviderSection> createState() => _AiProviderSectionState();
}

class _AiProviderSectionState extends State<AiProviderSection> {
  late String _provider;
  bool _userSwitchedProvider = false;
  late TextEditingController _localUrlCtrl;
  late TextEditingController _localModelCtrl;
  late TextEditingController _localKeyCtrl;
  late TextEditingController _geminiModelCtrl;
  late TextEditingController _geminiKeyCtrl;

  @override
  void initState() {
    super.initState();
    final s = widget.viewModel.settings;
    _provider = s.llmProvider;
    _localUrlCtrl = TextEditingController(text: s.localLlmUrl);
    _localModelCtrl = TextEditingController(text: s.localLlmModel.isNotEmpty ? s.localLlmModel : 'gpt-oss-20b');
    _localKeyCtrl = TextEditingController(text: s.localLlmApiKey);
    _geminiModelCtrl = TextEditingController(text: s.geminiModel);
    _geminiKeyCtrl = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant AiProviderSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel.settings != widget.viewModel.settings) {
      final s = widget.viewModel.settings;
      if (!_userSwitchedProvider) {
        _provider = s.llmProvider;
      }
      if (_localUrlCtrl.text.isEmpty || oldWidget.viewModel.settings.localLlmUrl != s.localLlmUrl) {
        _localUrlCtrl.text = s.localLlmUrl;
      }
      if (_localModelCtrl.text.isEmpty || oldWidget.viewModel.settings.localLlmModel != s.localLlmModel) {
        _localModelCtrl.text = s.localLlmModel.isNotEmpty ? s.localLlmModel : 'gpt-oss-20b';
      }
      if (_localKeyCtrl.text.isEmpty || oldWidget.viewModel.settings.localLlmApiKey != s.localLlmApiKey) {
        _localKeyCtrl.text = s.localLlmApiKey;
      }
      if (_geminiModelCtrl.text.isEmpty || oldWidget.viewModel.settings.geminiModel != s.geminiModel) {
        _geminiModelCtrl.text = s.geminiModel;
      }
    }
  }

  @override
  void dispose() {
    _localUrlCtrl.dispose();
    _localModelCtrl.dispose();
    _localKeyCtrl.dispose();
    _geminiModelCtrl.dispose();
    _geminiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    try {
      await widget.viewModel.saveLlmSettings(
        provider: _provider,
        localLlmUrl: _localUrlCtrl.text.trim(),
        localLlmModel: _localModelCtrl.text.trim(),
        localLlmApiKey: _localKeyCtrl.text.trim(),
        geminiModel: _geminiModelCtrl.text.trim(),
        geminiApiKey: _geminiKeyCtrl.text.trim(),
      );
      _geminiKeyCtrl.clear();
      _userSwitchedProvider = false;
      if (mounted) {
        IosToast.show(context, 'Pengaturan model AI berhasil disimpan!', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        IosToast.show(context, e.toString(), type: ToastType.error);
      }
    }
  }

  Future<void> _handleTest() async {
    try {
      await widget.viewModel.testLlm(
        provider: _provider,
        localLlmUrl: _localUrlCtrl.text.trim(),
        localLlmModel: _localModelCtrl.text.trim(),
        localLlmApiKey: _localKeyCtrl.text.trim(),
        geminiModel: _geminiModelCtrl.text.trim(),
        geminiApiKey: _geminiKeyCtrl.text.trim(),
      );
      final res = widget.viewModel.testResult;
      final ok = res?['ok'] == true;
      final msg = res?['message'] ?? (ok ? 'Koneksi AI berhasil!' : 'Koneksi gagal');
      if (mounted) {
        IosToast.show(context, msg.toString(), type: ok ? ToastType.success : ToastType.error);
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
    final s = widget.viewModel.settings;
    final testResult = widget.viewModel.testResult;

    return IosCard(
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
                child: Icon(CupertinoIcons.sparkles, size: 16, color: IosColors.statusGreen),
              ),
              const SizedBox(width: 10),
              const Text(
                'Model AI & Generator',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Pilih engine AI untuk generate logbook: Local LLM (offline LAN) atau Google Gemini Cloud API.',
            style: TextStyle(
              fontSize: 12,
              color: IosColors.secondaryLabel(context),
            ),
          ),
          const SizedBox(height: 14),

          // Provider selector
          CupertinoSlidingSegmentedControl<String>(
            groupValue: _provider,
            children: {
              'local': Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.cube, size: 13, color: IosColors.statusGreen),
                    SizedBox(width: 6),
                    Text('Local LLM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              'gemini': Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.sparkles, size: 13, color: IosColors.statusAmber),
                    SizedBox(width: 6),
                    Text('Google Gemini', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            },
            onValueChanged: (val) {
              if (val != null) {
                setState(() {
                  _provider = val;
                  _userSwitchedProvider = true;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Form fields based on selected provider
          if (_provider == 'local') ...[
            _buildField(
              context: context,
              label: 'URL Local LLM Server',
              controller: _localUrlCtrl,
              placeholder: 'http://192.168.13.155:3000',
            ),
            const SizedBox(height: 12),
            _buildField(
              context: context,
              label: 'Model Name',
              controller: _localModelCtrl,
              placeholder: 'gpt-oss-20b',
            ),
            const SizedBox(height: 12),
            _buildField(
              context: context,
              label: 'API Key (Opsional)',
              controller: _localKeyCtrl,
              placeholder: 'Kosongkan jika tanpa auth',
              isSecret: true,
            ),
          ] else ...[
            _buildField(
              context: context,
              label: 'Gemini Model',
              controller: _geminiModelCtrl,
              placeholder: 'gemini-3.6-flash',
            ),
            const SizedBox(height: 12),
            _buildField(
              context: context,
              label: 'Gemini API Key',
              controller: _geminiKeyCtrl,
              placeholder: s.hasApiKey ? 'Tersimpan: ${s.apiKeyMasked}' : 'AIzaSy...',
              isSecret: true,
            ),
            if (s.hasApiKey)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'API Key sudah tersimpan di server. Isi kembali hanya jika ingin mengganti.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: IosColors.secondaryLabel(context),
                  ),
                ),
              ),
          ],

          // Test results if any
          if (testResult != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: testResult['ok'] == true
                    ? IosColors.statusGreen.withValues(alpha: 0.15)
                    : IosColors.statusRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: testResult['ok'] == true ? IosColors.statusGreen : IosColors.statusRed,
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    testResult['ok'] == true ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.xmark_circle_fill,
                    size: 16,
                    color: testResult['ok'] == true ? IosColors.statusGreen : IosColors.statusRed,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      testResult['message'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: testResult['ok'] == true ? IosColors.statusGreen : IosColors.statusRed,
                      ),
                    ),
                  ),
                  if (testResult['latencyMs'] != null)
                    Text(
                      '${testResult['latencyMs']}ms',
                      style: const TextStyle(fontFamily: 'Courier', fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IosButton(
                text: 'Tes Koneksi AI',
                variant: IosButtonVariant.secondary,
                size: IosButtonSize.small,
                isLoading: widget.viewModel.isTestingLlm,
                onPressed: _handleTest,
              ),
              const SizedBox(width: 8),
              IosButton(
                text: 'Simpan AI',
                variant: IosButtonVariant.primary,
                size: IosButtonSize.small,
                isLoading: widget.viewModel.isSavingLlm,
                onPressed: _handleSave,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required String placeholder,
    bool isSecret = false,
  }) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: IosColors.secondaryLabel(context),
          ),
        ),
        const SizedBox(height: 5),
        CupertinoTextField(
          controller: controller,
          obscureText: isSecret,
          placeholder: placeholder,
          placeholderStyle: TextStyle(
            fontSize: 13,
            color: IosColors.tertiaryLabel(context),
          ),
          style: const TextStyle(fontFamily: 'Courier', fontSize: 13),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141416) : const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
              width: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}
