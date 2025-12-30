/// Constants for the Class Module
class ClassConstants {
  // Colors - Use theme colors instead of hardcoded values
  // These are kept for reference but should be replaced with ColorScheme
  static const int lightBackgroundColor = 0xFFF5FAFC;
  static const int studentCardBorderColor = 0xFFD1E5EA;
  static const int studentCardBackgroundColor = 0xFFE7F9FF;
  static const int studentAvatarBackgroundColor = 0xFFCFEFF7;
  static const int studentTextColor = 0xFF004B63;

  // Spacing
  static const double defaultPadding = 16.0;
  static const double cardPadding = 24.0;
  static const double formSpacing = 16.0;
  static const double sectionSpacing = 20.0;

  // Border Radius
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 12.0;
  static const double inputBorderRadius = 12.0;

  // Form Width
  static const double formMaxWidth = 420.0;
  static const double searchBarWidth = 300.0;

  // Pagination
  static const int itemsPerPage = 5;
  static const int maxVisiblePages = 3;

  // Student Preview
  static const int maxVisibleStudents = 6;

  // Messages
  static const String noTeacherMessage =
      'No teacher has been assigned to this class yet.';
  static const String noStudentsMessage =
      'No students have been enrolled in this class yet.';
  static const String classCreatedSuccess = 'Class created successfully!';
  static const String classUpdatedSuccess = 'Class updated successfully!';
  static const String classDeletedSuccess = 'Class deleted successfully!';
  static const String deleteConfirmationTitle = 'Delete Class';
  static const String deleteConfirmationMessage =
      'Are you sure you want to delete';

  // Validation Messages
  static const String classNameRequired = 'Please enter class name';
  static const String descriptionRequired = 'Please enter description';
  static const String duplicateStudentError =
      'Duplicate students are not allowed. Each student can only be enrolled once.';
}
