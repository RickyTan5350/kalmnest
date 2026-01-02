// lib/widgets/quiz_list_section.dart
import 'package:flutter/material.dart';
import 'package:code_play/api/class_api.dart';
import 'package:code_play/admin_teacher/widgets/class/teacher_view_quiz_page.dart';
import 'package:intl/intl.dart';
import 'package:code_play/constants/class_constants.dart';

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ClassConstants.cardBorderRadius),
        side: BorderSide(color: cs.outlineVariant, width: 1),
      ),
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
                    const SizedBox(height: 4),
                    Text(
                      '${_quizzes.length} quiz${_quizzes.length != 1 ? 'es' : ''} available',
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => TeacherViewQuizPage(
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
              ],
            ),
            SizedBox(height: ClassConstants.defaultPadding * 0.75),

            // Loading state
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(ClassConstants.defaultPadding),
                  child: CircularProgressIndicator(),
                ),
              )
            // Empty state
            else if (_quizzes.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(ClassConstants.cardPadding),
                  child: Column(
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 48,
                        color: cs.onSurfaceVariant.withOpacity(0.5),
                      ),
                      SizedBox(height: ClassConstants.defaultPadding * 0.75),
                      Text(
                        'No quizzes yet',
                        style: textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: ClassConstants.defaultPadding * 0.25),
                      Text(
                        'Create or assign quizzes to get started',
                        style: textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            // Quiz list (show first 3, or all if less than 3)
            else
              ..._quizzes.take(3).map((quiz) {
                final levelType = quiz['level_type'];
                final levelTypeName = levelType != null
                    ? levelType['level_type_name'] ?? 'Unknown'
                    : 'Unknown';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      vertical: ClassConstants.defaultPadding * 0.375,
                      horizontal: ClassConstants.defaultPadding * 0.25,
                    ),
                    tileColor: cs.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ClassConstants.cardBorderRadius * 0.67),
                    ),
                    leading: Icon(Icons.quiz, color: cs.primary),
                    title: Text(
                      quiz['level_name'] ?? 'No Name',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Uploaded: ${_formatDate(quiz['created_at'])}',
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ClassConstants.defaultPadding * 0.625,
                        vertical: ClassConstants.defaultPadding * 0.25,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(ClassConstants.cardBorderRadius * 1.67),
                      ),
                      child: Text(
                        levelTypeName,
                        style: textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => TeacherViewQuizPage(
                                classId: widget.classId,
                                roleName: widget.roleName,
                              ),
                            ),
                          )
                          .then((_) {
                            // Refresh quizzes when returning
                            _fetchQuizzes();
                          });
                    },
                  ),
                );
              }).toList(),

            // Show "View All" link if more than 3 quizzes
            if (_quizzes.length > 3)
              Padding(
                padding: EdgeInsets.only(top: ClassConstants.defaultPadding * 0.5),
                child: Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => TeacherViewQuizPage(
                                classId: widget.classId,
                                roleName: widget.roleName,
                              ),
                            ),
                          )
                          .then((_) {
                            // Refresh quizzes when returning
                            _fetchQuizzes();
                          });
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

