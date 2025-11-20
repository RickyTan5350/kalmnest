import 'package:flutter/material.dart';
// import 'theme.dart';
// import 'util.dart';

class StatItem {
  final String label;
  final String value;
  final String? change;

  StatItem({
    required this.label,
    required this.value,
    this.change,
  });
}

class ClassStatisticsSection extends StatelessWidget {
  const ClassStatisticsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stats = [
      StatItem(label: 'Total Classes', value: '20'),
      StatItem(label: 'Assigned Teacher', value: '15', change: '+1'),
      StatItem(label: 'Enrolled Students', value: '150', change: '+10'),
    ];

    return Row(
      children: stats.map((stat) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stat.label,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              stat.value,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            if (stat.change != null) ...[
              const SizedBox(height: 6),
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
    );
  }
}

