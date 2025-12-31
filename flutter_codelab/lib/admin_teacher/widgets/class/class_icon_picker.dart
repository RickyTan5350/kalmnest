// Icon picker widget for class customization
import 'package:flutter/material.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/class_customization.dart';

class ClassIconPicker extends StatelessWidget {
  final String? selectedIcon;
  final Function(String) onIconSelected;

  const ClassIconPicker({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = ClassCustomization.getIconByName(selectedIcon);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Class Icon',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ClassCustomization.availableIcons.map((classIcon) {
            final isSelected = selected?.name == classIcon.name;
            return GestureDetector(
              onTap: () => onIconSelected(classIcon.name),
              child: Tooltip(
                message: classIcon.displayName,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline.withOpacity(0.3),
                      width: isSelected ? 2 : 1.5,
                    ),
                  ),
                  child: Icon(
                    classIcon.icon,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}


