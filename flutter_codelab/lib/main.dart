import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

import 'package:code_play/l10n/generated/app_localizations.dart';
import 'package:code_play/controllers/locale_controller.dart';

import 'package:code_play/admin_teacher/widgets/disappearing_navigation_rail.dart';
import 'package:code_play/destinations.dart';
import 'package:code_play/admin_teacher/widgets/game/gamePages/create_game_page.dart';
import 'package:code_play/admin_teacher/widgets/note/admin_create_note_page.dart';
import 'package:code_play/admin_teacher/widgets/class/admin_create_class_page.dart';
import 'package:code_play/admin_teacher/widgets/user/create_account_form.dart';
import 'package:code_play/admin_teacher/widgets/achievements/admin_create_achievement_page.dart';
import 'package:code_play/admin_teacher/widgets/feedback/create_feedback.dart';
import 'package:code_play/admin_teacher/widgets/user/profile_header_content.dart';

import 'package:code_play/util.dart';
import 'package:code_play/theme.dart';

import 'package:code_play/models/user_data.dart';

import 'package:code_play/pages/pages.dart';
import 'package:code_play/pages/user_page.dart'; // Explicit import for key
import 'package:code_play/pages/login_page.dart';
import 'package:code_play/pages/game_page.dart';

import 'package:code_play/api/auth_api.dart';
import 'package:code_play/constants/api_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:code_play/config/http_setup.dart'; // New import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  print('--- CONFIGURATION DEBUG ---');
  print('ApiConstants.customBaseUrl: ${ApiConstants.customBaseUrl}');
  print('ApiConstants.baseUrl: ${ApiConstants.baseUrl}');
  print('ApiConstants.domain: ${ApiConstants.domain}');
  print('kDebugMode: $kDebugMode');
  print('---------------------------');

  if (kDebugMode) {
    setupHttpOverrides();
  }

  // Check for stored token and user data
  // Variable name: storedUserJson
  await const FlutterSecureStorage().deleteAll();
  final storedUserJson = await AuthApi.getStoredUser();
  final token = await AuthApi.getToken();

  UserDetails? initialUser;
  if (storedUserJson != null) {
    if (token != null) {
      storedUserJson['token'] = token;
    }
    initialUser = UserDetails.fromJson(storedUserJson);
  }

  runApp(MainApp(initialUser: initialUser));
}

// Update MainApp to accept the initial user state
class MainApp extends StatelessWidget {
  final UserDetails? initialUser;
  const MainApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = createTextTheme(
      context,
      "Roboto Slab",
      "Roboto Slab",
    );
    MaterialTheme theme = MaterialTheme(textTheme);

    // Determine the starting page based on the stored user data
    final Widget homeWidget = initialUser != null
        ? Feed(currentUser: initialUser!) // Go straight to feed if logged in
        : const LoginPage(); // Go to login if not logged in

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.instance,
      builder: (context, locale, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          theme: theme.light(),
          darkTheme: theme.dark(),
          themeMode: ThemeMode.system,
          home: homeWidget,
        );
      },
    );
  }
}

class Feed extends StatefulWidget {
  const Feed({super.key, required this.currentUser});
  final UserDetails currentUser; // Now uses UserDetails
  @override
  State<Feed> createState() => _FeedState();
}

class _FeedState extends State<Feed> {
  // ... (Rest of FeedState is unchanged) ...

  int selectedIndex = 0;
  bool wideScreen = false;
  bool _isRailExtended = false;

