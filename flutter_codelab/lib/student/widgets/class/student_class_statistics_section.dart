// lib/widgets/class_statistics_section.dart
import 'package:flutter/material.dart';

class ClassStatisticsSection extends StatelessWidget {
  final int totalStudents;
  final int totalQuizzes;

  const ClassStatisticsSection({
    Key? key,
    required this.totalStudents,
    required this.totalQuizzes,
  }) : super(key: key);

  Widget _statCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
  ) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant, width: 1),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Make this widget always take the full width of its parent content area.
    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // three equal-width stat cards
          Expanded(
            child: _statCard(context, 'Total Students', '$totalStudents', ''),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard(context, 'Total Quizzes', '$totalQuizzes', ''),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
