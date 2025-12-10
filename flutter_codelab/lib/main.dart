import 'package:flutter/material.dart';
import 'package:flutter_codelab/admin_teacher/widgets/note/admin_create_note_page.dart';
import 'util.dart';
import 'theme.dart';
import 'package:flutter_codelab/admin_teacher/widgets/disappearing_bottom_navigation_bar.dart';
import 'package:flutter_codelab/admin_teacher/widgets/disappearing_navigation_rail.dart';
import 'pages/pages.dart';
import 'package:flutter_codelab/admin_teacher//widgets/achievements/admin_create_achievement_page.dart';
import 'package:flutter_codelab/admin_teacher/widgets/create_account_form.dart';
import 'package:flutter_codelab/pages/login_page.dart';
import 'models/user_data.dart';
import 'api/auth_api.dart';
import 'package:flutter_codelab/admin_teacher/widgets/profile_header_content.dart'; // NEW IMPORT

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check for stored token and user data
  // Variable name: storedUserJson
  final storedUserJson = await AuthApi.getStoredUser();

  // Reference the correct variable name here: storedUserJson
  final UserDetails? initialUser = storedUserJson != null
      ? UserDetails.fromJson(storedUserJson)
      : null;

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
      darkTheme: theme.dark(),
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final double width = MediaQuery.of(context).size.width;
    wideScreen = width > 600;
  }

  void _onAddButtonPressed() {
    // This switch statement checks the currently selected page
    switch (selectedIndex) {
      case 0: // This is the index for 'UserPage' (Index 0)
      // ADD THIS CASE FOR USER PAGE
        showCreateUserAccountDialog(
          context: context,
          showSnackBar: _showSnackBar,
        );
        break;
      case 2:
       if (widget.currentUser.isStudent) {
          // 2. BLOCK: Show error message
          _showSnackBar(
            context,
            'Students cannot add notes. This is for Admins only.',
            Theme.of(context).colorScheme.error,
          );
        } else {
          // 3. ALLOW: Open dialog if Admin
          showCreateNotesDialog(
            context: context,
            showSnackBar: _showSnackBar,
          );
        }
        break;

        

      case 4: // This is the index for 'AchievementPage'
        if(widget.currentUser.isStudent){
          _showSnackBar(context, 'You do not have access to this function', Theme.of(context).colorScheme.error);
        }else{
          showCreateAchievementDialog(
            context: context,
            showSnackBar: _showSnackBar,
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

    final List<Widget> pages = [
      const UserPage(), // Index 0
      const GamePage(), // Index 1
      NotePage(
        currentUser: widget.currentUser,
      ),
      const ClassPage(), //utter Index 3
      AchievementPage(
        showSnackBar: _showSnackBar,
        currentUser: widget.currentUser,
      ), // Index 4
      const AiChatPage(), // Index 5
    ];
    // --- END OF FIX ---

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
                  // Main Page Content (Expanded to fill the remaining space)
                  Expanded(
                    child: pages[selectedIndex],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: wideScreen
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
      ),
    );
  }
}