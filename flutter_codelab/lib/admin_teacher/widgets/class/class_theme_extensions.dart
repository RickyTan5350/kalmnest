import 'package:flutter/material.dart';
import 'package:code_play/constants/class_constants.dart';

/// Theme extensions and helper methods for consistent styling in Class Module
class ClassTheme {
  /// Get consistent input decoration for forms
  static InputDecoration inputDecoration({
    required BuildContext context,
    required String labelText,
    required IconData icon,
    String? hintText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ClassConstants.inputBorderRadius),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ClassConstants.inputBorderRadius),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ClassConstants.inputBorderRadius),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withOpacity(0.6),
      ),
      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.25),
      filled: true,
    );
  }

  /// Get consistent card style
  static BoxDecoration cardDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(ClassConstants.cardBorderRadius),
      border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
    );
  }

  /// Get consistent button style
  static ButtonStyle primaryButtonStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ElevatedButton.styleFrom(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ClassConstants.buttonBorderRadius),
      ),
    );
  }

  /// Get consistent container background color
  static Color containerBackgroundColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }
}

