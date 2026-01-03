import 'package:flutter/material.dart';
import 'package:code_play/constants/class_constants.dart';
import 'package:code_play/l10n/generated/app_localizations.dart';

class TeacherPreviewRow extends StatelessWidget {
  final String teacherName;
  final String teacherDescription;
  final VoidCallback? onTap;

  const TeacherPreviewRow({
    super.key,
    required this.teacherName,
    required this.teacherDescription,
    this.onTap,
  });

  String _getInitials(String name) {
    final parts = name.split(" ").where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return "?";
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.assignedTeacher,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: ClassConstants.defaultPadding * 0.75),

        InkWell(
          borderRadius: BorderRadius.circular(ClassConstants.cardBorderRadius),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: ClassConstants.defaultPadding * 0.75,
              horizontal: ClassConstants.defaultPadding,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(
                ClassConstants.cardBorderRadius,
              ),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    _getInitials(teacherName),
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(width: ClassConstants.defaultPadding),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacherName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: ClassConstants.defaultPadding * 0.25),
                      Text(
                        teacherDescription,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.chevron_right,
                  size: 28,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
