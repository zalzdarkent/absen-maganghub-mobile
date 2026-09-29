import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/commit_model.dart';
import '../../domain/models/repository_model.dart';
import '../../domain/models/status_model.dart';

class GitHubRepoInfo {
  final String owner;
  final String repo;
  final String? authToken;

  const GitHubRepoInfo({
    required this.owner,
    required this.repo,
    this.authToken,
  });
}

class GithubService {
  final http.Client _client;

  GithubService({http.Client? client}) : _client = client ?? http.Client();

  static GitHubRepoInfo? parseGitHubRepo(String value) {
    var raw = value.trim();
    raw = raw
        .replaceAll(RegExp(r'^git@github\.com:', caseSensitive: false), 'https://github.com/')
        .replaceAll(RegExp(r'^ssh:\/\/git@github\.com\/', caseSensitive: false), 'https://github.com/');

    final reg = RegExp(r'^https?:\/\/(?:[^/@]+(?::[^/@]*)?@)?github\.com\/([^/]+)\/([^/]+?)(?:\.git)?\/?$', caseSensitive: false);
    final match = reg.firstMatch(raw);
    if (match != null) {
      return GitHubRepoInfo(
        owner: match.group(1)!,
        repo: match.group(2)!,
      );
    }

    // Also support "owner/repo" shorthand
    final shortReg = RegExp(r'^([a-zA-Z0-9._-]+)\/([a-zA-Z0-9._-]+)$');
    final shortMatch = shortReg.firstMatch(raw);
    if (shortMatch != null) {
      return GitHubRepoInfo(
        owner: shortMatch.group(1)!,
        repo: shortMatch.group(2)!,
      );
    }

    return null;
  }