  void _showSnackBar(BuildContext context, String message, Color color) {
    // Ensure we are operating within a Scaffold's context
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Clear any current snackbar to show the new one immediately
    scaffoldMessenger.hideCurrentSnackBar();

    // Show the new SnackBar
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
          ), // Ensures text is readable
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4), // Display time
        behavior:
            SnackBarBehavior.floating, // For better appearance on wider screens
      ),
    );
  }

  // NEW: Confirmation Dialog
  Future<bool?> _confirmLogout() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(dialogContext)!.logoutConfirmation),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(AppLocalizations.of(dialogContext)!.cancel),
            ),
            // Use FilledButton for the primary action (Logout)
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(AppLocalizations.of(dialogContext)!.logout),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    // 1. Show confirmation dialog and wait for result
    final bool? confirmed = await _confirmLogout();

    if (confirmed != true) {
      return; // User cancelled the operation
    }

    // 2. Proceed with logout only if confirmed
    try {
      await AuthApi.logout(widget.currentUser.id);
    } catch (e) {
      // Log the error but continue with navigation,
      // as local storage clearance is critical and should have happened.
      print('Logout API call failed, but continuing to clear session: $e');
    }

    if (mounted) {
      // Navigate back to the LoginPage and clear the navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false, // Predicate: Remove all routes below
      );
    }
  }

  Future<void> _showCreateClassDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateClassScreen()),
    );

    // If class was created successfully, reload the class list
    if (result == true) {
      // Use GlobalKey to access ClassPage's reload method (similar to feedback callback)
      classPageGlobalKey.currentState?.reloadClassList();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final double width = MediaQuery.of(context).size.width;
    wideScreen = width > 600;
  }

  // Get filtered destinations based on user role
  List<Destination> _getFilteredDestinations() {
    final bool isStudent = widget.currentUser.isStudent;
    return destinations.where((dest) {
      // Hide AI chat for teachers and admins
      if (dest.label == 'AI chat' && !isStudent) {
        return false;
      }
      return true;
    }).toList();
  }

  // Get original destination index from filtered index
  int _getOriginalIndex(int filteredIndex) {
    final filteredDestinations = _getFilteredDestinations();
    if (filteredIndex < 0 || filteredIndex >= filteredDestinations.length) {
      return -1;
    }
    final filteredDest = filteredDestinations[filteredIndex];
    return destinations.indexOf(filteredDest);
  }

  void _onAddButtonPressed() {
    final originalIndex = _getOriginalIndex(selectedIndex);

    // This switch statement checks the currently selected page
    switch (originalIndex) {
      case 0: // This is the index for 'UserPage' (Index 0)
        // CHECK if the current user is a Student OR a Teacher
        if (widget.currentUser.isStudent || widget.currentUser.isTeacher) {
          _showSnackBar(
            context,
            AppLocalizations.of(context)!.noPermissionCreateUser,
            Theme.of(context).colorScheme.error,
          );
        } else {
          // Only Admins can see the options
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return SimpleDialog(
                title: Text(AppLocalizations.of(context)!.selectAction),
                children: [
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      showCreateUserAccountDialog(
                        context: context,
                        showSnackBar: _showSnackBar,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.person_add),
                          const SizedBox(width: 12),
                          Text(AppLocalizations.of(context)!.createUserProfile),
                        ],
                      ),
                    ),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      // Trigger import via GlobalKey
                      userPageGlobalKey.currentState?.importUsers();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.file_upload),
                          const SizedBox(width: 12),
                          Text(AppLocalizations.of(context)!.importUserProfile),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
        break;

      case 1:
        // Block students from creating games
        if (widget.currentUser.isStudent) {
          _showSnackBar(
            context,
            AppLocalizations.of(context)!.studentsCannotCreateGames,
            Theme.of(context).colorScheme.error,
          );
        } else {
          showCreateGamePage(
            context: context,
            showSnackBar: _showSnackBar,
            userRole: widget.currentUser.roleName,
          );
        }
        break;
      case 2:
        if (widget.currentUser.isStudent) {
          // 2. BLOCK: Show error message
          _showSnackBar(
            context,
            AppLocalizations.of(context)!.studentsCannotAddNotes,
            Theme.of(context).colorScheme.error,
          );
        } else {
          // 3. ALLOW: Open dialog if Admin
          showCreateNotesDialog(context: context, showSnackBar: _showSnackBar);
        }
        break;

      case 3: // This is the index for 'ClassPage'
        if (widget.currentUser.isAdmin) {
          _showCreateClassDialog();
        } else {
          _showSnackBar(
            context,
            AppLocalizations.of(context)!.noAccessFunction,
            Theme.of(context).colorScheme.error,
          );
        }
        break;

      case 4: // This is the index for 'AchievementPage'
        if (widget.currentUser.isStudent) {
          _showSnackBar(
            context,
            AppLocalizations.of(context)!.noAccessFunction,
            Theme.of(context).colorScheme.error,
          );
        } else {
          showCreateAchievementDialog(
            context: context,
            showSnackBar: _showSnackBar,
          );
        }
        break;
      case 6: // This is the index for 'Feedback'
        if (widget.currentUser.isStudent || widget.currentUser.isAdmin) {
          _showSnackBar(
            context,
            AppLocalizations.of(context)!.accessDeniedCreateFeedback,
            Theme.of(context).colorScheme.error,
          );
        } else {
          showCreateFeedbackDialog(
            context: context,
            showSnackBar: _showSnackBar,
            onFeedbackAdded: (feedback) {
              // Optionally do something after feedback is added
            },
            authToken: widget.currentUser.token,
          );
        }
        break;
      default:
        print("No 'add' action for index $selectedIndex");
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- ADD THE COLOR AND PAGE VARIABLES HERE ---
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = Color.alphaBlend(
      colorScheme.primary.withAlpha(36),
      colorScheme.surface,
    );

    // Filter destinations and pages based on user role
    // Only students can access AI chat
    final bool isStudent = widget.currentUser.isStudent;
    final List<Destination> filteredDestinations = _getFilteredDestinations();

    // Build pages list matching filtered destinations
    final List<Widget> pages = [];
    for (final dest in filteredDestinations) {
      switch (dest.label) {
        case 'User':
          pages.add(
            UserPage(key: userPageGlobalKey, currentUser: widget.currentUser),
          );
          break;
        case 'Game':
          pages.add(
            GamePage(
              key: gamePageGlobalKey,
              userRole: widget.currentUser.roleName,
            ),
          );
          break;
        case 'Note':
          pages.add(NotePage(currentUser: widget.currentUser));
          break;
        case 'Class':
          pages.add(
            ClassPage(key: classPageGlobalKey, currentUser: widget.currentUser),
          );
          break;
        case 'Achievement':
          pages.add(
            AchievementPage(
              showSnackBar: _showSnackBar,
              currentUser: widget.currentUser,
            ),
          );
          break;
        case 'AI chat':
          if (isStudent) {
            pages.add(
              AiChatPage(
                currentUser: widget.currentUser,
                authToken: widget.currentUser.token,
              ),
            );
          }
          break;
        case 'Feedback':
          pages.add(
            FeedbackPage(
              authToken: widget.currentUser.token,
              currentUser: widget.currentUser,
            ),
          );
          break;
      }
    }

    // Adjust selectedIndex if it's out of bounds or points to hidden AI chat
    if (selectedIndex >= filteredDestinations.length) {
      selectedIndex = 0;
    } else if (!isStudent && _getOriginalIndex(selectedIndex) == 5) {
      // If AI chat was selected but user is not student, go to first page
      selectedIndex = 0;
    }

    bool isChatPage =
        isStudent &&
        selectedIndex < filteredDestinations.length &&
        filteredDestinations[selectedIndex].label == 'AI chat';

    return Scaffold(
      backgroundColor:
          backgroundColor, // ADDED: Match background preventing white gaps
      body: Column(
        children: [
          // Profile Header (now always visible at the top)
          Container(
            color: backgroundColor,
            child: ProfileHeaderContent(
              currentUser: widget.currentUser,
              onLogoutPressed: _handleLogout,
              onMenuPressed: () {
                setState(() {
                  _isRailExtended = !_isRailExtended;
                });
              },
            ),
          ),
          // Main Body: Sidebar + Content
          Expanded(
            child: Row(
              children: [
                if (wideScreen)
                  DisappearingNavigationRail(
                    selectedIndex: selectedIndex,
                    backgroundColor: backgroundColor,
                    destinations: filteredDestinations,
                    onDestinationSelected: (index) {
                      setState(() {
                        selectedIndex = index;
                      });
                      // Refresh GamePage when navigating to it
                      final dest = filteredDestinations[index];
                      if (dest.label == 'Game') {
                        gamePageGlobalKey.currentState?.refresh();
                      }
                    },
                    isExtended: _isRailExtended,
                    onAddButtonPressed: isChatPage ? null : _onAddButtonPressed,
                  ),
                Expanded(
                  child: Container(
                    color: backgroundColor,
                    child: pages[selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: (wideScreen || isChatPage)
          ? null
          : FloatingActionButton(
              backgroundColor: colorScheme.tertiaryContainer,
              foregroundColor: colorScheme.onTertiaryContainer,
              onPressed: _onAddButtonPressed,
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: wideScreen
          ? null
          : BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) {
                setState(() {
                  selectedIndex = index;
                });
                // Refresh GamePage when navigating to it
                final dest = filteredDestinations[index];
                if (dest.label == 'Game') {
                  gamePageGlobalKey.currentState?.refresh();
                }
              },
              type: BottomNavigationBarType.fixed,
              items: filteredDestinations.asMap().entries.map((entry) {
                final index = entry.key;
                final dest = entry.value;
                final l10n = AppLocalizations.of(context)!;
                final labelMap = {
                  'User': l10n.users,
                  'Game': l10n.games,
                  'Note': l10n.notes,
                  'Class': l10n.classes,
                  'Achievement': l10n.achievements,
                  'AI chat': l10n.aiChat,
                  'Feedback': l10n.feedback,
                };
                return BottomNavigationBarItem(
                  icon: Icon(
                    selectedIndex == index ? dest.selectedIcon : dest.icon,
                  ),
                  label: labelMap[dest.label] ?? dest.label,
                );
              }).toList(),
            ),
    );
  }
}
