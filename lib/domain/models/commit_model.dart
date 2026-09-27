class CommitFile {
  final String filename;
  final int additions;
  final int deletions;
  final String? patch;
  final String? status;

  const CommitFile({
    required this.filename,
    this.additions = 0,
    this.deletions = 0,
    this.patch,
    this.status,
  });

  factory CommitFile.fromJson(Map<String, dynamic> json) {
    return CommitFile(
      filename: json['filename'] as String? ?? '',
      additions: (json['additions'] as num?)?.toInt() ?? 0,
      deletions: (json['deletions'] as num?)?.toInt() ?? 0,
      patch: json['patch'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'additions': additions,
      'deletions': deletions,
      if (patch != null) 'patch': patch,
      if (status != null) 'status': status,
    };
  }
}

class Commit {
  final String? sha;
  final String? shortSha;
  final String? message;
  final String? subject;
  final String? author;
  final String? stats;
  final String? patch;
  final List<CommitFile>? files;
  final String? repoId;
  final String? repoLabel;
  final String? date;
  final String? url;

  const Commit({
    this.sha,
    this.shortSha,
    this.message,
    this.subject,
    this.author,
    this.stats,
    this.patch,
    this.files,
    this.repoId,
    this.repoLabel,
    this.date,
    this.url,
  });

  String get displaySha {
    if (shortSha != null && shortSha!.isNotEmpty) return shortSha!;
    if (sha != null && sha!.length >= 7) return sha!.substring(0, 7);
    return sha ?? '';
  }

  String get displayMessage {
    if (subject != null && subject!.isNotEmpty) return subject!;
    if (message != null && message!.isNotEmpty) {
      return message!.split('\n').first;
    }
    return 'Tanpa pesan commit';
  }

  factory Commit.fromJson(Map<String, dynamic> json) {
    return Commit(
      sha: json['sha'] as String?,
      shortSha: json['shortSha'] as String?,
      message: json['message'] as String?,
      subject: json['subject'] as String?,
      author: json['author'] as String?,
      stats: json['stats'] as String?,
      patch: json['patch'] as String?,
      files: (json['files'] as List<dynamic>?)
          ?.map((e) => CommitFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      repoId: json['repoId'] as String?,
      repoLabel: json['repoLabel'] as String?,
      date: json['date'] as String?,
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (sha != null) 'sha': sha,
      if (shortSha != null) 'shortSha': shortSha,
      if (message != null) 'message': message,
      if (subject != null) 'subject': subject,
      if (author != null) 'author': author,
      if (stats != null) 'stats': stats,
      if (patch != null) 'patch': patch,
      if (files != null) 'files': files!.map((f) => f.toJson()).toList(),
      if (repoId != null) 'repoId': repoId,
      if (repoLabel != null) 'repoLabel': repoLabel,
      if (date != null) 'date': date,
      if (url != null) 'url': url,
    };
  }
}

class CommitDiffResponse {
  final String? patch;
  final String? stats;
  final List<CommitFile>? files;
  final String? sha;
  final String? message;

  const CommitDiffResponse({
    this.patch,
    this.stats,
    this.files,
    this.sha,
    this.message,
  });

  factory CommitDiffResponse.fromJson(Map<String, dynamic> json) {
    return CommitDiffResponse(
      patch: json['patch'] as String?,
      stats: json['stats'] as String?,
      files: (json['files'] as List<dynamic>?)
          ?.map((e) => CommitFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      sha: json['sha'] as String?,
      message: json['message'] as String?,
    );
  }
}
