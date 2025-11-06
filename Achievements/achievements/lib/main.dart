import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/theme.dart';

// const seedColor = Color(0xFF73EDEF);

// final ThemeData lightTheme = ThemeData(
//   useMaterial3: true,
//   colorScheme: ColorScheme.fromSeed(
//     seedColor: seedColor,
//     brightness: Brightness.light,
//   )
// );

// final ThemeData darkTheme = ThemeData(
//   useMaterial3: true,
//   colorScheme: ColorScheme.fromSeed(
//     seedColor: seedColor,
//     brightness: Brightness.dark,
//   ),
// );

final TextTheme robotoTheme = GoogleFonts.robotoTextTheme();

final MaterialTheme achievementsTheme = MaterialTheme(robotoTheme);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Achievements',
      // Use the 'light()' method for the light theme
      theme: achievementsTheme.light(),

      // Use the 'dark()' method for the dark theme
      darkTheme: achievementsTheme.dark(),
      themeMode: ThemeMode.system,
      home: const MyAchievementsPage(),
    );
  }
}

// You would place this inside your main.dart or a new file.
class MyAchievementsPage extends StatefulWidget {
  const MyAchievementsPage({super.key});

  @override
  State<MyAchievementsPage> createState() => _MyAchievementsPageState();
}

class _MyAchievementsPageState extends State<MyAchievementsPage> {
  // This holds the state for the NavigationRail
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Get the color scheme from the theme
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      // The AppBar is separate from the body
      appBar: AppBar(title: const Text('Achievements App')),

      // This is the full body you were building
      body: Row(
        children: [
          NavigationRail(
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                // Add logic here to open a drawer
              },
            ),

            // ADD THIS LINE TO CENTER THE DESTINATIONS
            groupAlignment: 0.0,

            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },

            labelType: NavigationRailLabelType.all,

            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.emoji_events_outlined),
                selectedIcon: Icon(Icons.emoji_events),
                label: Text('Achievements'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.star_border),
                selectedIcon: Icon(Icons.star),
                label: Text('Label'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.star_border),
                selectedIcon: Icon(Icons.star),
                label: Text('Label'),
              ),
            ],
          ),

          // 2. EXPANDED CARD
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 28.0,
                  left: 36.0,
                  right: 28.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ROW 1: Back and More Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {},
                        ),
                      ],
                    ),

                    // ROW 2: Title
                    Padding(
                      padding: const EdgeInsets.only(left: 24.0, top: 27.0),
                      child: Text(
                        "Achievements",
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 28,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ROW 3: Chips and Search Bar
                    Padding(
                      padding: const EdgeInsets.only(left: 24.0, top: 27.0),
                      child: Row(
                        children: [
                          // Left side: Filter Chips
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              FilterChip(
                                label: Text(
                                  'HTML',
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontSize: 14,
                                    fontFamily: 'Roboto',
                                    letterSpacing: 0.10,
                                  ),
                                ),
                                selected: false,
                                onSelected: (bool selected) {},
                              ),
                              const SizedBox(width: 10),
                              FilterChip(
                                label: Text(
                                  'CSS',
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontSize: 14,
                                    fontFamily: 'Roboto',
                                    letterSpacing: 0.10,
                                  ),
                                ),
                                selected: true,
                                onSelected: (bool selected) {},
                              ),
                              const SizedBox(width: 10),
                              FilterChip(
                                label: Text(
                                  'JS',
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontSize: 14,
                                    fontFamily: 'Roboto',
                                    letterSpacing: 0.10,
                                  ),
                                ),
                                selected: false,
                                onSelected: (bool selected) {},
                              ),
                            ],
                          ),

                          // Middle: Spacer
                          const Spacer(),

                          // Right side: Search Bar
                          SizedBox(
                            width: 300, // Fixed width for the search bar
                            child: SearchBar(
                              leading: IconButton(
                                icon: const Icon(Icons.menu),
                                onPressed: () {},
                              ),
                              hintText: "Achievement Name",
                              trailing: <Widget>[
                                IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
