import 'repository_model.dart';

class SettingsModel {
  final String repoPath;
  final bool persistentSettings;
  final bool isVercel;
  final List<Repository> repositories;
  final String? activeRepoId;
  final List<String> defaultRepoIds;
  final String llmProvider; // 'local' | 'gemini'
  final String localLlmUrl;
  final String localLlmModel;
  final String localLlmApiKey;
  final String geminiModel;
  final String geminiApiKey;
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
    this.localLlmUrl = 'http://192.168.13.155:3000',
    this.localLlmModel = 'gpt-oss-20b',
    this.localLlmApiKey = '',
    this.geminiModel = 'gemini-3.6-flash',
    this.geminiApiKey = '',
    this.githubToken = '',
    this.hasApiKey = false,
    this.apiKeyMasked = '',
  });

  bool get isLocalLlm => llmProvider == 'local';
  bool get isGemini => llmProvider == 'gemini';

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    final gemKey = json['geminiApiKey'] as String? ?? '';
    final hasKey = json['hasApiKey'] as bool? ?? (gemKey.isNotEmpty);
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
      llmProvider: json['llmProvider'] as String? ?? 'local',
      localLlmUrl:
          json['localLlmUrl'] as String? ?? 'http://192.168.13.155:3000',
      localLlmModel: json['localLlmModel'] as String? ?? 'gpt-oss-20b',
      localLlmApiKey: json['localLlmApiKey'] as String? ?? '',
      geminiModel: json['geminiModel'] as String? ?? 'gemini-3.6-flash',
      geminiApiKey: gemKey,
      githubToken: json['githubToken'] as String? ?? '',
      hasApiKey: hasKey,
      apiKeyMasked: json['apiKeyMasked'] as String? ??
          (gemKey.isNotEmpty && gemKey.length > 8
              ? '${gemKey.substring(0, 4)}••••${gemKey.substring(gemKey.length - 4)}'
              : ''),
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
      'geminiModel': geminiModel,
      'geminiApiKey': geminiApiKey,
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
    String? geminiModel,
    String? geminiApiKey,
    String? githubToken,
    bool? hasApiKey,
    String? apiKeyMasked,
  }) {
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
      geminiModel: geminiModel ?? this.geminiModel,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      githubToken: githubToken ?? this.githubToken,
      hasApiKey: hasApiKey ?? this.hasApiKey,
      apiKeyMasked: apiKeyMasked ?? this.apiKeyMasked,
    );
  }
}
