// lib/widgets/quiz_list_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/class_api.dart';
import 'package:flutter_codelab/constants/api_constants.dart';
import 'package:flutter_codelab/student/widgets/class/student_view_quiz_page.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';
import 'package:flutter_codelab/constants/class_constants.dart';

class QuizListSection extends StatefulWidget {
  final String roleName;
  final String classId;
  final String className;
  final String classDescription;

  const QuizListSection({
    Key? key,
    required this.roleName,
    required this.classId,
    required this.className,
    required this.classDescription,
  }) : super(key: key);

  @override
  State<QuizListSection> createState() => _QuizListSectionState();
}

class _QuizListSectionState extends State<QuizListSection> {
  bool _loading = true;
  List<Map<String, dynamic>> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _fetchQuizzes();
  }

  Future<void> _fetchQuizzes() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final quizzes = await ClassApi.getClassQuizzes(widget.classId);
      if (!mounted) return;
      setState(() {
        _quizzes = quizzes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      debugPrint('Error fetching quizzes: $e');
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(date.toString());
      return DateFormat('MMM d, yyyy').format(dateTime);
    } catch (e) {
      return 'Unknown';
    }
  }

  void _playQuiz(BuildContext context, Map<String, dynamic> quiz) {
    final levelId = quiz['level_id'];
    if (levelId == null) return;

    // Open Unity WebView with the level (same as game module)
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 1200,
          height: 800,
          child: Column(
            children: [
              // Header with close button
              Container(
                padding: EdgeInsets.all(ClassConstants.defaultPadding * 0.5),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      quiz['level_name'] ?? 'Quiz',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Unity WebView
              Expanded(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri(
                      "${ApiConstants.domain}/unity_build/index.html?role=${widget.roleName}&level=$levelId",
                    ),
                  ),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    isInspectable: false,
                  ),
                  onWebViewCreated: (controller) {},
                  onLoadStart: (controller, url) {
                    debugPrint("Started loading: $url");
                  },
                  onLoadStop: (controller, url) async {
                    debugPrint("Finished loading: $url");
                  },
                  onLoadError: (controller, url, code, message) {
                    debugPrint("Failed to load $url: $message");
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ClassConstants.cardBorderRadius),
            side: BorderSide(
              color: cs.outline.withOpacity(0.3),
              width: 1.0,
            ),
          ),
          color: cs.surfaceContainerLow,
          child: Padding(
            padding: EdgeInsets.all(ClassConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quizzes',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        SizedBox(height: ClassConstants.defaultPadding * 0.25),
                        Text(
                          '${_quizzes.length} quiz${_quizzes.length != 1 ? 'es' : ''} available',
                          style: textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => StudentViewQuizPage(
                                  classId: widget.classId,
                                  roleName: widget.roleName,
                                ),
                              ),
                            )
                            .then((_) {
                              // Refresh quizzes when returning from quiz page
                              _fetchQuizzes();
                            });
                      },
                      child: const Text('View All Quizzes'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Loading state
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),

                // Empty state
                if (!_loading && _quizzes.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            size: 48,
                            color: cs.onSurfaceVariant.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No quizzes available',
                            style: textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: ClassConstants.defaultPadding * 0.25),
                          Text(
                            'Your teacher hasn\'t assigned any quizzes yet',
                            style: textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                // Quiz items
                if (!_loading && _quizzes.isNotEmpty) ...[
                  ..._quizzes.take(3).map((quiz) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Card(
                        elevation: 1.0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: cs.outline.withOpacity(0.3),
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // Icon container
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Icon(
                                  Icons.quiz,
                                  color: cs.onPrimaryContainer,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Quiz info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      quiz['level_name'] ?? 'No Name',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Uploaded: ${_formatDate(quiz['created_at'])}',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Play button
                              FilledButton.icon(
                                onPressed: () => _playQuiz(context, quiz),
                                icon: const Icon(Icons.play_arrow, size: 18),
                                label: const Text('Play'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: cs.primary,
                                  foregroundColor: cs.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],

                // Show "View All" link if more than 3 quizzes
                if (_quizzes.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StudentViewQuizPage(
                                classId: widget.classId,
                                roleName: widget.roleName,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'View all ${_quizzes.length} quizzes',
                          style: textTheme.bodySmall?.copyWith(color: cs.primary),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
  }
}
