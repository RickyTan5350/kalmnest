// Color picker widget for class customization
import 'package:flutter/material.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/class_customization.dart';

class ClassColorPicker extends StatelessWidget {
  final String? selectedColor;
  final Function(String) onColorSelected;

  const ClassColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = ClassCustomization.getColorByName(selectedColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Class Color',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ClassCustomization.availableColors.map((classColor) {
            final isSelected = selected?.name == classColor.name;
            return GestureDetector(
              onTap: () => onColorSelected(classColor.name),
              child: Tooltip(
                message: classColor.displayName,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: classColor.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline.withOpacity(0.3),
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: classColor.color.withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

