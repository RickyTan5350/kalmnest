import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'dart:io'; // For HttpOverrides
import 'package:flutter_codelab/admin_teacher/widgets/disappearing_navigation_rail.dart';
import 'package:flutter_codelab/admin_teacher/widgets/disappearing_bottom_navigation_bar.dart';
import 'package:flutter_codelab/admin_teacher/widgets/game/gamePages/create_game_page.dart';
import 'package:flutter_codelab/admin_teacher/widgets/note/admin_create_note_page.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/admin_create_class_page.dart';
import 'package:flutter_codelab/admin_teacher/widgets/user/create_account_form.dart';
import 'package:flutter_codelab/admin_teacher/widgets/achievements/admin_create_achievement_page.dart';
import 'package:flutter_codelab/admin_teacher/widgets/feedback/create_feedback.dart';
import 'package:flutter_codelab/admin_teacher/widgets/profile_header_content.dart';
import 'package:flutter_codelab/util.dart';
import 'package:flutter_codelab/theme.dart';
import 'package:flutter_codelab/destinations.dart';
import 'package:flutter_codelab/models/user_data.dart';
import 'package:flutter_codelab/pages/pages.dart';
import 'package:flutter_codelab/pages/login_page.dart';
import 'package:flutter_codelab/api/auth_api.dart';
import 'package:flutter_codelab/constants/api_constants.dart';

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

    return MaterialApp(
      debugShowCheckedModeBanner: false, // <--- ADD THIS LINE HERE
      theme: theme.light(),
      //darkTheme: theme.dark(),
      themeMode: ThemeMode.system,
      home: homeWidget, // Use the determined home widget
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
          title: const Text('Log out of your account?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            // Use FilledButton for the primary action (Logout)
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Logout'),
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
        'Class created successfully!',
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

  void _onAddButtonPressed() {
    final filteredDestinations = _getFilteredDestinations();
    if (selectedIndex >= filteredDestinations.length) return;
    
    final currentLabel = filteredDestinations[selectedIndex].label;

    switch (currentLabel) {
      case 'User':
        if (widget.currentUser.isStudent || widget.currentUser.isTeacher) {
          _showSnackBar(context, 'You do not have permission to create user accounts.', Theme.of(context).colorScheme.error);
        } else {
          showCreateUserAccountDialog(context: context, showSnackBar: _showSnackBar);
        }
        break;
      case 'Game':
        showCreateGamePage(context: context, showSnackBar: _showSnackBar, userRole: widget.currentUser.roleName);
        break;
      case 'Note':
        if (widget.currentUser.isStudent) {
          _showSnackBar(context, 'Students cannot add notes.', Theme.of(context).colorScheme.error);
        } else {
          showCreateNotesDialog(context: context, showSnackBar: _showSnackBar);
        }
        break;
      case 'Class':
        if (widget.currentUser.isAdmin) {
          _showCreateClassDialog();
        } else {
          _showSnackBar(context, 'You do not have access to this function', Theme.of(context).colorScheme.error);
        }
        break;
      case 'Achievement':
        if (widget.currentUser.isStudent) {
          _showSnackBar(context, 'You do not have access to this function', Theme.of(context).colorScheme.error);
        } else {
          showCreateAchievementDialog(context: context, showSnackBar: _showSnackBar);
        }
        break;
      case 'Feedback':
        if (!widget.currentUser.isTeacher) {
          _showSnackBar(context, 'You do not have access to create feedback', Theme.of(context).colorScheme.error);
        } else {
          showCreateFeedbackDialog(
            context: context,
            showSnackBar: _showSnackBar,
            onFeedbackAdded: (feedback) {},
            authToken: widget.currentUser.token ?? '',
          );
        }
        break;
      default:
        debugPrint("No 'add' action for $currentLabel");
    }
  }

  List<Destination> _getFilteredDestinations() {
    return destinations.where((d) {
      if (d.label == 'AI chat' && !widget.currentUser.isStudent) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = Color.alphaBlend(
      colorScheme.primary.withAlpha(36),
      colorScheme.surface,
    );
    final filteredDestinations = _getFilteredDestinations();
    final List<Widget> pages = [
      const UserPage(),
      GamePage(userRole: widget.currentUser.roleName),
      NotePage(currentUser: widget.currentUser),
      ClassPage(key: classPageGlobalKey, currentUser: widget.currentUser),
      AchievementPage(showSnackBar: _showSnackBar, currentUser: widget.currentUser),
      if (widget.currentUser.isStudent)
        AiChatPage(currentUser: widget.currentUser, authToken: widget.currentUser.token),
      FeedbackPage(authToken: widget.currentUser.token, currentUser: widget.currentUser),
    ];
    // --- END OF FIX ---

    final isChatPage = filteredDestinations[selectedIndex].label == 'AI chat';

    return Scaffold(
      body: Row(
        children: [
          if (wideScreen)
            DisappearingNavigationRail(
              selectedIndex: selectedIndex,
              backgroundColor: backgroundColor, // <-- Now uses the fresh color
              onDestinationSelected: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
              // REMOVED onLogoutPressed
              isExtended: _isRailExtended,
              onMenuPressed: () {
                setState(() {
                  _isRailExtended = !_isRailExtended;
                });
              },
              onAddButtonPressed: _onAddButtonPressed,
              destinations: filteredDestinations,
              showAddButton: !isChatPage,
            ),
          Expanded(
            child: Container(
              color: backgroundColor, // <-- Now uses the fresh color
              // MODIFIED: Always use a Column for header + content
              child: Column(
                children: [
                  // Profile Header (now always visible)
                  ProfileHeaderContent(
                    currentUser: widget.currentUser,
                    onLogoutPressed: _handleLogout,
                  ),
                  // Main Page Content (Preserve state using IndexedStack)
                  Expanded(
                    child: IndexedStack(
                      index: selectedIndex,
                      children: pages,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: wideScreen || isChatPage
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
              },
              destinations: filteredDestinations,
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
