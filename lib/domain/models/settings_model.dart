import '../../core/constants/api_constants.dart';
import 'repository_model.dart';

class SettingsModel {
  final String repoPath;
  final bool persistentSettings;
  final bool isVercel;
  final List<Repository> repositories;
  final String? activeRepoId;
  final List<String> defaultRepoIds;
  final String llmProvider; // 'local' | 'cloud' (legacy 'opencode' | 'gemini')
  final String localLlmUrl;
  final String localLlmModel;
  final String localLlmApiKey;

  // Cloud AI configuration & presets
  final String cloudProvider; // 'groq' | 'gemini' | 'openrouter' | 'opencode' | 'custom'
  final String cloudModel;
  final String cloudUrl;
  final String cloudApiKey;

  final String githubToken;
  final bool hasApiKey;
  final String apiKeyMasked;

  const SettingsModel({
    this.repoPath = '',
    this.persistentSettings = true,
    this.isVercel = false,
    this.repositories = const [],
    this.activeRepoId,
    this.defaultRepoIds = const [],
    this.llmProvider = 'local',
    this.localLlmUrl = ApiConstants.defaultLocalLlmUrl,
    this.localLlmModel = ApiConstants.defaultLocalLlmModel,
    this.localLlmApiKey = '',
    this.cloudProvider = 'groq',
    String? cloudModel,
    String? cloudUrl,
    String? cloudApiKey,
    String? openCodeModel,
    String? openCodeApiKey,
    String? geminiModel,
    String? geminiApiKey,
    this.githubToken = '',
    this.hasApiKey = false,
    this.apiKeyMasked = '',
  })  : cloudModel = cloudModel ?? openCodeModel ?? geminiModel ?? ApiConstants.defaultGroqModel,
        cloudUrl = cloudUrl ??
            ((openCodeModel == 'big-pickle' || cloudModel == 'big-pickle')
                ? ApiConstants.defaultOpenCodeUrl
                : ApiConstants.defaultGroqUrl),
        cloudApiKey = cloudApiKey ?? openCodeApiKey ?? geminiApiKey ?? '';

  // Backward compatibility getters
  String get openCodeModel => cloudModel;
  String get openCodeApiKey => cloudApiKey;
  String get geminiModel => cloudModel;
  String get geminiApiKey => cloudApiKey;
  bool get isLocalLlm => llmProvider == 'local';
  bool get isCloud => llmProvider != 'local';
  bool get isOpenCode => isCloud;
  bool get isGemini => isCloud;

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    final rawKey = json['cloudApiKey'] as String? ??
        json['openCodeApiKey'] as String? ??
        json['geminiApiKey'] as String? ??
        json['apiKey'] as String? ??
        '';

    final rawProvider = json['llmProvider'] as String? ?? 'local';
    final provider = rawProvider == 'gemini' ? 'opencode' : rawProvider;

    final rawCloudProvider = json['cloudProvider'] as String?;
    String cloudProvider = rawCloudProvider ?? (provider == 'opencode' ? 'opencode' : 'groq');

    final rawModel = json['cloudModel'] as String? ??
        json['openCodeModel'] as String? ??
        json['geminiModel'] as String?;

    String cloudModel;
    if (rawModel == null || rawModel.isEmpty || rawModel == 'gemini-3.6-flash') {
      cloudModel = cloudProvider == 'gemini'
          ? ApiConstants.defaultGeminiModel
          : (cloudProvider == 'openrouter'
              ? ApiConstants.defaultOpenRouterModel
              : (cloudProvider == 'opencode' ? 'big-pickle' : ApiConstants.defaultGroqModel));
    } else {
      cloudModel = rawModel;
    }

    final rawUrl = json['cloudUrl'] as String?;
    final cloudUrl = (rawUrl != null && rawUrl.isNotEmpty)
        ? rawUrl
        : (cloudProvider == 'gemini'
            ? ApiConstants.defaultGeminiUrl
            : (cloudProvider == 'openrouter'
                ? ApiConstants.defaultOpenRouterUrl
                : (cloudProvider == 'opencode' || cloudModel == 'big-pickle'
                    ? ApiConstants.defaultOpenCodeUrl
                    : ApiConstants.defaultGroqUrl)));

    final hasKey = json['hasApiKey'] as bool? ?? (rawKey.isNotEmpty);