  Map<String, String> _buildHeaders(String? token) {
    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'MagangHub-iOS-Flutter',
      'Cache-Control': 'no-cache',
    };
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'token ${token.trim()}';
    }
    return headers;
  }

  Future<List<Commit>> fetchTodayCommitsForRepo({
    required String repoUrl,
    required String repoId,
    required String repoLabel,
    String? token,
    int maxCommits = 8,
  }) async {
    final info = parseGitHubRepo(repoUrl);
    if (info == null) return [];

    final now = DateTime.now();
    final since = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();

    // Do not pass until: commits cannot be in the future, and device clock drift
    // could otherwise filter out recent commits.
    final uri = Uri.parse(
      'https://api.github.com/repos/${info.owner}/${info.repo}/commits?since=$since&per_page=50',
    );

    try {
      final res = await _client.get(uri, headers: _buildHeaders(token)).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) {
        return [];
      }

      final list = jsonDecode(res.body);
      if (list is! List) return [];

      final commitsToFetch = list.take(maxCommits).toList();
      final results = await Future.wait(commitsToFetch.map((c) async {
        final sha = (c['sha'] as String?) ?? '';
        final commitObj = c['commit'] as Map<String, dynamic>? ?? {};
        final message = (commitObj['message'] as String?)?.split('\n').first ?? 'commit';
        final authorObj = c['author'] as Map<String, dynamic>?;
        final authorName = (authorObj?['login'] as String?) ??
            (commitObj['author']?['name'] as String?) ??
            'unknown';
        final date = (commitObj['author']?['date'] as String?) ?? '';
        final htmlUrl = (c['html_url'] as String?) ?? '';

        // Try to fetch commit diff for stats & patch
        List<CommitFile> files = [];
        String patch = '';
        String stats = '';

        if (sha.isNotEmpty) {
          try {
            final diffUri = Uri.parse('https://api.github.com/repos/${info.owner}/${info.repo}/commits/$sha');
            final diffRes = await _client.get(diffUri, headers: _buildHeaders(token)).timeout(const Duration(seconds: 5));
            if (diffRes.statusCode == 200) {
              final diffData = jsonDecode(diffRes.body);
              final rawFiles = diffData['files'] as List<dynamic>? ?? [];
              files = rawFiles.take(4).map((f) {
                final fname = (f['filename'] as String?) ?? '';
                final fstatus = (f['status'] as String?) ?? 'modified';
                final fadds = (f['additions'] as int?) ?? 0;
                final fdels = (f['deletions'] as int?) ?? 0;
                final fpatch = (f['patch'] as String?) ?? '';
                return CommitFile(
                  filename: fname,
                  status: fstatus,
                  additions: fadds,
                  deletions: fdels,
                  patch: fpatch.length > 800 ? '${fpatch.substring(0, 800)}\n...(diff dipotong)' : fpatch,
                );
              }).toList();

              stats = files.map((f) => '${f.filename} (+${f.additions}/-${f.deletions} ${f.status})').join(', ');
              patch = files.map((f) => '--- ${f.filename} [${f.status} +${f.additions}/-${f.deletions}]\n${f.patch}').join('\n\n');
            }
          } catch (_) {}
        }

        return Commit(
          sha: sha,
          shortSha: sha.length > 7 ? sha.substring(0, 7) : sha,
          message: message,
          author: authorName,
          date: date,
          url: htmlUrl,
          files: files,
          stats: stats,
          patch: patch,
          repoId: repoId,
          repoLabel: repoLabel,
        );
      }));

      return results;
    } catch (_) {
      return [];
    }
  }

  Future<CommitDiffResponse> fetchCommitDiff(String repoUrl, String sha, {String? token}) async {
    final info = parseGitHubRepo(repoUrl);
    if (info == null) {
      return CommitDiffResponse(sha: sha, patch: 'URL repository tidak valid');
    }

    try {
      final diffUri = Uri.parse('https://api.github.com/repos/${info.owner}/${info.repo}/commits/$sha');
      final res = await _client.get(diffUri, headers: _buildHeaders(token)).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        return CommitDiffResponse(sha: sha, patch: 'Gagal mengambil diff dari GitHub (HTTP ${res.statusCode})');
      }

      final data = jsonDecode(res.body);
      final message = (data['commit']?['message'] as String?)?.split('\n').first ?? 'commit';
      final rawFiles = data['files'] as List<dynamic>? ?? [];
      final files = rawFiles.map((f) {
        return CommitFile(
          filename: (f['filename'] as String?) ?? '',
          status: (f['status'] as String?) ?? 'modified',
          additions: (f['additions'] as int?) ?? 0,
          deletions: (f['deletions'] as int?) ?? 0,
          patch: (f['patch'] as String?) ?? '',
        );
      }).toList();

      final patch = files.map((f) => '--- ${f.filename} [${f.status} +${f.additions}/-${f.deletions}]\n${f.patch}').join('\n\n');

      return CommitDiffResponse(
        sha: sha,
        message: message,
        files: files,
        patch: patch,
      );
    } catch (e) {
      return CommitDiffResponse(sha: sha, patch: 'Error mengambil diff: $e');
    }
  }

  Future<StatusResponse> fetchCombinedStatus({
    required List<Repository> repositories,
    required List<String> selectedRepoIds,
    String? token,
  }) async {
    final targetRepos = repositories.where((r) => selectedRepoIds.contains(r.id)).toList();
    if (targetRepos.isEmpty && repositories.isNotEmpty) {
      targetRepos.add(repositories.first);
    }

    final allCommits = <Commit>[];
    final partsLogs = <String>[];
    final partsDetailed = <String>[];

    final fetchTasks = targetRepos.map((repo) async {
      final commits = await fetchTodayCommitsForRepo(
        repoUrl: repo.url,
        repoId: repo.id,
        repoLabel: repo.label,
        token: token,
      );
      return MapEntry(repo, commits);
    });

    final results = await Future.wait(fetchTasks);

    for (final entry in results) {
      final repo = entry.key;
      final commits = entry.value;
      if (commits.isNotEmpty) {
        allCommits.addAll(commits);
        final repoLogs = commits.map((c) => '- ${c.message} (${c.author})').join('\n');
        partsLogs.add('=== REPO: ${repo.label} ===\n$repoLogs');

        final repoDetailed = commits.asMap().entries.map((mapEntry) {
          final idx = mapEntry.key + 1;
          final c = mapEntry.value;
          return '### $idx. ${c.message} (${c.author}) [${c.shortSha}]\nFiles: ${c.stats}\nDiff:\n${c.patch}';
        }).join('\n\n---\n\n');
        partsDetailed.add('=== REPO: ${repo.label} ===\n$repoDetailed');
      }
    }

    final combinedLogs = partsLogs.join('\n\n');
    var combinedDetailed = partsDetailed.join('\n\n===================\n\n');
    if (combinedDetailed.length > 9000) {
      combinedDetailed = '${combinedDetailed.substring(0, 9000)}\n... (diff dipotong)';
    }

    return StatusResponse(
      gitLogs: combinedLogs,
      commits: allCommits,
      detailed: combinedDetailed,
      hasCommitsToday: allCommits.isNotEmpty,
      alreadyGenerated: false,
      repoIds: targetRepos.map((r) => r.id).toList(),
    );
  }
}
