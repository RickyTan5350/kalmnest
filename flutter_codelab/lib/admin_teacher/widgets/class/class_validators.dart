import 'package:flutter_codelab/constants/class_constants.dart';
import 'package:flutter_codelab/l10n/generated/app_localizations.dart';

/// Validation helper methods for class form inputs
class ClassValidators {
  /// Validate class name
  ///
  /// Rules:
  /// - Required
  /// - Minimum 3 characters
  /// - Maximum 100 characters
  static String? className(String? value, AppLocalizations? l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n?.classNameRequired ?? ClassConstants.classNameRequired;
    }

    final trimmed = value.trim();

    if (trimmed.length < 3) {
      return l10n?.classNameMinCharacters ??
          'Class name must be at least 3 characters';
    }

    if (trimmed.length > 100) {
      return l10n?.classNameMaxCharacters ??
          'Class name cannot exceed 100 characters';
    }

    return null;
  }

  /// Validate description
  ///
  /// Rules:
  /// - Required
  /// - Minimum 10 words
  /// - Maximum 500 characters
  static String? description(String? value, AppLocalizations? l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n?.descriptionRequired ?? 'Description is required';
    }

    final trimmed = value.trim();

    if (trimmed.length > 500) {
      return l10n?.descriptionMaxCharacters ??
          'Description cannot exceed 500 characters';
    }

    // Count words (split by whitespace and filter empty strings)
    final words = trimmed
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final wordCount = words.length;

    if (wordCount < 10) {
      return l10n?.descriptionMinWords ??
          'Description must contain at least 10 words';
    }

    return null;
  }

  /// Validate student IDs list
  ///
  /// Rules:
  /// - No duplicates
  /// - All IDs must be valid UUIDs (optional check)
  static String? studentIds(List<String>? studentIds) {
    if (studentIds == null || studentIds.isEmpty) {
      return null; // Optional field
    }

    // Check for duplicates
    final uniqueIds = studentIds.toSet();
    if (uniqueIds.length != studentIds.length) {
      return ClassConstants.duplicateStudentError;
    }

    // Optional: Validate UUID format
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );

    for (final id in studentIds) {
      if (id.isNotEmpty && !uuidRegex.hasMatch(id)) {
        return 'Invalid student ID format';
      }
    }

    return null;
  }

  /// Validate teacher ID (optional)
  ///
  /// Rules:
  /// - If provided, must be valid UUID format
  static String? teacherId(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );

    if (!uuidRegex.hasMatch(value)) {
      return 'Invalid teacher ID format';
    }

    return null;
  }

  /// Sanitize input string
  ///
  /// Removes leading/trailing whitespace and potentially dangerous characters
  static String sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[<>]'), '') // Remove potential HTML tags
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  /// Validate focus field
  ///
  /// Rules:
  /// - Optional (nullable)
  /// - Must be one of: HTML, CSS, JavaScript, PHP
  static String? focus(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    const validFocuses = ['HTML', 'CSS', 'JavaScript', 'PHP'];
    if (!validFocuses.contains(value)) {
      return 'Focus must be one of: HTML, CSS, JavaScript, PHP';
    }

    return null;
  }

  /// Validate entire class form
  ///
  /// Returns a map of field names to error messages
  static Map<String, String?> validateClassForm({
    required String? className,
    String? description,
    String? teacherId,
    String? focus,
    List<String>? studentIds,
    AppLocalizations? l10n,
  }) {
    return {
      'class_name': ClassValidators.className(className, l10n),
      'description': ClassValidators.description(description, l10n),
      'teacher_id': ClassValidators.teacherId(teacherId),
      'focus': ClassValidators.focus(focus),
      'student_ids': ClassValidators.studentIds(studentIds),
    };
  }

  /// Check if form is valid (no errors)
  static bool isFormValid(Map<String, String?> errors) {
    return errors.values.every((error) => error == null);
  }
}
