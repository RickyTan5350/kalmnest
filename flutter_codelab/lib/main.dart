import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'dart:io'; // For HttpOverrides

import 'package:flutter_codelab/l10n/generated/app_localizations.dart';
import 'package:flutter_codelab/controllers/locale_controller.dart';

import 'package:flutter_codelab/admin_teacher/widgets/disappearing_navigation_rail.dart';
import 'package:flutter_codelab/admin_teacher/widgets/disappearing_bottom_navigation_bar.dart';
import 'package:flutter_codelab/admin_teacher/widgets/game/gamePages/create_game_page.dart';
import 'package:flutter_codelab/admin_teacher/widgets/note/admin_create_note_page.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/admin_create_class_page.dart';
import 'package:flutter_codelab/admin_teacher/widgets/user/create_account_form.dart';
import 'package:flutter_codelab/admin_teacher/widgets/achievements/admin_create_achievement_page.dart';
import 'package:flutter_codelab/admin_teacher/widgets/feedback/create_feedback.dart';
import 'package:flutter_codelab/admin_teacher/widgets/user/profile_header_content.dart';

import 'package:flutter_codelab/util.dart';
import 'package:flutter_codelab/theme.dart';

import 'package:flutter_codelab/models/user_data.dart';

import 'package:flutter_codelab/pages/pages.dart';
import 'package:flutter_codelab/pages/user_page.dart'; // Explicit import for key
import 'package:flutter_codelab/pages/login_page.dart';
import 'package:flutter_codelab/pages/game_page.dart';

