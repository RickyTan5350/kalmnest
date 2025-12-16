import 'package:flutter_codelab/constants/class_constants.dart';

/// Validation helper methods for class form inputs
class ClassValidators {
  /// Validate class name
  ///
  /// Rules:
  /// - Required
  /// - Minimum 3 characters
  /// - Maximum 100 characters
  static String? className(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ClassConstants.classNameRequired;
    }

    final trimmed = value.trim();

    if (trimmed.length < 3) {
      return 'Class name must be at least 3 characters';
    }

    if (trimmed.length > 100) {
      return 'Class name must not exceed 100 characters';
    }

    // Check for invalid characters (optional - can be customized)
    if (RegExp(r'[<>{}[\]\\]').hasMatch(trimmed)) {
      return 'Class name contains invalid characters';
    }

    return null;
  }

  /// Validate description
  ///
  /// Rules:
  /// - Required
  /// - Minimum 10 characters
  /// - Maximum 500 characters
  static String? description(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ClassConstants.descriptionRequired;
    }

    final trimmed = value.trim();

    if (trimmed.length < 10) {
      return 'Description must be at least 10 characters';
    }

    if (trimmed.length > 500) {
      return 'Description must not exceed 500 characters';
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

  /// Validate entire class form
  ///
  /// Returns a map of field names to error messages
  static Map<String, String?> validateClassForm({
    required String? className,
    required String? description,
    String? teacherId,
    List<String>? studentIds,
  }) {
    return {
      'class_name': ClassValidators.className(className),
      'description': ClassValidators.description(description),
      'teacher_id': ClassValidators.teacherId(teacherId),
      'student_ids': ClassValidators.studentIds(studentIds),
    };
  }

  /// Check if form is valid (no errors)
  static bool isFormValid(Map<String, String?> errors) {
    return errors.values.every((error) => error == null);
  }
}
