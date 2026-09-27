import 'commit_model.dart';

enum StatusKind { idle, ok, warn, err }

class StatusResponse {
  final String gitLogs;
  final List<Commit> commits;
  final String detailed;
  final bool hasCommitsToday;
  final bool alreadyGenerated;
  final List<String>? repoIds;

  const StatusResponse({
    this.gitLogs = '',
    this.commits = const [],
    this.detailed = '',
    this.hasCommitsToday = false,
    this.alreadyGenerated = false,
    this.repoIds,
  });

  StatusKind get statusKind {
    if (!hasCommitsToday) return StatusKind.warn;
    return StatusKind.ok;
  }

  String get statusText {
    if (!hasCommitsToday) return 'belum ada commit hari ini';
    if (alreadyGenerated) return 'sudah di-generate hari ini';
    return 'Siap!';
  }

  factory StatusResponse.fromJson(Map<String, dynamic> json) {
    return StatusResponse(
      gitLogs: json['gitLogs'] as String? ?? '',
      commits: (json['commits'] as List<dynamic>?)
              ?.map((e) => Commit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      detailed: json['detailed'] as String? ?? '',
      hasCommitsToday: json['hasCommitsToday'] as bool? ?? false,
      alreadyGenerated: json['alreadyGenerated'] as bool? ?? false,
      repoIds: (json['repoIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }
}
