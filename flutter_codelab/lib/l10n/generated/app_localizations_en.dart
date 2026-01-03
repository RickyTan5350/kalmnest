// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get helloWorld => 'Hello World';

  @override
  String get userProfile => 'Profile';

  @override
  String get logout => 'Log out';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String helloUser(String userName) {
    return 'Hello, $userName';
  }

  @override
  String get logoutConfirmation => 'Log out of your account?';

  @override
  String get cancel => 'Cancel';

  @override
  String loginFailed(String error) {
    return 'Login Failed: $error';
  }

  @override
  String get autofillSuccess => 'Autofill success!';

  @override
  String get emailHint => 'user@example.com';

  @override
  String get emailValidation => 'Please enter a valid email address';

  @override
  String get passwordValidation => 'Password must be at least 6 characters';

  @override
  String get email => 'Email';

  @override
  String get emailPlaceholder => 'user@example.com';

  @override
  String get validEmailRequired => 'Valid email required';

  @override
  String get password => 'Password';

  @override
  String get passwordRequired => 'Password required';

  @override
  String get login => 'Log In';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get accountRecovery => 'Account Recovery';

  @override
  String get resetCodeSent => 'Reset code sent! Check your email.';

  @override
  String get enterEmailInstructions =>
      'Enter your email address to receive a 6-digit verification code.';

  @override
  String get sendResetCode => 'Send Reset Code';

  @override
  String get quiz => 'Quiz';

  @override
  String get passwordResetSuccess =>
      'Password reset successfully! Please login.';

  @override
  String get setNewPassword => 'Set New Password';

  @override
  String get sixDigitCode => '6-Digit Code';

  @override
  String get newPassword => 'New Password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get name => 'Name';

  @override
  String get date => 'Date';

  @override
  String get unlocked => 'Unlocked';

  @override
  String get locked => 'Locked';

  @override
  String get ascending => 'Ascending';

  @override
  String get descending => 'Descending';

  @override
  String get noLevelsFound => 'No levels found';

  @override
  String get delete => 'Delete';

  @override
  String forUser(Object email) {
    return 'for $email';
  }

  @override
  String get achievements => 'Achievements';

  @override
  String get searchHint => 'Search titles or descriptions...';

  @override
  String get all => 'All';

  @override
  String get createdByMe => 'Created by Me';

  @override
  String get sortBy => 'Sort By';

  @override
  String get order => 'Order';

  @override
  String get refreshList => 'Refresh List';

  @override
  String get sortOptions => 'Sort Options';

  @override
  String get gameLevels => 'Game Levels';

  @override
  String get refreshLevels => 'Refresh Levels';

  @override
  String get addLevel => 'Add Level';

  @override
  String get searchLevels => 'Search levels...';

  @override
  String get visibility => 'Visibility';

  @override
  String get public => 'Public';

  @override
  String get private => 'Private';

  @override
  String get deleteLevel => 'Delete Level';

  @override
  String get deleteLevelConfirmation =>
      'Are you sure you want to delete this level?';

  @override
  String get failedToLoadLevel => 'Failed to load level data';

  @override
  String get notes => 'Notes';

  @override
  String get searchNotesHint => 'Search topic or title';

  @override
  String get users => 'Users';

  @override
  String get games => 'Games';

  @override
  String get classes => 'Classes';

  @override
  String get aiChat => 'AI Chat';

  @override
  String get feedback => 'Feedback';

  @override
  String get searchUserHint => 'Search users...';

  @override
  String get importingUsers => 'Importing users...';

  @override
  String get usersImportedSuccess => 'Users imported successfully!';

  @override
  String importFailed(String error) {
    return 'Import Failed: $error';
  }

  @override
  String get student => 'Student';

  @override
  String get teacher => 'Teacher';

  @override
  String get admin => 'Admin';

  @override
  String get allStatus => 'All Status';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get myFeedback => 'My Feedback';

  @override
  String failedToLoadFeedback(String error) {
    return 'Failed to load feedback: $error';
  }

  @override
  String get errorLoadingFeedback => 'Error loading feedback';

  @override
  String get retry => 'Retry';

  @override
  String get noFeedbackYet => 'No feedback yet';

  @override
  String get teachersFeedbackInstructions =>
      'Your teachers will provide feedback here';

  @override
  String fromTeacher(String teacherName) {
    return 'From: $teacherName';
  }

  @override
  String get classCreatedSuccess => 'Class created successfully!';

  @override
  String get noPermissionCreateUser =>
      'You do not have permission to create user accounts.';

  @override
  String get selectAction => 'Select Action';

  @override
  String get createUserProfile => 'Create User Profile';

  @override
  String get importUserProfile => 'Import User Profile';

  @override
  String get studentsCannotCreateGames =>
      'Students cannot create games. This is for Teachers and Admins only.';

  @override
  String get studentsCannotAddNotes =>
      'Students cannot add notes. This is for Admins only.';

  @override
  String get noAccessFunction => 'You do not have access to this function';

  @override
  String get noAccessCreateFeedback =>
      'You do not have access to create feedback';

  @override
  String userAchievements(String name) {
    return '$name\'s Achievements';
  }

  @override
  String get createNewUser => 'Create New User';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password';

  @override
  String get userAccountCreatedSuccess => 'User account successfully created!';

  @override
  String get networkErrorCheckApi =>
      'Network Error: Check API URL and server status.';

  @override
  String unknownErrorOccurred(String error) {
    return 'An unknown error occurred: $error';
  }

  @override
  String get createUser => 'Create User';

  @override
  String get deleteUsers => 'Delete Users';

  @override
  String deleteUsersConfirmation(int count) {
    return 'Are you sure you want to delete $count users? This action cannot be undone.';
  }

  @override
  String get deletingUsers => 'Deleting selected users...';

  @override
  String deletedUsersSuccess(int count) {
    return 'Successfully deleted $count users';
  }

  @override
  String errorDeletingUsers(String error) {
    return 'Error deleting users: $error';
  }

  @override
  String errorLoadingAchievements(String error) {
    return 'Error loading achievements: $error';
  }

  @override
  String selectedCount(int count) {
    return '$count Selected';
  }

  @override
  String get deleteSelectedUsers => 'Delete Selected Users';

  @override
  String resultsCount(int count) {
    return '$count Results';
  }

  @override
  String get noUsersFound => 'No users found';

  @override
  String get deleteUserAccount => 'Delete User Account?';

  @override
  String deleteUserAccountConfirmation(String name) {
    return 'Are you sure you want to permanently delete $name\'s account and all associated data? This action cannot be undone.';
  }

  @override
  String deletedUserSuccess(String name) {
    return 'Successfully deleted user: $name';
  }

  @override
  String get accessDeniedAdminOnly =>
      'Access Denied: Only Administrators can delete user accounts.';

  @override
  String errorDeletingUser(String error) {
    return 'Error deleting user: $error';
  }

  @override
  String get editUserProfile => 'Edit User Profile';

  @override
  String get errorLoadingProfile => 'Error loading profile';

  @override
  String get userProfileDetails => 'User Profile Details';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get genderLabel => 'Gender';

  @override
  String get joinedDateLabel => 'Joined Date';

  @override
  String get accountStatusLabel => 'Account Status';

  @override
  String get recentAchievements => 'Recent Achievements';

  @override
  String get viewAll => 'View All';

  @override
  String get noAchievementsYet => 'No achievements unlocked yet.';

  @override
  String get unknownDate => 'Unknown Date';

  @override
  String get achievement => 'Achievement';

  @override
  String unlockedOn(String date) {
    return 'Unlocked on $date';
  }

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get passwordsMatchError =>
      'Error: New password and confirmation must match.';

  @override
  String get userProfileUpdated => 'User profile successfully updated!';

  @override
  String get accessDeniedAdminModify =>
      'Access Denied: Only Administrators can modify user profiles.';

  @override
  String errorUpdatingProfile(String error) {
    return 'Error updating profile: $error';
  }

  @override
  String get pleaseEnterName => 'Please enter a name';

  @override
  String get pleaseEnterEmail => 'Please enter an email';

  @override
  String get enterValidEmail => 'Enter a valid email address';

  @override
  String get passwordLengthError => 'Password must be at least 8 characters';

  @override
  String get confirmPasswordRequired => 'Please confirm the new password';

  @override
  String get pleaseEnterPhone => 'Please enter a phone number';

  @override
  String get enterValidPhone => 'Enter a valid Malaysian phone number';

  @override
  String get pleaseEnterAddress => 'Please enter an address';

  @override
  String get pleaseSelectGender => 'Please select a gender';

  @override
  String get pleaseSelectRole => 'Please select a role';

  @override
  String get roleLabel => 'Role';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get other => 'Other';

  @override
  String get feedbacks => 'Feedbacks';

  @override
  String get results => 'Results';

  @override
  String get noFeedbackFound => 'No feedback found.';

  @override
  String get sortByTime => 'Sort by Time';

  @override
  String get newestFirst => 'Newest First';

  @override
  String get oldestFirst => 'Oldest First';

  @override
  String get refreshFeedbacks => 'Refresh Feedbacks';

  @override
  String get filterByStudent => 'Filter by Student';

  @override
  String get allStudents => 'All Students';

  @override
  String get filterByTeacher => 'Filter by Teacher';

  @override
  String get allTeachers => 'All Teachers';

  @override
  String get deleteFeedbackTitle => 'Delete Feedback?';

  @override
  String get deleteFeedbackConfirmation =>
      'Are you sure you want to delete this feedback? This action cannot be undone.';

  @override
  String get feedbackDeleted => 'Feedback deleted';

  @override
  String get editFeedback => 'Edit Feedback';

  @override
  String get currentTopic => 'Current Topic';

  @override
  String get discardChangesTitle => 'Discard Changes?';

  @override
  String get discardChangesConfirmation =>
      'You have unsaved changes. Are you sure you want to discard them?';

  @override
  String get discard => 'Discard';

  @override
  String get changesSavedSuccess => 'Changes saved successfully!';

  @override
  String updateFailed(String error) {
    return 'Update failed: $error';
  }

  @override
  String from(String name) {
    return 'From: $name';
  }

  @override
  String failedToLoadStudents(String error) {
    return 'Failed to load students: $error';
  }

  @override
  String get pleaseSelectStudent => 'Please select a student';

  @override
  String feedbackSentTo(String name) {
    return 'Feedback sent to $name';
  }

  @override
  String get accessDeniedCreateFeedback =>
      'Access Denied: Only teachers can create feedback.';

  @override
  String get newFeedback => 'New Feedback';

  @override
  String get selectStudent => 'Select Student';

  @override
  String get selectAStudent => 'Select a student';

  @override
  String get noStudentsAvailable => 'No students available';

  @override
  String get selectTopic => 'Select Topic';

  @override
  String get selectATopic => 'Select a topic';

  @override
  String get pleaseSelectTopic => 'Please select a topic';

  @override
  String get title => 'Title';

  @override
  String get titleHint => 'e.g., Great Job!';

  @override
  String get pleaseEnterTitle => 'Please enter a title';

  @override
  String get feedbackHint => 'Write your feedback here...';

  @override
  String get pleaseWriteFeedback => 'Please write feedback';

  @override
  String get send => 'Send';

  @override
  String errorLoadingHistory(String error) {
    return 'Error loading history: $error';
  }

  @override
  String errorLoadingMessages(String error) {
    return 'Error loading messages: $error';
  }

  @override
  String get clearHistory => 'Clear History';

  @override
  String get clearHistoryConfirmation =>
      'Are you sure you want to delete this chat session?';

  @override
  String get chatDeletedSuccessfully => 'Chat deleted successfully';

  @override
  String get chatClearedSuccessfully => 'Chat cleared successfully';

  @override
  String deleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get aiChatTitle => 'KalmNest AI (Gemini-2.0-flash)';

  @override
  String get howCanIHelp => 'How can I help you today?';

  @override
  String get askQuestion => 'Ask Question';

  @override
  String get recentQuestions => 'Recent Questions';

  @override
  String get noQuestionsFound => 'No previous questions found.';

  @override
  String get untitledQuestion => 'Untitled Question';

  @override
  String get quickSuggestions => 'Quick Learning Suggestions';

  @override
  String get suggestionPrefix => 'Give me Learning Suggestion for ';

  @override
  String get typeQuestionHint => 'Type your question...';

  @override
  String get backToHistory => 'Back to History';

  @override
  String get refreshQuestion => 'Refresh Question';

  @override
  String get deleteChat => 'Delete Chat';

  @override
  String get classCreatedSuccessfully => 'Class created successfully!';

  @override
  String get failedToCreateClass => 'Failed to create class';

  @override
  String get ok => 'OK';

  @override
  String get createNewClass => 'Create New Class';

  @override
  String get indicatesRequiredFields => '* indicates required fields';

  @override
  String get className => 'Class Name';

  @override
  String get enterClassName => 'Enter class name';

  @override
  String get description => 'Description';

  @override
  String get enterDescription => 'Enter description (at least 10 words)';

  @override
  String get atLeast10Words => 'At least 10 words';

  @override
  String get focusOptional => 'Focus (Optional)';

  @override
  String get noneOptional => 'None (Optional)';

  @override
  String get assignTeacherOptional => 'Assign Teacher (Optional)';

  @override
  String get classUpdatedSuccessfully => 'Class updated successfully!';

  @override
  String get failedToUpdateClass => 'Failed to update class';

  @override
  String get editClass => 'Edit Class';

  @override
  String get editClassDetails => 'Edit Class Details';

  @override
  String get loading => 'Loading...';

  @override
  String get selectTeacher => 'Select Teacher';

  @override
  String get classNameRequired => 'Class name is required';

  @override
  String get classNameMinCharacters =>
      'Class name must be at least 3 characters';

  @override
  String get classNameMaxCharacters =>
      'Class name cannot exceed 100 characters';

  @override
  String get descriptionRequired => 'Description is required';

  @override
  String get descriptionMaxCharacters =>
      'Description cannot exceed 500 characters';

  @override
  String get descriptionMinWords =>
      'Description must contain at least 10 words';

  @override
  String get thisClass => 'this class';

  @override
  String deleteClassConfirmation(String className) {
    return 'Are you sure you want to delete $className? This action cannot be undone.';
  }

  @override
  String get classDeletedSuccessfully => 'Class deleted successfully!';

  @override
  String errorDeletingClass(String error) {
    return 'Error deleting class: $error';
  }

  @override
  String get unknown => 'Unknown';

  @override
  String get nA => 'N/A';

  @override
  String get details => 'Details';

  @override
  String get refresh => 'Refresh';

  @override
  String get deleteClass => 'Delete Class';

  @override
  String classesSelected(int count) {
    return '$count Classes Selected';
  }

  @override
  String deleteClassesConfirmation(int count) {
    return 'Are you sure you want to delete $count class(es)? This action cannot be undone.';
  }

  @override
  String classesDeletedSuccessfully(int count) {
    return '$count class(es) deleted successfully!';
  }

  @override
  String get noName => 'No Name';

  @override
  String get noTeacherAssigned => 'No Teacher Assigned';

  @override
  String get generalInfo => 'General Information';

  @override
  String get searchStudents => 'Search Students';

  @override
  String get totalStudents => 'Total Students';

  @override
  String get completionRate => 'Completion Rate';

  @override
  String get quizzesAssigned => 'Quizzes Assigned';

  @override
  String get moreOptions => 'More Options';

  @override
  String get viewDetails => 'View Details';

  @override
  String get completed => 'Completed';

  @override
  String get quizzes => 'Quizzes';

  @override
  String get courseProgress => 'Course Progress';

  @override
  String get noStudentsFound => 'No students found';

  @override
  String get tryAdjustingSearchCriteria => 'Try adjusting your search criteria';

  @override
  String get edit => 'Edit';

  @override
  String get noClassesFound => 'No classes found';

  @override
  String get tryAdjustingSearchQuery => 'Try adjusting your search query';

  @override
  String get notEnrolledInAnyClasses => 'You are not enrolled in any classes';

  @override
  String get classFocusUpdatedSuccessfully =>
      'Class focus updated successfully!';

  @override
  String get failedToUpdateClassFocus => 'Failed to update class focus';

  @override
  String get editClassFocus => 'Edit Class Focus';

  @override
  String editFocusFor(String className) {
    return 'Edit Focus for $className';
  }

  @override
  String get youCanOnlyEditFocus =>
      'You can only edit the focus for your own classes';

  @override
  String get failedToLoadQuizStudentData => 'Failed to load quiz student data';

  @override
  String get never => 'Never';

  @override
  String get allQuizzes => 'All Quizzes';

  @override
  String get statistics => 'Statistics';

  @override
  String get pending => 'Pending';

  @override
  String get failedToLoadStudentQuizData => 'Failed to load student quiz data';

  @override
  String get gender => 'Gender';

  @override
  String get joinedDate => 'Joined Date';

  @override
  String get accountStatus => 'Account Status';

  @override
  String get totalQuizzes => 'Total Quizzes';

  @override
  String get noQuizzesFound => 'No quizzes found';

  @override
  String get quizVisibility => 'Quiz Visibility';

  @override
  String get howShouldQuizBeVisible => 'How should this quiz be visible?';

  @override
  String get onlyVisibleToThisClass => 'Only visible to this class';

  @override
  String get visibleToEveryone => 'Visible to everyone';

  @override
  String get quizCreatedAndAssignedSuccessfully =>
      'Quiz created and assigned successfully!';

  @override
  String get failedToAssignQuiz => 'Failed to assign quiz';

  @override
  String get quizAssignedSuccessfully => 'Quiz assigned successfully!';

  @override
  String get removeQuiz => 'Remove Quiz';

  @override
  String get areYouSureRemoveQuiz =>
      'Are you sure you want to remove this quiz from the class?';

  @override
  String get remove => 'Remove';

  @override
  String get quizRemovedSuccessfully => 'Quiz removed successfully!';

  @override
  String quizzesAvailable(int count) {
    return '$count quizzes available';
  }

  @override
  String get viewAllQuizzes => 'View All Quizzes';

  @override
  String get noQuizzesYet => 'No quizzes yet';

  @override
  String get createOrAssignQuizzes => 'Create or assign quizzes to get started';

  @override
  String uploaded(String date) {
    return 'Uploaded $date';
  }

  @override
  String viewAllXQuizzes(int count) {
    return 'View All $count Quizzes';
  }

  @override
  String get unknownTeacher => 'Unknown Teacher';

  @override
  String get noTeacher => 'No Teacher';

  @override
  String get studentSingular => 'student';

  @override
  String get studentsPlural => 'students';

  @override
  String get noStudents => 'No students';

  @override
  String get assignedTeacher => 'Assigned Teacher';

  @override
  String get play => 'Play';

  @override
  String get allClasses => 'All Classes';

  @override
  String get myClasses => 'My Classes';

  @override
  String get enrolledClasses => 'Enrolled Classes';

  @override
  String get searchByClassName => 'Search by class name';

  @override
  String get noDescriptionAvailable => 'No description available';

  @override
  String get timestamps => 'Timestamps';

  @override
  String get createdAt => 'Created At';

  @override
  String get updatedAt => 'Updated At';

  @override
  String get assignStudentsOptional => 'Assign Students (Optional)';

  @override
  String get enrollStudentsOptional => 'Enroll Students (Optional)';

  @override
  String get classInformation => 'Class Information';

  @override
  String studentNumber(int number) {
    return 'Student $number';
  }

  @override
  String get selectStudents => 'Select Students';

  @override
  String get addStudent => 'Add Student';

  @override
  String get reset => 'Reset';

  @override
  String get create => 'Create';

  @override
  String get creator => 'Creator';

  @override
  String get focus => 'Focus';

  @override
  String get notSet => 'Not Set';

  @override
  String get cannotOpenTeacherProfile => 'Cannot open teacher profile';

  @override
  String get noTeacherAssignedToClass => 'No teacher assigned to this class';

  @override
  String get lastUpdated => 'Last Updated';

  @override
  String get students => 'Students';

  @override
  String moreStudents(int count) {
    return 'and $count more students';
  }

  @override
  String get noStudentsEnrolled => 'No students enrolled';

  @override
  String get listOfEnrolledStudents => 'List of Enrolled Students';

  @override
  String get status => 'Status';

  @override
  String get assigned => 'Assigned';

  @override
  String get failedToRemoveQuiz => 'Failed to remove quiz';

  @override
  String get searchQuizzes => 'Search Quizzes';

  @override
  String get assignQuiz => 'Assign Quiz';

  @override
  String get createQuiz => 'Create Quiz';

  @override
  String get tapToViewStudentCompletion => 'Tap to view student completion';

  @override
  String get assignQuizToClass => 'Assign Quiz to Class';

  @override
  String get reloadQuizzes => 'Reload Quizzes';

  @override
  String get noQuizzesAssigned => 'No quizzes assigned';

  @override
  String get pleaseEnterQuestion => 'Please enter a question';

  @override
  String get aiLanguageNotice =>
      'AI responds in the same language as your question';

  @override
  String deleteFeedbacksConfirmation(int count) {
    return 'Are you sure you want to delete $count feedback(s)? This action cannot be undone.';
  }

  @override
  String feedbacksDeletedSuccessfully(int count) {
    return 'Successfully deleted $count feedback(s).';
  }

  @override
  String get selected => 'Selected';

  @override
  String get deleteChatSessionsTitle => 'Delete Chat Sessions?';

  @override
  String deleteChatSessionsConfirmation(int count) {
    return 'Are you sure you want to delete $count chat session(s)? This action cannot be undone.';
  }

  @override
  String chatSessionsDeletedSuccessfully(int count) {
    return 'Successfully deleted $count chat session(s).';
  }
}
