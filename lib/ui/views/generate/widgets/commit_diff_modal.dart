import 'package:flutter/cupertino.dart';
import '../../../../core/theme/ios_colors.dart';
import '../../../../domain/models/commit_model.dart';
import '../../../view_models/generate_view_model.dart';

class CommitDiffModal extends StatefulWidget {
  final Commit commit;
  final GenerateViewModel viewModel;

  const CommitDiffModal({
    super.key,
    required this.commit,
    required this.viewModel,
  });

  @override
  State<CommitDiffModal> createState() => _CommitDiffModalState();
}

class _CommitDiffModalState extends State<CommitDiffModal> {
  CommitDiffResponse? _diff;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDiff();
  }

  Future<void> _loadDiff() async {
    final sha = widget.commit.sha;
    if (sha == null || sha.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'SHA commit tidak tersedia';
      });
      return;
    }

    try {
      final res = await widget.viewModel.getCommitDiff(sha);
      if (mounted) {
        setState(() {
          _diff = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final codeBg = isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA);
    final borderColor = isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE);

    return Column(
      children: [
        // Commit Header Summary
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF21262D) : const Color(0xFFEAEFF5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Text(
                      widget.commit.displaySha,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: IosColors.statusGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.commit.repoLabel != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: IosColors.statusBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        widget.commit.repoLabel!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: IosColors.statusBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.commit.author ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: IosColors.secondaryLabel(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.commit.displayMessage,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_diff?.stats != null || widget.commit.stats != null) ...[
                const SizedBox(height: 4),
                Text(
                  _diff?.stats ?? widget.commit.stats ?? '',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 11,
                    color: IosColors.secondaryLabel(context),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Diff Content
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CupertinoActivityIndicator(radius: 14),
                )
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: IosColors.statusRed, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: codeBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor, width: 0.8),
                        ),
                        child: Text(
                          _diff?.patch != null && _diff!.patch!.isNotEmpty
                              ? _diff!.patch!
                              : (widget.commit.patch ?? 'Tidak ada perubahan file pada commit ini.'),
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 11.5,
                            height: 1.5,
                            color: isDark ? const Color(0xFFC9D1D9) : const Color(0xFF24292F),
                          ),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}
