import 'package:flutter/material.dart';
import 'package:code_play/api/class_api.dart';
import 'package:code_play/constants/class_constants.dart';

class StatItem {
  final String label;
  final String value;
  final String? change;

  StatItem({required this.label, required this.value, this.change});
}

class ClassStatisticsSection extends StatefulWidget {
  const ClassStatisticsSection({super.key});

  @override
  State<ClassStatisticsSection> createState() => _ClassStatisticsSectionState();
}

class _ClassStatisticsSectionState extends State<ClassStatisticsSection> {
  int totalClasses = 0;
  int totalAssignedTeachers = 0;
  int totalEnrolledStudents = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final stats = await ClassApi.fetchClassStats();
    if (!mounted) return;

    final count = stats['total_classes'] ?? 0;
    final assigned = stats['total_assigned_teachers'] ?? 0;
    final enrolled = stats['total_enrolled_students'] ?? 0;

    if (mounted) {
      setState(() {
        totalClasses = count;
        totalAssignedTeachers = assigned;
        totalEnrolledStudents = enrolled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = [
      StatItem(label: 'Total Classes', value: '$totalClasses'),
      StatItem(label: 'Assigned Teacher', value: '$totalAssignedTeachers'),
      StatItem(label: 'Enrolled Students', value: '$totalEnrolledStudents'),
    ];

    return Row(
      children: stats.map((stat) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ClassConstants.defaultPadding * 0.5,
            ),
            child: _StatCard(stat: stat),
          ),
        );
      }).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final StatItem stat;

  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(ClassConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.label,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: ClassConstants.defaultPadding * 0.375),
              Text(
                stat.value,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (stat.change != null) ...[
                SizedBox(height: ClassConstants.defaultPadding * 0.375),
                Row(
                  children: [
                    Icon(Icons.trending_up, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      stat.change!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

