import 'package:flutter/material.dart';
import 'util.dart';
import 'theme.dart';
import 'models/data.dart' as data;
import 'models/models.dart';
import 'widgets/disappearing_bottom_navigation_bar.dart';
import 'widgets/disappearing_navigation_rail.dart';
import 'pages/pages.dart';
import 'package:flutter_codelab/widgets/create_achievement_page.dart';
import 'package:flutter_codelab/widgets/create_feedback.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = createTextTheme(context, "Roboto Slab", "Roboto Slab");
    MaterialTheme theme = MaterialTheme(textTheme);
    return MaterialApp(
        theme: theme.light(), // <-- Uses your custom light colors + text
        darkTheme: theme.dark(), // <-- Uses your custom dark colors + text
        themeMode: ThemeMode.system,
        home: Feed(currentUser: data.user_0));
  }
}

class Feed extends StatefulWidget {
  const Feed({super.key, required this.currentUser});
  final User currentUser;
  @override
  State<Feed> createState() => _FeedState();
}


class _FeedState extends State<Feed> {
  // --- DELETE THE COLOR VARIABLES FROM HERE ---

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final double width = MediaQuery.of(context).size.width;
    wideScreen = width > 600;
  }
  void _onAddButtonPressed() {
   // This switch statement checks the currently selected page
   switch (selectedIndex) {
   case 4: // This is the index for 'AchievementPage'
    
    showCreateAchievementDialog(
          context: context,
          showSnackBar: _showSnackBar,
        );
    
  break;

   case 6: // This is the index for 'FeedbackPage'
    showCreateFeedbackDialog(
          context: context,
          showSnackBar: _showSnackBar,
          onFeedbackAdded: (feedback) {
            // Optionally do something after feedback is added
          },
          authToken: '', // TODO: Pass actual auth token from your auth provider
        );
    break;

   case 2: // This is the index for 'NotePage'
 // TODO: Create and navigate to a 'CreateNotePage'
{{// Navigator.push(
  //   context,
  //   MaterialPageRoute(builder: (context) => const CreateNotePage()),
 // );
 print('TODO: Open Create Note Page');
 break;}}

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
      const UserPage(), 
      const GamePage(), 
      const NotePage(),
      const ClassPage(), 
      const AchievementPage(), 
      const AiChatPage(), 
      // TODO: Pass actual auth token from your auth provider
      const FeedbackPage(authToken: null),
    ];

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
              isExtended: _isRailExtended,
              onMenuPressed: () {
                setState(() {
                  _isRailExtended = !_isRailExtended;
                },
                
                );
              },
              onAddButtonPressed: _onAddButtonPressed,
            ),
          Expanded(
            child: Container(
              color: backgroundColor, // <-- Now uses the fresh color
              child: pages[selectedIndex],
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