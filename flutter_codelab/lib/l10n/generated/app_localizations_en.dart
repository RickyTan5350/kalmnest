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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Are you sure you want to delete $count users? This action cannot be undone.',
      one:
          'Are you sure you want to delete 1 user? This action cannot be undone.',
    );
    return '$_temp0';
  }

  @override
  String get deletingUsers => 'Deleting selected users...';

  @override
  String deletedUsersSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Successfully deleted $count users',
      one: 'Successfully deleted 1 user',
    );
    return '$_temp0';
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
}
