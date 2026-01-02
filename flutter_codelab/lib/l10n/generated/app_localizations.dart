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
  /// **'Student'**
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

  /// No description provided for @feedbacks.
  ///
  /// In en, this message translates to:
  /// **'Feedbacks'**
  String get feedbacks;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @noFeedbackFound.
  ///
  /// In en, this message translates to:
  /// **'No feedback found.'**
  String get noFeedbackFound;

  /// No description provided for @sortByTime.
  ///
  /// In en, this message translates to:
  /// **'Sort by Time'**
  String get sortByTime;

  /// No description provided for @newestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get newestFirst;

  /// No description provided for @oldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest First'**
  String get oldestFirst;

  /// No description provided for @refreshFeedbacks.
  ///
  /// In en, this message translates to:
  /// **'Refresh Feedbacks'**
  String get refreshFeedbacks;

  /// No description provided for @filterByStudent.
  ///
  /// In en, this message translates to:
  /// **'Filter by Student'**
  String get filterByStudent;

  /// No description provided for @allStudents.
  ///
  /// In en, this message translates to:
  /// **'All Students'**
  String get allStudents;

  /// No description provided for @filterByTeacher.
  ///
  /// In en, this message translates to:
  /// **'Filter by Teacher'**
  String get filterByTeacher;

  /// No description provided for @allTeachers.
  ///
  /// In en, this message translates to:
  /// **'All Teachers'**
  String get allTeachers;

  /// No description provided for @deleteFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Feedback?'**
  String get deleteFeedbackTitle;

  /// No description provided for @deleteFeedbackConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this feedback? This action cannot be undone.'**
  String get deleteFeedbackConfirmation;

  /// No description provided for @feedbackDeleted.
  ///
  /// In en, this message translates to:
  /// **'Feedback deleted'**
  String get feedbackDeleted;

  /// No description provided for @editFeedback.
  ///
  /// In en, this message translates to:
  /// **'Edit Feedback'**
  String get editFeedback;

  /// No description provided for @currentTopic.
  ///
  /// In en, this message translates to:
  /// **'Current Topic'**
  String get currentTopic;

  /// No description provided for @discardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes?'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesConfirmation.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to discard them?'**
  String get discardChangesConfirmation;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @changesSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Changes saved successfully!'**
  String get changesSavedSuccess;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed: {error}'**
  String updateFailed(String error);

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From: {name}'**
  String from(String name);

  /// No description provided for @failedToLoadStudents.
  ///
  /// In en, this message translates to:
  /// **'Failed to load students: {error}'**
  String failedToLoadStudents(String error);

  /// No description provided for @pleaseSelectStudent.
  ///
  /// In en, this message translates to:
  /// **'Please select a student'**
  String get pleaseSelectStudent;

  /// No description provided for @feedbackSentTo.
  ///
  /// In en, this message translates to:
  /// **'Feedback sent to {name}'**
  String feedbackSentTo(String name);

  /// No description provided for @accessDeniedCreateFeedback.
  ///
  /// In en, this message translates to:
  /// **'Access Denied: Only teachers can create feedback.'**
  String get accessDeniedCreateFeedback;

  /// No description provided for @newFeedback.
  ///
  /// In en, this message translates to:
  /// **'New Feedback'**
  String get newFeedback;

  /// No description provided for @selectStudent.
  ///
  /// In en, this message translates to:
  /// **'Select Student'**
  String get selectStudent;

  /// No description provided for @selectAStudent.
  ///
  /// In en, this message translates to:
  /// **'Select a student'**
  String get selectAStudent;

  /// No description provided for @noStudentsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No students available'**
  String get noStudentsAvailable;

  /// No description provided for @selectTopic.
  ///
  /// In en, this message translates to:
  /// **'Select Topic'**
  String get selectTopic;

  /// No description provided for @selectATopic.
  ///
  /// In en, this message translates to:
  /// **'Select a topic'**
  String get selectATopic;

  /// No description provided for @pleaseSelectTopic.
  ///
  /// In en, this message translates to:
  /// **'Please select a topic'**
  String get pleaseSelectTopic;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Great Job!'**
  String get titleHint;

  /// No description provided for @pleaseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterTitle;

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Write your feedback here...'**
  String get feedbackHint;

  /// No description provided for @pleaseWriteFeedback.
  ///
  /// In en, this message translates to:
  /// **'Please write feedback'**
  String get pleaseWriteFeedback;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @errorLoadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Error loading history: {error}'**
  String errorLoadingHistory(String error);

  /// No description provided for @errorLoadingMessages.
  ///
  /// In en, this message translates to:
  /// **'Error loading messages: {error}'**
  String errorLoadingMessages(String error);

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clearHistory;

  /// No description provided for @clearHistoryConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this chat session?'**
  String get clearHistoryConfirmation;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String deleteFailed(String error);

  /// No description provided for @aiChatTitle.
  ///
  /// In en, this message translates to:
  /// **'KalmNest AI (Gemini-2.0-flash)'**
  String get aiChatTitle;

  /// No description provided for @howCanIHelp.
  ///
  /// In en, this message translates to:
  /// **'How can I help you today?'**
  String get howCanIHelp;

  /// No description provided for @askQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask Question'**
  String get askQuestion;

  /// No description provided for @recentQuestions.
  ///
  /// In en, this message translates to:
  /// **'Recent Questions'**
  String get recentQuestions;

  /// No description provided for @noQuestionsFound.
  ///
  /// In en, this message translates to:
  /// **'No previous questions found.'**
  String get noQuestionsFound;

  /// No description provided for @untitledQuestion.
  ///
  /// In en, this message translates to:
  /// **'Untitled Question'**
  String get untitledQuestion;

  /// No description provided for @quickSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Quick Learning Suggestions'**
  String get quickSuggestions;

  /// No description provided for @suggestionPrefix.
  ///
  /// In en, this message translates to:
  /// **'Give me Learning Suggestion for '**
  String get suggestionPrefix;

  /// No description provided for @typeQuestionHint.
  ///
  /// In en, this message translates to:
  /// **'Type your question...'**
  String get typeQuestionHint;

  /// No description provided for @backToHistory.
  ///
  /// In en, this message translates to:
  /// **'Back to History'**
  String get backToHistory;

  /// No description provided for @refreshQuestion.
  ///
  /// In en, this message translates to:
  /// **'Refresh Question'**
  String get refreshQuestion;

  /// No description provided for @deleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete Chat'**
  String get deleteChat;
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
