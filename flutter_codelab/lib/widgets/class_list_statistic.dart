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
      StatItem(label: 'Assigned teacher', value: '15', change: '+1'),
      StatItem(label: 'Enrolled students', value: '150', change: '+10'),
    ];

    return Row(
      children: stats
          .map(
            (stat) => Expanded(
              child: _StatCard(stat: stat),
            ),
          )
          .toList(),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Text(
              stat.label,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.normal,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            // Value
            Text(
              stat.value,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
            // Change
            if (stat.change != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  stat.change!,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.normal,
                    color: colorScheme.primary,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
