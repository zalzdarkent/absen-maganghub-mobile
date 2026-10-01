import 'package:flutter/cupertino.dart';
import '../../../../core/constants/api_constants.dart';
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
  late String _provider; // 'local' | 'cloud'
  late String _cloudPreset; // 'groq' | 'gemini' | 'openrouter' | 'custom'
  bool _userSwitchedProvider = false;

  late TextEditingController _localUrlCtrl;
  late TextEditingController _localModelCtrl;
  late TextEditingController _localKeyCtrl;

  late TextEditingController _cloudModelCtrl;
  late TextEditingController _cloudKeyCtrl;
  late TextEditingController _cloudUrlCtrl;

  @override
  void initState() {
    super.initState();
    final s = widget.viewModel.settings;
    _provider = s.isLocalLlm ? 'local' : 'cloud';
    _cloudPreset = s.cloudProvider.isNotEmpty ? s.cloudProvider : 'groq';

    _localUrlCtrl = TextEditingController(text: s.localLlmUrl);
    _localModelCtrl = TextEditingController(text: s.localLlmModel.isNotEmpty ? s.localLlmModel : 'gpt-oss-20b');
    _localKeyCtrl = TextEditingController(text: s.localLlmApiKey);

    _cloudModelCtrl = TextEditingController(text: s.cloudModel.isNotEmpty ? s.cloudModel : ApiConstants.defaultGroqModel);
    _cloudModelCtrl.addListener(() => setState(() {}));
    _cloudKeyCtrl = TextEditingController();
    _cloudUrlCtrl = TextEditingController(text: s.cloudUrl.isNotEmpty ? s.cloudUrl : ApiConstants.defaultGroqUrl);
  }

  @override
  void didUpdateWidget(covariant AiProviderSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel.settings != widget.viewModel.settings) {
      final s = widget.viewModel.settings;
      if (!_userSwitchedProvider) {
        _provider = s.isLocalLlm ? 'local' : 'cloud';
        _cloudPreset = s.cloudProvider.isNotEmpty ? s.cloudProvider : 'groq';
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
      if (_cloudModelCtrl.text.isEmpty || oldWidget.viewModel.settings.cloudModel != s.cloudModel) {
        _cloudModelCtrl.text = s.cloudModel.isNotEmpty ? s.cloudModel : ApiConstants.defaultGroqModel;
      }
      if (_cloudUrlCtrl.text.isEmpty || oldWidget.viewModel.settings.cloudUrl != s.cloudUrl) {
        _cloudUrlCtrl.text = s.cloudUrl.isNotEmpty ? s.cloudUrl : ApiConstants.defaultGroqUrl;
      }
    }
  }

  @override
  void dispose() {
    _localUrlCtrl.dispose();
    _localModelCtrl.dispose();
    _localKeyCtrl.dispose();
    _cloudModelCtrl.dispose();
    _cloudKeyCtrl.dispose();
    _cloudUrlCtrl.dispose();
    super.dispose();
  }

  void _onSelectPreset(String preset) {
    setState(() {
      _cloudPreset = preset;
      if (preset == 'groq') {
        _cloudModelCtrl.text = ApiConstants.defaultGroqModel;
        _cloudUrlCtrl.text = ApiConstants.defaultGroqUrl;
      } else if (preset == 'gemini') {
        _cloudModelCtrl.text = ApiConstants.defaultGeminiModel;
        _cloudUrlCtrl.text = ApiConstants.defaultGeminiUrl;
      } else if (preset == 'openrouter') {
        _cloudModelCtrl.text = ApiConstants.defaultOpenRouterModel;
        _cloudUrlCtrl.text = ApiConstants.defaultOpenRouterUrl;
      } else if (preset == 'custom') {
        if (_cloudUrlCtrl.text.contains('groq') || _cloudUrlCtrl.text.contains('googleapis')) {
          _cloudUrlCtrl.text = '';
        }
      }
    });
  }

  Future<void> _handleSave() async {
    try {
      await widget.viewModel.saveLlmSettings(
        provider: _provider,
        localLlmUrl: _localUrlCtrl.text.trim(),
        localLlmModel: _localModelCtrl.text.trim(),
        localLlmApiKey: _localKeyCtrl.text.trim(),
        cloudProvider: _cloudPreset,
        cloudModel: _cloudModelCtrl.text.trim(),
        cloudUrl: _cloudUrlCtrl.text.trim(),
        cloudApiKey: _cloudKeyCtrl.text.trim(),
      );
      _cloudKeyCtrl.clear();
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
        cloudProvider: _cloudPreset,
        cloudModel: _cloudModelCtrl.text.trim(),
        cloudUrl: _cloudUrlCtrl.text.trim(),
        cloudApiKey: _cloudKeyCtrl.text.trim(),
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
            'Pilih engine AI untuk generate logbook: Local LLM (offline LAN) atau Cloud AI gratis (Groq, Gemini, OpenRouter).',
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.cube, size: 13, color: IosColors.statusGreen),
                    const SizedBox(width: 6),
                    const Text('Local LLM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              'cloud': Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.sparkles, size: 13, color: IosColors.statusAmber),
                    const SizedBox(width: 6),
                    const Text('Cloud AI (Gratis)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
            // Preset selection
            Text(
              'PILIH PROVIDER CLOUD GRATIS',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: IosColors.secondaryLabel(context),
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildPresetChip('groq', 'Groq (Kilat & Gratis)', CupertinoIcons.bolt_fill, IosColors.statusAmber),
                _buildPresetChip('gemini', 'Google Gemini', CupertinoIcons.sparkles, const Color(0xFF4285F4)),
                _buildPresetChip('openrouter', 'OpenRouter', CupertinoIcons.globe, IosColors.statusGreen),
                _buildPresetChip('custom', 'Custom API', CupertinoIcons.slider_horizontal_3, IosColors.secondaryLabel(context)),
              ],
            ),
            const SizedBox(height: 12),

            // Information banner about selected preset
            _buildPresetInfoCard(context, _cloudPreset),
            const SizedBox(height: 14),

            _buildField(
              context: context,
              label: 'Model Name',
              controller: _cloudModelCtrl,
              placeholder: _cloudPreset == 'groq'
                  ? 'llama-3.1-8b-instant'
                  : (_cloudPreset == 'gemini' ? 'gemini-1.5-flash' : 'nama model'),
            ),
            if (_cloudPreset == 'groq') ...[
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickModelChip('llama-3.1-8b-instant', '⚡ Llama 3.1 8B (Kilat & Rekomendasi)'),
                    const SizedBox(width: 6),
                    _buildQuickModelChip('llama3-70b-8192', 'Llama 3 70B (8k)'),
                    const SizedBox(width: 6),
                    _buildQuickModelChip('llama-3.3-70b-versatile', 'Llama 3.3 70B'),
                    const SizedBox(width: 6),
                    _buildQuickModelChip('mixtral-8x7b-32768', 'Mixtral 8x7B'),
                    const SizedBox(width: 6),
                    _buildQuickModelChip('gemma2-9b-it', 'Gemma 2 9B'),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _handleFetchAvailableModels,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.viewModel.isFetchingModels
                            ? CupertinoIcons.arrow_2_circlepath
                            : CupertinoIcons.search,
                        size: 13,
                        color: IosColors.systemBlue,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.viewModel.isFetchingModels
                            ? 'Sedang memeriksa model...'
                            : '🔍 Ambil Daftar Model Aktif di Akun Groq Saya',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: IosColors.systemBlue,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_cloudPreset == 'gemini') ...[
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickModelChip('gemini-1.5-flash', '⚡ Gemini 1.5 Flash (Kilat)'),
                    const SizedBox(width: 6),
                    _buildQuickModelChip('gemini-1.5-pro', 'Gemini 1.5 Pro'),
                    const SizedBox(width: 6),
                    _buildQuickModelChip('gemini-2.0-flash', 'Gemini 2.0 Flash'),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _handleFetchAvailableModels,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.viewModel.isFetchingModels
                            ? CupertinoIcons.arrow_2_circlepath
                            : CupertinoIcons.search,
                        size: 13,
                        color: IosColors.systemBlue,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.viewModel.isFetchingModels
                            ? 'Sedang memeriksa model...'
                            : '🔍 Ambil Model Aktif dari Google AI Studio',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: IosColors.systemBlue,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_cloudModelCtrl.text.toLowerCase().contains('prompt-guard') || _cloudModelCtrl.text.toLowerCase().contains('guard')) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: IosColors.statusAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: IosColors.statusAmber.withValues(alpha: 0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 14, color: IosColors.statusAmber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Model Prompt Guard adalah classifier keamanan (deteksi jailbreak/injeksi teks) dan tidak bisa generate paragraf logbook. Disarankan gunakan "llama-3.1-8b-instant" untuk hasil logbook yang lengkap.',
                        style: TextStyle(fontSize: 11, color: IosColors.label(context), height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),

            if (_cloudPreset == 'custom' || _cloudPreset == 'openrouter') ...[
              _buildField(
                context: context,
                label: 'Endpoint URL',
                controller: _cloudUrlCtrl,
                placeholder: 'https://api.domain.com/v1/chat/completions',
              ),
              const SizedBox(height: 12),
            ],

            _buildField(
              context: context,
              label: 'API Key ${_getPresetDisplayName(_cloudPreset)}',
              controller: _cloudKeyCtrl,
              placeholder: s.hasApiKey ? 'Tersimpan: ${s.apiKeyMasked}' : _getPresetKeyPlaceholder(_cloudPreset),
              isSecret: true,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                s.hasApiKey
                    ? 'API Key sudah tersimpan di database lokal. Isi hanya jika ingin mengganti key baru.'
                    : 'Paste API Key dari konsol provider di atas.',
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

  Widget _buildPresetChip(String preset, String title, IconData icon, Color color) {
    final isSelected = _cloudPreset == preset;
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _onSelectPreset(preset),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.18)
              : (isDark ? const Color(0xFF1E1E20) : const Color(0xFFF2F2F7)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)),
            width: isSelected ? 1.4 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isSelected ? color : IosColors.secondaryLabel(context)),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? (isDark ? CupertinoColors.white : CupertinoColors.black) : IosColors.secondaryLabel(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetInfoCard(BuildContext context, String preset) {
    String message;
    IconData icon;
    Color color;

    if (preset == 'groq') {
      icon = CupertinoIcons.bolt_fill;
      color = IosColors.statusAmber;
      message = '⭐ Rekomendasi Utama: 100% gratis tanpa kartu kredit! Model "llama-3.1-8b-instant" responnya kilat (<1 detik) & bebas limit di semua akun Groq. Untuk model 70B, sebagian akun menggunakan "llama3-70b-8192".';
    } else if (preset == 'gemini') {
      icon = CupertinoIcons.sparkles;
      color = const Color(0xFF4285F4);
      message = '✨ Google Gemini resmi gratis di aistudio.google.com (15 RPM / 1.500 request/hari). Model default gemini-1.5-flash stabil dan tidak lagi error 404.';
    } else if (preset == 'openrouter') {
      icon = CupertinoIcons.globe;
      color = IosColors.statusGreen;
      message = '🌐 OpenRouter menyediakan banyak model open-source gratis (:free). Dapatkan API key di openrouter.ai.';
    } else {
      icon = CupertinoIcons.slider_horizontal_3;
      color = IosColors.secondaryLabel(context);
      message = '⚙️ Custom API: Mendukung endpoint chat completions OpenAI-compatible apa pun.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11,
                height: 1.35,
                color: IosColors.label(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPresetDisplayName(String preset) {
    switch (preset) {
      case 'groq':
        return 'Groq';
      case 'gemini':
        return 'Google Gemini';
      case 'openrouter':
        return 'OpenRouter';
      default:
        return 'Cloud AI';
    }
  }

  String _getPresetKeyPlaceholder(String preset) {
    switch (preset) {
      case 'groq':
        return 'gsk_...';
      case 'gemini':
        return 'AIzaSy...';
      case 'openrouter':
        return 'sk-or-v1-...';
      default:
        return 'sk-...';
    }
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

  Widget _buildQuickModelChip(String modelName, String label) {
    final isSelected = _cloudModelCtrl.text == modelName;
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _cloudModelCtrl.text = modelName;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? IosColors.statusGreen.withValues(alpha: 0.18)
              : (isDark ? const Color(0xFF1E1E20) : const Color(0xFFF2F2F7)),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? IosColors.statusGreen : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)),
            width: isSelected ? 1.0 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? IosColors.statusGreen
                : IosColors.secondaryLabel(context),
          ),
        ),
      ),
    );
  }

  Future<void> _handleFetchAvailableModels() async {
    if (widget.viewModel.isFetchingModels) return;

    final s = widget.viewModel.settings;
    final apiKey = _cloudKeyCtrl.text.trim().isNotEmpty
        ? _cloudKeyCtrl.text.trim()
        : s.cloudApiKey;

    if (apiKey.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('API Key Diperlukan'),
          content: Text('Masukkan API Key ${_getPresetDisplayName(_cloudPreset)} terlebih dahulu pada kolom API Key di bawah agar sistem dapat memeriksa model yang aktif pada akun Anda.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final models = await widget.viewModel.fetchAvailableModels(
        provider: _cloudPreset,
        apiKey: apiKey,
        customUrl: _cloudUrlCtrl.text.trim(),
      );

      if (!mounted) return;

      if (models.isEmpty) {
        IosToast.show(context, 'Tidak ada model teks yang ditemukan pada akun ini.', type: ToastType.error);
        return;
      }

      _showModelPickerModal(models);
    } catch (e) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Gagal Memeriksa Model'),
          content: Text(e.toString().replaceAll('Exception: ', '')),
          actions: [
            CupertinoDialogAction(
              child: const Text('Tutup'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    }
  }

  void _showModelPickerModal(List<String> models) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 420,
        decoration: BoxDecoration(
          color: CupertinoTheme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(CupertinoIcons.square_list_fill, size: 18, color: IosColors.systemBlue),
                        const SizedBox(width: 8),
                        Text(
                          'Model Aktif di Akun (${models.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Selesai'),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pilih model yang ingin digunakan untuk generate logbook:',
                    style: TextStyle(fontSize: 11.5, color: IosColors.secondaryLabel(context)),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(height: 0.5, color: IosColors.separator(context)),
              Expanded(
                child: ListView.separated(
                  itemCount: models.length,
                  separatorBuilder: (context, index) => Container(
                    height: 0.5,
                    color: IosColors.separator(context),
                    margin: const EdgeInsets.only(left: 16),
                  ),
                  itemBuilder: (context, idx) {
                    final m = models[idx];
                    final isCurrent = _cloudModelCtrl.text.trim() == m;
                    final isRecommended = m == 'llama-3.1-8b-instant' || m == 'gemini-1.5-flash';
                    return CupertinoListTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              m,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                color: isCurrent ? IosColors.statusGreen : IosColors.label(context),
                              ),
                            ),
                          ),
                          if (isRecommended)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: IosColors.statusGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Rekomendasi',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: IosColors.statusGreen,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: isCurrent
                          ? Icon(CupertinoIcons.checkmark_alt, color: IosColors.statusGreen, size: 18)
                          : null,
                      onTap: () {
                        setState(() {
                          _cloudModelCtrl.text = m;
                        });
                        Navigator.pop(ctx);
                        IosToast.show(context, 'Model dipilih: $m', type: ToastType.success);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
