import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ms'),
  ];

  /// The conventional newborn programmer greeting
  ///
  /// In en, this message translates to:
  /// **'Hello World'**
  String get helloWorld;

  /// No description provided for @userProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get userProfile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @helloUser.
  ///
  /// In en, this message translates to:
  /// **'Hello, {userName}'**
  String helloUser(String userName);

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Log out of your account?'**
  String get logoutConfirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login Failed: {error}'**
  String loginFailed(String error);

  /// No description provided for @autofillSuccess.
  ///
  /// In en, this message translates to:
  /// **'Autofill success!'**
  String get autofillSuccess;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'user@example.com'**
  String get emailHint;

  /// No description provided for @emailValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get emailValidation;

  /// No description provided for @passwordValidation.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordValidation;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'user@example.com'**
  String get emailPlaceholder;

  /// No description provided for @validEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Valid email required'**
  String get validEmailRequired;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password required'**
  String get passwordRequired;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @accountRecovery.
  ///
  /// In en, this message translates to:
  /// **'Account Recovery'**
  String get accountRecovery;

  /// No description provided for @resetCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Reset code sent! Check your email.'**
  String get resetCodeSent;

  /// No description provided for @enterEmailInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address to receive a 6-digit verification code.'**
  String get enterEmailInstructions;

  /// No description provided for @sendResetCode.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Code'**
  String get sendResetCode;

  /// No description provided for @quiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quiz;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully! Please login.'**
  String get passwordResetSuccess;

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get setNewPassword;

  /// No description provided for @sixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'6-Digit Code'**
  String get sixDigitCode;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get unlocked;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @ascending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// No description provided for @descending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// No description provided for @noLevelsFound.
  ///
  /// In en, this message translates to:
  /// **'No levels found'**
  String get noLevelsFound;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @forUser.
  ///
  /// In en, this message translates to:
  /// **'for {email}'**
  String forUser(Object email);

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search titles or descriptions...'**
  String get searchHint;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @createdByMe.
  ///
  /// In en, this message translates to:
  /// **'Created by Me'**
  String get createdByMe;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @refreshList.
  ///
  /// In en, this message translates to:
  /// **'Refresh List'**
  String get refreshList;

  /// No description provided for @sortOptions.
  ///
  /// In en, this message translates to:
  /// **'Sort Options'**
  String get sortOptions;

  /// No description provided for @gameLevels.
  ///
  /// In en, this message translates to:
  /// **'Game Levels'**
  String get gameLevels;

  /// No description provided for @refreshLevels.
  ///
  /// In en, this message translates to:
  /// **'Refresh Levels'**
  String get refreshLevels;

  /// No description provided for @addLevel.
  ///
  /// In en, this message translates to:
  /// **'Add Level'**
  String get addLevel;

  /// No description provided for @searchLevels.
  ///
  /// In en, this message translates to:
  /// **'Search levels...'**
  String get searchLevels;

  /// No description provided for @visibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get visibility;

  /// No description provided for @public.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get public;

  /// No description provided for @private.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get private;

  /// No description provided for @deleteLevel.
  ///
  /// In en, this message translates to:
  /// **'Delete Level'**
  String get deleteLevel;

  /// No description provided for @deleteLevelConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this level?'**
  String get deleteLevelConfirmation;

  /// No description provided for @failedToLoadLevel.
  ///
  /// In en, this message translates to:
  /// **'Failed to load level data'**
  String get failedToLoadLevel;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @searchNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Search topic or title'**
  String get searchNotesHint;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @games.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get games;

  /// No description provided for @classes.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get classes;

  /// No description provided for @aiChat.
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get aiChat;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @searchUserHint.
  ///
  /// In en, this message translates to:
  /// **'Search users...'**
  String get searchUserHint;

  /// No description provided for @importingUsers.
  ///
  /// In en, this message translates to:
  /// **'Importing users...'**
  String get importingUsers;

  /// No description provided for @usersImportedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Users imported successfully!'**
  String get usersImportedSuccess;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import Failed: {error}'**
  String importFailed(String error);

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'student'**
  String get student;

  /// No description provided for @teacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacher;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @allStatus.
  ///
  /// In en, this message translates to:
  /// **'All Status'**
  String get allStatus;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @myFeedback.
  ///
  /// In en, this message translates to:
  /// **'My Feedback'**
  String get myFeedback;

  /// No description provided for @failedToLoadFeedback.
  ///
  /// In en, this message translates to:
  /// **'Failed to load feedback: {error}'**
  String failedToLoadFeedback(String error);

  /// No description provided for @errorLoadingFeedback.
  ///
  /// In en, this message translates to:
  /// **'Error loading feedback'**
  String get errorLoadingFeedback;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noFeedbackYet.
  ///
  /// In en, this message translates to:
  /// **'No feedback yet'**
  String get noFeedbackYet;

  /// No description provided for @teachersFeedbackInstructions.
  ///
  /// In en, this message translates to:
  /// **'Your teachers will provide feedback here'**
  String get teachersFeedbackInstructions;

  /// No description provided for @fromTeacher.
  ///
  /// In en, this message translates to:
  /// **'From: {teacherName}'**
  String fromTeacher(String teacherName);

  /// No description provided for @classCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Class created successfully!'**
  String get classCreatedSuccess;

  /// No description provided for @noPermissionCreateUser.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to create user accounts.'**
  String get noPermissionCreateUser;

  /// No description provided for @selectAction.
  ///
  /// In en, this message translates to:
  /// **'Select Action'**
  String get selectAction;

  /// No description provided for @createUserProfile.
  ///
  /// In en, this message translates to:
  /// **'Create User Profile'**
  String get createUserProfile;

  /// No description provided for @importUserProfile.
  ///
  /// In en, this message translates to:
  /// **'Import User Profile'**
  String get importUserProfile;

  /// No description provided for @studentsCannotCreateGames.
  ///
  /// In en, this message translates to:
  /// **'Students cannot create games. This is for Teachers and Admins only.'**
  String get studentsCannotCreateGames;

  /// No description provided for @studentsCannotAddNotes.
  ///
  /// In en, this message translates to:
  /// **'Students cannot add notes. This is for Admins only.'**
  String get studentsCannotAddNotes;

  /// No description provided for @noAccessFunction.
  ///
  /// In en, this message translates to:
  /// **'You do not have access to this function'**
  String get noAccessFunction;

  /// No description provided for @noAccessCreateFeedback.
  ///
  /// In en, this message translates to:
  /// **'You do not have access to create feedback'**
  String get noAccessCreateFeedback;

  /// No description provided for @userAchievements.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Achievements'**
  String userAchievements(String name);

  /// No description provided for @createNewUser.
  ///
  /// In en, this message translates to:
  /// **'Create New User'**
  String get createNewUser;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmPassword;

  /// No description provided for @userAccountCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'User account successfully created!'**
  String get userAccountCreatedSuccess;

  /// No description provided for @networkErrorCheckApi.
  ///
  /// In en, this message translates to:
  /// **'Network Error: Check API URL and server status.'**
  String get networkErrorCheckApi;

  /// No description provided for @unknownErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred: {error}'**
  String unknownErrorOccurred(String error);

  /// No description provided for @createUser.
  ///
  /// In en, this message translates to:
  /// **'Create User'**
  String get createUser;

  /// No description provided for @deleteUsers.
  ///
  /// In en, this message translates to:
  /// **'Delete Users'**
  String get deleteUsers;

  /// No description provided for @deleteUsersConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} users? This action cannot be undone.'**
  String deleteUsersConfirmation(int count);

  /// No description provided for @deletingUsers.
  ///
  /// In en, this message translates to:
  /// **'Deleting selected users...'**
  String get deletingUsers;

  /// No description provided for @deletedUsersSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully deleted {count} users'**
  String deletedUsersSuccess(int count);

  /// No description provided for @errorDeletingUsers.
  ///
  /// In en, this message translates to:
  /// **'Error deleting users: {error}'**
  String errorDeletingUsers(String error);

  /// No description provided for @errorLoadingAchievements.
  ///
  /// In en, this message translates to:
  /// **'Error loading achievements: {error}'**
  String errorLoadingAchievements(String error);

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Selected'**
  String selectedCount(int count);

  /// No description provided for @deleteSelectedUsers.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected Users'**
  String get deleteSelectedUsers;

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Results'**
  String resultsCount(int count);

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @deleteUserAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete User Account?'**
  String get deleteUserAccount;

  /// No description provided for @deleteUserAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete {name}\'s account and all associated data? This action cannot be undone.'**
  String deleteUserAccountConfirmation(String name);

  /// No description provided for @deletedUserSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully deleted user: {name}'**
  String deletedUserSuccess(String name);

  /// No description provided for @accessDeniedAdminOnly.
  ///
  /// In en, this message translates to:
  /// **'Access Denied: Only Administrators can delete user accounts.'**
  String get accessDeniedAdminOnly;

  /// No description provided for @errorDeletingUser.
  ///
  /// In en, this message translates to:
  /// **'Error deleting user: {error}'**
  String errorDeletingUser(String error);

  /// No description provided for @editUserProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit User Profile'**
  String get editUserProfile;

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get errorLoadingProfile;

  /// No description provided for @userProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'User Profile Details'**
  String get userProfileDetails;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderLabel;

  /// No description provided for @joinedDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Joined Date'**
  String get joinedDateLabel;

  /// No description provided for @accountStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get accountStatusLabel;

  /// No description provided for @recentAchievements.
  ///
  /// In en, this message translates to:
  /// **'Recent Achievements'**
  String get recentAchievements;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @noAchievementsYet.
  ///
  /// In en, this message translates to:
  /// **'No achievements unlocked yet.'**
  String get noAchievementsYet;

  /// No description provided for @unknownDate.
  ///
  /// In en, this message translates to:
  /// **'Unknown Date'**
  String get unknownDate;

  /// No description provided for @achievement.
  ///
  /// In en, this message translates to:
  /// **'Achievement'**
  String get achievement;

  /// No description provided for @unlockedOn.
  ///
  /// In en, this message translates to:
  /// **'Unlocked on {date}'**
  String unlockedOn(String date);

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @passwordsMatchError.
  ///
  /// In en, this message translates to:
  /// **'Error: New password and confirmation must match.'**
  String get passwordsMatchError;

  /// No description provided for @userProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'User profile successfully updated!'**
  String get userProfileUpdated;

  /// No description provided for @accessDeniedAdminModify.
  ///
  /// In en, this message translates to:
  /// **'Access Denied: Only Administrators can modify user profiles.'**
  String get accessDeniedAdminModify;

  /// No description provided for @errorUpdatingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error updating profile: {error}'**
  String errorUpdatingProfile(String error);

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get pleaseEnterName;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter an email'**
  String get pleaseEnterEmail;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get enterValidEmail;

  /// No description provided for @passwordLengthError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordLengthError;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm the new password'**
  String get confirmPasswordRequired;

  /// No description provided for @pleaseEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a phone number'**
  String get pleaseEnterPhone;

  /// No description provided for @enterValidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Malaysian phone number'**
  String get enterValidPhone;

  /// No description provided for @pleaseEnterAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter an address'**
  String get pleaseEnterAddress;

  /// No description provided for @pleaseSelectGender.
  ///
  /// In en, this message translates to:
  /// **'Please select a gender'**
  String get pleaseSelectGender;

  /// No description provided for @pleaseSelectRole.
  ///
  /// In en, this message translates to:
  /// **'Please select a role'**
  String get pleaseSelectRole;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @generalInfo.
  ///
  /// In en, this message translates to:
  /// **'General Info'**
  String get generalInfo;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @timestamps.
  ///
  /// In en, this message translates to:
  /// **'Timestamps'**
  String get timestamps;

  /// No description provided for @teacherIncharge.
  ///
  /// In en, this message translates to:
  /// **'Teacher in-charge'**
  String get teacherIncharge;

  /// No description provided for @assignedTeacher.
  ///
  /// In en, this message translates to:
  /// **'Assigned Teacher'**
  String get assignedTeacher;

  /// No description provided for @quizzes.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get quizzes;

  /// No description provided for @students.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get students;

  /// No description provided for @completionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion Rate'**
  String get completionRate;

  /// No description provided for @quizAssignTotalStudent.
  ///
  /// In en, this message translates to:
  /// **'Quiz Assign Total Student'**
  String get quizAssignTotalStudent;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @statistic.
  ///
  /// In en, this message translates to:
  /// **'Statistic'**
  String get statistic;

  /// No description provided for @assignQuiz.
  ///
  /// In en, this message translates to:
  /// **'Assign Quiz'**
  String get assignQuiz;

  /// No description provided for @createQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Create Quizzes'**
  String get createQuizzes;

  /// No description provided for @searchByClassName.
  ///
  /// In en, this message translates to:
  /// **'Search by class name'**
  String get searchByClassName;

  /// No description provided for @myClasses.
  ///
  /// In en, this message translates to:
  /// **'My Classes'**
  String get myClasses;

  /// No description provided for @enrolledClasses.
  ///
  /// In en, this message translates to:
  /// **'Enrolled Classes'**
  String get enrolledClasses;

  /// No description provided for @totalStudents.
  ///
  /// In en, this message translates to:
  /// **'Total Students'**
  String get totalStudents;

  /// No description provided for @totalQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Total Quizzes'**
  String get totalQuizzes;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdated;

  /// No description provided for @creator.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get creator;

  /// No description provided for @focus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focus;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @noTeacherAssigned.
  ///
  /// In en, this message translates to:
  /// **'No teacher assigned'**
  String get noTeacherAssigned;

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available'**
  String get noDescriptionAvailable;

  /// No description provided for @noStudents.
  ///
  /// In en, this message translates to:
  /// **'No students'**
  String get noStudents;

  /// No description provided for @noStudentsEnrolled.
  ///
  /// In en, this message translates to:
  /// **'No students have been enrolled in this class yet.'**
  String get noStudentsEnrolled;

  /// No description provided for @allQuizzes.
  ///
  /// In en, this message translates to:
  /// **'All Quizzes'**
  String get allQuizzes;

  /// No description provided for @searchQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Search quizzes...'**
  String get searchQuizzes;

  /// No description provided for @quizAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} quiz{plural} available'**
  String quizAvailable(int count, String plural);

  /// No description provided for @noQuizzesYet.
  ///
  /// In en, this message translates to:
  /// **'No quizzes yet'**
  String get noQuizzesYet;

  /// No description provided for @teacherHasntAssignedQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Your teacher hasn\'t assigned any quizzes yet'**
  String get teacherHasntAssignedQuizzes;

  /// No description provided for @uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploaded;

  /// No description provided for @unknownTeacher.
  ///
  /// In en, this message translates to:
  /// **'Unknown Teacher'**
  String get unknownTeacher;

  /// No description provided for @studentsPlural.
  ///
  /// In en, this message translates to:
  /// **'students'**
  String get studentsPlural;

  /// No description provided for @listOfEnrolledStudents.
  ///
  /// In en, this message translates to:
  /// **'List of enrolled students'**
  String get listOfEnrolledStudents;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @editClass.
  ///
  /// In en, this message translates to:
  /// **'Edit Class'**
  String get editClass;

  /// No description provided for @editFocus.
  ///
  /// In en, this message translates to:
  /// **'Edit Focus'**
  String get editFocus;

  /// No description provided for @deleteClass.
  ///
  /// In en, this message translates to:
  /// **'Delete Class'**
  String get deleteClass;

  /// No description provided for @classDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Class deleted successfully.'**
  String get classDeletedSuccessfully;

  /// No description provided for @errorDeletingClass.
  ///
  /// In en, this message translates to:
  /// **'Error deleting class: {error}'**
  String errorDeletingClass(String error);

  /// No description provided for @cannotOpenTeacherProfile.
  ///
  /// In en, this message translates to:
  /// **'Cannot open teacher profile: missing teacher id.'**
  String get cannotOpenTeacherProfile;

  /// No description provided for @noTeacherAssignedToClass.
  ///
  /// In en, this message translates to:
  /// **'No teacher assigned to this class.'**
  String get noTeacherAssignedToClass;

  /// No description provided for @tryAdjustingSearchQuery.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search query'**
  String get tryAdjustingSearchQuery;

  /// No description provided for @notAssignedToAnyClasses.
  ///
  /// In en, this message translates to:
  /// **'You are not assigned to any classes yet'**
  String get notAssignedToAnyClasses;

  /// No description provided for @noClassesFound.
  ///
  /// In en, this message translates to:
  /// **'No classes found'**
  String get noClassesFound;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @quizzesAssigned.
  ///
  /// In en, this message translates to:
  /// **'Quizzes Assigned'**
  String get quizzesAssigned;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @nA.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get nA;

  /// No description provided for @viewAllQuizzes.
  ///
  /// In en, this message translates to:
  /// **'View All Quizzes'**
  String get viewAllQuizzes;

  /// No description provided for @noQuizzesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No quizzes available'**
  String get noQuizzesAvailable;

  /// No description provided for @assignQuizToClass.
  ///
  /// In en, this message translates to:
  /// **'Assign Quiz to Class'**
  String get assignQuizToClass;

  /// No description provided for @createQuiz.
  ///
  /// In en, this message translates to:
  /// **'Create Quiz'**
  String get createQuiz;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data: {error}'**
  String errorLoadingData(String error);

  /// No description provided for @failedToLoadQuizStudentData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load quiz student data'**
  String get failedToLoadQuizStudentData;

  /// No description provided for @searchStudents.
  ///
  /// In en, this message translates to:
  /// **'Search students...'**
  String get searchStudents;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @editClassFocus.
  ///
  /// In en, this message translates to:
  /// **'Edit Class Focus'**
  String get editClassFocus;

  /// No description provided for @editFocusFor.
  ///
  /// In en, this message translates to:
  /// **'Edit Focus for \"{className}\"'**
  String editFocusFor(String className);

  /// No description provided for @youCanOnlyEditFocus.
  ///
  /// In en, this message translates to:
  /// **'You can only edit the focus of this class.'**
  String get youCanOnlyEditFocus;

  /// No description provided for @focusOptional.
  ///
  /// In en, this message translates to:
  /// **'Focus (Optional)'**
  String get focusOptional;

  /// No description provided for @selectFocusOptional.
  ///
  /// In en, this message translates to:
  /// **'Select focus'**
  String get selectFocusOptional;

  /// No description provided for @noneOptional.
  ///
  /// In en, this message translates to:
  /// **'None (Optional)'**
  String get noneOptional;

  /// No description provided for @classFocusUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Class focus updated successfully!'**
  String get classFocusUpdatedSuccessfully;

  /// No description provided for @failedToUpdateClassFocus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update class focus'**
  String get failedToUpdateClassFocus;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @searchStudentsByName.
  ///
  /// In en, this message translates to:
  /// **'Search students by name...'**
  String get searchStudentsByName;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @completion.
  ///
  /// In en, this message translates to:
  /// **'Completion'**
  String get completion;

  /// No description provided for @courseProgress.
  ///
  /// In en, this message translates to:
  /// **'Course Progress'**
  String get courseProgress;

  /// No description provided for @removeQuiz.
  ///
  /// In en, this message translates to:
  /// **'Remove Quiz'**
  String get removeQuiz;

  /// No description provided for @removeQuizConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this quiz from the class?'**
  String get removeQuizConfirmation;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @quizCreatedAndAssignedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Quiz created and assigned successfully'**
  String get quizCreatedAndAssignedSuccessfully;

  /// No description provided for @quizAssignedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Quiz assigned successfully'**
  String get quizAssignedSuccessfully;

  /// No description provided for @quizRemovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Quiz removed successfully'**
  String get quizRemovedSuccessfully;

  /// No description provided for @failedToRemoveQuiz.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove quiz'**
  String get failedToRemoveQuiz;

  /// No description provided for @failedToAssignQuiz.
  ///
  /// In en, this message translates to:
  /// **'Failed to assign quiz'**
  String get failedToAssignQuiz;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @quizText.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quizText;

  /// No description provided for @noName.
  ///
  /// In en, this message translates to:
  /// **'No Name'**
  String get noName;

  /// No description provided for @tapToViewStudentCompletion.
  ///
  /// In en, this message translates to:
  /// **'Tap to view student completion'**
  String get tapToViewStudentCompletion;

  /// No description provided for @createOrAssignQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Create or assign quizzes to get started'**
  String get createOrAssignQuizzes;

  /// No description provided for @createNewClass.
  ///
  /// In en, this message translates to:
  /// **'Create New Class'**
  String get createNewClass;

  /// No description provided for @editClassDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Class Details'**
  String get editClassDetails;

  /// No description provided for @className.
  ///
  /// In en, this message translates to:
  /// **'Class Name'**
  String get className;

  /// No description provided for @enterClassName.
  ///
  /// In en, this message translates to:
  /// **'Enter class name'**
  String get enterClassName;

  /// No description provided for @pleaseEnterClassName.
  ///
  /// In en, this message translates to:
  /// **'Please enter class name'**
  String get pleaseEnterClassName;

  /// No description provided for @classNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Class name required'**
  String get classNameRequired;

  /// No description provided for @enterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter description'**
  String get enterDescription;

  /// No description provided for @pleaseEnterDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter description'**
  String get pleaseEnterDescription;

  /// No description provided for @assignTeacherOptional.
  ///
  /// In en, this message translates to:
  /// **'Assign Teacher (Optional)'**
  String get assignTeacherOptional;

  /// No description provided for @selectTeacher.
  ///
  /// In en, this message translates to:
  /// **'Select teacher'**
  String get selectTeacher;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @enrollStudents.
  ///
  /// In en, this message translates to:
  /// **'Enroll Students'**
  String get enrollStudents;

  /// No description provided for @studentOptional.
  ///
  /// In en, this message translates to:
  /// **'Student {index} (Optional)'**
  String studentOptional(int index);

  /// No description provided for @selectStudent.
  ///
  /// In en, this message translates to:
  /// **'Select student'**
  String get selectStudent;

  /// No description provided for @addStudent.
  ///
  /// In en, this message translates to:
  /// **'Add Student'**
  String get addStudent;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @classCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Class created successfully!'**
  String get classCreatedSuccessfully;

  /// No description provided for @classUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Class updated successfully!'**
  String get classUpdatedSuccessfully;

  /// No description provided for @failedToCreateClass.
  ///
  /// In en, this message translates to:
  /// **'Failed to create class'**
  String get failedToCreateClass;

  /// No description provided for @failedToUpdateClass.
  ///
  /// In en, this message translates to:
  /// **'Failed to update class'**
  String get failedToUpdateClass;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @assignedLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assignedLabel;

  /// No description provided for @completedDate.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedDate;

  /// No description provided for @quizVisibility.
  ///
  /// In en, this message translates to:
  /// **'Quiz Visibility'**
  String get quizVisibility;

  /// No description provided for @selectQuizVisibility.
  ///
  /// In en, this message translates to:
  /// **'Select quiz visibility'**
  String get selectQuizVisibility;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ms'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ms':
      return AppLocalizationsMs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
