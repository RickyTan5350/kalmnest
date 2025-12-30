import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import 'package:flutter_codelab/models/student.dart';
import 'package:flutter_codelab/constants/class_constants.dart';
=======
import 'package:code_play/models/student.dart';
import 'package:code_play/constants/class_constants.dart';
import 'package:code_play/l10n/generated/app_localizations.dart';
>>>>>>> Stashed changes

class StudentPreviewRow extends StatelessWidget {
  final List<Student> students;
  final VoidCallback onViewAll;

  const StudentPreviewRow({
    Key? key,
    required this.students,
    required this.onViewAll,
  }) : super(key: key);

  Widget _studentCard(BuildContext context, Student student) {
    return Container(
      width: 160,
      padding: EdgeInsets.all(ClassConstants.defaultPadding * 0.75),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ClassConstants.cardBorderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              student.name,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: ClassConstants.defaultPadding * 0.625),
          Expanded(
            child: Text(
              student.fullName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Proper "OTHERS" card
  Widget _othersCard(BuildContext context, int extra) {
    return InkWell(
      onTap: onViewAll,
      borderRadius: BorderRadius.circular(ClassConstants.cardBorderRadius),
      child: Container(
        width: 160,
        padding: EdgeInsets.all(ClassConstants.defaultPadding * 0.75),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ClassConstants.cardBorderRadius),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                Icons.group,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                size: 18,
              ),
            ),
            SizedBox(width: ClassConstants.defaultPadding * 0.625),
            Expanded(
              child: Text(
                "$extra more",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClassConstants.cardBorderRadius),
        ),
        child: Padding(
          padding: EdgeInsets.all(ClassConstants.defaultPadding),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: ClassConstants.defaultPadding * 0.75),
              Expanded(
                child: Text(
                  'No students have been enrolled in this class yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final shown = students.take(6).toList();
    final extra = students.length - shown.length;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ClassConstants.cardBorderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(ClassConstants.defaultPadding * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.students,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: ClassConstants.defaultPadding * 0.25),
                    Text(
                      AppLocalizations.of(context)!.listOfEnrolledStudents,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 36),
                  ),
                  onPressed: onViewAll,
                  child: Text(AppLocalizations.of(context)!.viewAll),
                ),
              ],
            ),

            SizedBox(height: ClassConstants.defaultPadding * 0.75),

            // Horizontal scroll of student cards + others card
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...shown.map(
                    (s) => Padding(
                      padding: EdgeInsets.only(
                        right: ClassConstants.defaultPadding * 0.75,
                      ),
                      child: _studentCard(context, s),
                    ),
                  ),

                  if (extra > 0)
                    Padding(
                      padding: EdgeInsets.only(
                        right: ClassConstants.defaultPadding * 0.75,
                      ),
                      child: _othersCard(context, extra),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