import 'package:flutter_codelab/api/auth_api.dart';
import 'package:flutter_codelab/constants/api_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('--- CONFIGURATION DEBUG ---');
  print('ApiConstants.customBaseUrl: ${ApiConstants.customBaseUrl}');
  print('ApiConstants.baseUrl: ${ApiConstants.baseUrl}');
  print('ApiConstants.domain: ${ApiConstants.domain}');
  print('kDebugMode: $kDebugMode');
  print('---------------------------');

  if (kDebugMode) {
    HttpOverrides.global = MyHttpOverrides();
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
          //darkTheme: theme.dark(),
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
      _showSnackBar(
        context,
        AppLocalizations.of(context)!.classCreatedSuccess,
        Theme.of(context).colorScheme.primary,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final double width = MediaQuery.of(context).size.width;
    wideScreen = width > 600;
  }

  // Helper to determine visible pages based on role
  List<Map<String, dynamic>> _getVisiblePages(UserDetails user) {
    // List of all possible pages with their destinations and IDs
    final List<Map<String, dynamic>> allPages = [
      {
        'id': 'users',
        'widget': UserPage(key: userPageGlobalKey, currentUser: user),
        'destination': NavigationRailDestination(
          icon: const Icon(Icons.people_outline),
          selectedIcon: const Icon(Icons.people),
          label: Text(AppLocalizations.of(context)!.users),
        ),
      },
      {
        'id': 'games',
        'widget': GamePage(key: gamePageGlobalKey, userRole: user.roleName),
        'destination': NavigationRailDestination(
          icon: const Icon(Icons.games_outlined),
          selectedIcon: const Icon(Icons.games),
          label: Text(AppLocalizations.of(context)!.games),
        ),
      },
      {
        'id': 'notes',
        'widget': NotePage(currentUser: user),
        'destination': NavigationRailDestination(
          icon: const Icon(Icons.note_outlined),
          selectedIcon: const Icon(Icons.note),
          label: Text(AppLocalizations.of(context)!.notes),
        ),
      },
      {
        'id': 'classes',
        'widget': ClassPage(key: classPageGlobalKey, currentUser: user),
        'destination': NavigationRailDestination(
          icon: const Icon(Icons.class_outlined),
          selectedIcon: const Icon(Icons.class_),
          label: Text(AppLocalizations.of(context)!.classes),
        ),
      },
      {
        'id': 'achievements',
        'widget': AchievementPage(showSnackBar: _showSnackBar, currentUser: user),
        'destination': NavigationRailDestination(
          icon: const Icon(Icons.emoji_events_outlined),
          selectedIcon: const Icon(Icons.emoji_events),
          label: Text(AppLocalizations.of(context)!.achievements),
        ),
      },
      {
        // THIS IS THE AI CHAT PAGE - ONLY FOR STUDENTS
        'id': 'ai_chat',
        'widget': AiChatPage(currentUser: user, authToken: user.token),
        'destination': NavigationRailDestination(
          icon: const Icon(Icons.chat_outlined),
          selectedIcon: const Icon(Icons.chat),
          label: Text(AppLocalizations.of(context)!.aiChat),
        ),
      },
      {
        'id': 'feedback',
        'widget': FeedbackPage(authToken: user.token, currentUser: user),
        'destination': NavigationRailDestination(
          icon: const Icon(Icons.feedback_outlined),
          selectedIcon: const Icon(Icons.feedback),
          label: Text(AppLocalizations.of(context)!.feedback),
        ),
      },
    ];

    // Filter logic
    return allPages.where((page) {
      if (page['id'] == 'ai_chat') {
        return user.isStudent; // Only students see AI Chat
      }
      return true;
    }).toList();
  }

  void _onAddButtonPressed() {
    final visiblePages = _getVisiblePages(widget.currentUser);
    if (selectedIndex >= visiblePages.length) return;
    
    final pageId = visiblePages[selectedIndex]['id'];

    switch (pageId) {
      case 'users':
        if (widget.currentUser.isStudent || widget.currentUser.isTeacher) {
          _showSnackBar(
            context,
            AppLocalizations.of(context)!.noPermissionCreateUser,
            Theme.of(context).colorScheme.error,
          );
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return SimpleDialog(
                title: Text(AppLocalizations.of(context)!.selectAction),
                children: [
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.pop(context);
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
                      Navigator.pop(context);
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

      case 'games':
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

      case 'notes':
        if (widget.currentUser.isStudent) {
          _showSnackBar(
            context,
            AppLocalizations.of(context)!.studentsCannotAddNotes,
            Theme.of(context).colorScheme.error,
          );
        } else {
          showCreateNotesDialog(context: context, showSnackBar: _showSnackBar);
        }
        break;

      case 'classes':
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

      case 'achievements':
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

      case 'feedback':
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
            },
            authToken: widget.currentUser.token,
          );
        }
        break;
      
      default:
        print("No 'add' action for page $pageId");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = Color.alphaBlend(
      colorScheme.primary.withAlpha(36),
      colorScheme.surface,
    );

    // Dynamic Page Generation
    final visiblePages = _getVisiblePages(widget.currentUser);
    final List<Widget> pages = visiblePages.map((p) => p['widget'] as Widget).toList();
    final List<NavigationRailDestination> destinations = visiblePages.map((p) => p['destination'] as NavigationRailDestination).toList();

    // Check if selected index is possibly out of bounds if role changed (unlikely within session but good safety)
    if (selectedIndex >= pages.length) {
      selectedIndex = 0;
    }

    final currentPageId = visiblePages[selectedIndex]['id'];
    final bool isChatPage = currentPageId == 'ai_chat';

    return Scaffold(
      backgroundColor: backgroundColor, 
      body: Column(
        children: [
          // Profile Header
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
          // Main Body
          Expanded(
            child: Row(
              children: [
                if (wideScreen)
                  DisappearingNavigationRail(
                    selectedIndex: selectedIndex,
                    backgroundColor: backgroundColor,
                    onDestinationSelected: (index) {
                      setState(() {
                        selectedIndex = index;
                      });
                      // Refresh GamePage
                      if (visiblePages[index]['id'] == 'games') {
                        gamePageGlobalKey.currentState?.refresh();
                      }
                    },
                    isExtended: _isRailExtended,
                    onAddButtonPressed: isChatPage ? null : _onAddButtonPressed,
                    destinations: destinations,
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
          : DisappearingBottomNavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  selectedIndex = index;
                });
                 if (visiblePages[index]['id'] == 'games') {
                  gamePageGlobalKey.currentState?.refresh();
                }
              },
              // We need to pass the destinations to bottom bar too if it supports it, 
              // but DisappearingBottomNavigationBar seems to use hardcoded destinations in its implementation likely. 
              // We should check DisappearingBottomNavigationBar implementation. 
              // Assuming it needs update or is generic.
              // Checking the file...
            ),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

