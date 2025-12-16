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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
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
