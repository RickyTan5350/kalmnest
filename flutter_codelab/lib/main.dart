import 'package:flutter/material.dart';
import 'util.dart';
import 'theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/data.dart' as data;
import 'models/models.dart';
import 'widgets/disappearing_bottom_navigation_bar.dart'; // Add import
import 'widgets/disappearing_navigation_rail.dart'; // Add import
import 'widgets/email_list_view.dart';

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
      theme: theme.light(),     // <-- Uses your custom light colors + text
      darkTheme: theme.dark(),  // <-- Uses your custom dark colors + text
      themeMode: ThemeMode.system,
      home: Feed(currentUser: data.user_0)
    );
  }
}

class Feed extends StatefulWidget {
  const Feed({super.key, required this.currentUser});

  final User currentUser;

  @override
  State<Feed> createState() => _FeedState();
}

class _FeedState extends State<Feed> {
  late final _colorScheme = Theme.of(context).colorScheme;
  late final _backgroundColor = Color.alphaBlend(
    _colorScheme.primary.withAlpha(36),
    _colorScheme.surface,
  );

  int selectedIndex = 0;
 
  bool wideScreen = false;

  bool _isRailExtended = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final double width = MediaQuery.of(context).size.width;
    wideScreen = width > 600;
  }
 

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: Row(
        children: [
          if (wideScreen)
            DisappearingNavigationRail(
              selectedIndex: selectedIndex,
              backgroundColor: _backgroundColor,
              onDestinationSelected: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
              isExtended: _isRailExtended,
              onMenuPressed: () {
                setState(() {
                  _isRailExtended = !_isRailExtended;
                });
              },
            ),
          
          Expanded(
            child: Container(
              color: _backgroundColor,
              child: EmailListView(
                selectedIndex: selectedIndex,
                onSelected: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                currentUser: widget.currentUser,
              ),
            ),
          ),
        ], 
      ), 
      floatingActionButton: wideScreen
          ? null
          : FloatingActionButton(
              backgroundColor: _colorScheme.tertiaryContainer,
              foregroundColor: _colorScheme.onTertiaryContainer,
              onPressed: () {},
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