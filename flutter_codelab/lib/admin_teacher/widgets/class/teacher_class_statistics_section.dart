// lib/widgets/class_statistics_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_codelab/constants/class_constants.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/class_theme_extensions.dart';

class ClassStatisticsSection extends StatelessWidget {
  final int totalStudents;
  final int totalQuizzes;

  const ClassStatisticsSection({
    super.key,
    required this.totalStudents,
    required this.totalQuizzes,
  });

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
        borderRadius: BorderRadius.circular(ClassConstants.cardBorderRadius),
        side: BorderSide(color: cs.outlineVariant, width: 1),
      ),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(ClassConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            SizedBox(height: ClassConstants.defaultPadding * 0.5),
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              SizedBox(height: ClassConstants.defaultPadding * 0.375),
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
          SizedBox(width: ClassConstants.defaultPadding * 0.75),
          Expanded(
            child: _statCard(context, 'Total Quizzes', '$totalQuizzes', ''),
          ),
          SizedBox(width: ClassConstants.defaultPadding * 0.75),
        ],
      ),
    );
  }
}