    return SettingsModel(
      repoPath: json['repoPath'] as String? ?? '',
      persistentSettings: json['persistentSettings'] as bool? ?? true,
      isVercel: json['isVercel'] as bool? ?? false,
      repositories: (json['repositories'] as List<dynamic>?)
              ?.map((e) => Repository.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      activeRepoId: json['activeRepoId'] as String?,
      defaultRepoIds: (json['defaultRepoIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      llmProvider: provider,
      localLlmUrl: json['localLlmUrl'] as String? ?? ApiConstants.defaultLocalLlmUrl,
      localLlmModel: json['localLlmModel'] as String? ?? ApiConstants.defaultLocalLlmModel,
      localLlmApiKey: json['localLlmApiKey'] as String? ?? '',
      cloudProvider: cloudProvider,
      cloudModel: cloudModel,
      cloudUrl: cloudUrl,
      cloudApiKey: rawKey,
      githubToken: json['githubToken'] as String? ?? '',
      hasApiKey: hasKey,
      apiKeyMasked: json['apiKeyMasked'] as String? ??
          (rawKey.isNotEmpty && rawKey.length > 8
              ? '${rawKey.substring(0, 4)}••••${rawKey.substring(rawKey.length - 4)}'
              : (rawKey.isNotEmpty ? '••••••••' : '')),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'repoPath': repoPath,
      'persistentSettings': persistentSettings,
      'isVercel': isVercel,
      'repositories': repositories.map((r) => r.toJson()).toList(),
      if (activeRepoId != null) 'activeRepoId': activeRepoId,
      'defaultRepoIds': defaultRepoIds,
      'llmProvider': llmProvider,
      'localLlmUrl': localLlmUrl,
      'localLlmModel': localLlmModel,
      'localLlmApiKey': localLlmApiKey,
      'cloudProvider': cloudProvider,
      'cloudModel': cloudModel,
      'cloudUrl': cloudUrl,
      'cloudApiKey': cloudApiKey,
      // Legacy compatibility keys
      'openCodeModel': cloudModel,
      'openCodeApiKey': cloudApiKey,
      'geminiModel': cloudModel,
      'geminiApiKey': cloudApiKey,
      'githubToken': githubToken,
      'hasApiKey': hasApiKey,
      'apiKeyMasked': apiKeyMasked,
    };
  }

  SettingsModel copyWith({
    String? repoPath,
    bool? persistentSettings,
    bool? isVercel,
    List<Repository>? repositories,
    String? activeRepoId,
    List<String>? defaultRepoIds,
    String? llmProvider,
    String? localLlmUrl,
    String? localLlmModel,
    String? localLlmApiKey,
    String? cloudProvider,
    String? cloudModel,
    String? cloudUrl,
    String? cloudApiKey,
    String? openCodeModel,
    String? openCodeApiKey,
    String? geminiModel,
    String? geminiApiKey,
    String? githubToken,
    bool? hasApiKey,
    String? apiKeyMasked,
  }) {
    final effectiveCloudProvider = cloudProvider ?? this.cloudProvider;
    final effectiveModel = cloudModel ?? openCodeModel ?? geminiModel ?? this.cloudModel;
    final effectiveKey = cloudApiKey ?? openCodeApiKey ?? geminiApiKey ?? this.cloudApiKey;
    final effectiveUrl = cloudUrl ?? this.cloudUrl;

    return SettingsModel(
      repoPath: repoPath ?? this.repoPath,
      persistentSettings: persistentSettings ?? this.persistentSettings,
      isVercel: isVercel ?? this.isVercel,
      repositories: repositories ?? this.repositories,
      activeRepoId: activeRepoId ?? this.activeRepoId,
      defaultRepoIds: defaultRepoIds ?? this.defaultRepoIds,
      llmProvider: llmProvider ?? this.llmProvider,
      localLlmUrl: localLlmUrl ?? this.localLlmUrl,
      localLlmModel: localLlmModel ?? this.localLlmModel,
      localLlmApiKey: localLlmApiKey ?? this.localLlmApiKey,
      cloudProvider: effectiveCloudProvider,
      cloudModel: effectiveModel,
      cloudUrl: effectiveUrl,
      cloudApiKey: effectiveKey,
      githubToken: githubToken ?? this.githubToken,
      hasApiKey: hasApiKey ?? this.hasApiKey,
      apiKeyMasked: apiKeyMasked ?? this.apiKeyMasked,
    );
  }
}
