// lib/widgets/quiz_list_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_codelab/models/quiz.dart';

class QuizListSection extends StatelessWidget {
  final List<Quiz> quizzes;
  final String roleName; // add role
  const QuizListSection({
    Key? key,
    required this.quizzes,
    required this.roleName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String formatDate(DateTime date) {
      const months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ];
      return "${months[date.month - 1]} ${date.day}, ${date.year}";
    }

    // Filter quizzes for student
    final visibleQuizzes = roleName.toLowerCase() == 'student'
        ? quizzes.where((q) => q.status == QuizStatus.published).toList()
        : quizzes;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
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
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage quizzes',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => debugPrint('View All Quizzes'),
                      child: const Text('View All Quizzes'),
                    ),
                    if (roleName.toLowerCase() == 'teacher') ...[
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => debugPrint('Create Quiz'),
                        child: const Text('Create Quiz'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // List quizzes
            ...visibleQuizzes.map((q) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 4,
                ),
                tileColor: Theme.of(context).colorScheme.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                title: Text(
                  q.title,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                subtitle: Text(
                  '${q.questions} questions • Assigned: ${formatDate(q.assignedDate)}',
                ),
                trailing: Chip(
                  label: Text(
                    roleName.toLowerCase() == 'teacher'
                        ? (q.status == QuizStatus.published
                              ? 'Published'
                              : 'Draft')
                        : 'Attempt',
                  ),
                  backgroundColor: q.status == QuizStatus.published
                      ? Colors.green.withOpacity(0.12)
                      : Colors.grey.withOpacity(0.12),
                ),
                onTap: () => debugPrint('Open ${q.title}'),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
