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
      themeMode: ThemeMode.light,
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
  void _showPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // This is the widget that will be displayed
        return AlertDialog(
          title: const Text('Custom Achievements'),
          content: const Text(''),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                // This closes the popup
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

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
                              const SizedBox(width: 10),
                              FilterChip(
                                label: Text(
                                  'PHP',
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
                                  'Level',
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
                                  'Quiz',
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

      floatingActionButton: FloatingActionButton.large(
        elevation: 8.0,
        onPressed: () {
          // Call Form
          showDialog(
            context: context,
            builder: (BuildContext context) {
              // You instantiate your class here
              return const AchievementFormDialog();
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AchievementFormDialog extends StatefulWidget {
  const AchievementFormDialog({super.key});

  @override
  State<AchievementFormDialog> createState() => _AchievementFormDialogState();
}

class _AchievementFormDialogState extends State<AchievementFormDialog> {
  // 1. Create a GlobalKey for the form
  final _formKey = GlobalKey<FormState>();

  // 2. Create controllers for the form fields
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  String? _selectedLevel;
  AchievementType? _selectedAchievementType;

  // 3. Remember to dispose of controllers
  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // 4. Create the submit logic
  void _submitForm() {
    // Validate the form
    if (_formKey.currentState!.validate()) {
      // Form is valid, do something with the data
      final String achievementName = _nameController.text;
      final String description = _descriptionController.text;

      print('Achievement Name: $achievementName');
      print('Description: $description');
      print('Category: $_selectedCategory');

      // Close the dialog and pass back data (optional)
      Navigator.of(context).pop(true); // Pop with a success flag
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Achievement'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min, // Make the dialog content shrink-wrap
          children: [
            // Field 1: Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Achievement Name',
                icon: Icon(Icons.emoji_events),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Field 2: Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Displaying Achievment Title',
                icon: Icon(Icons.description),
              ),
              maxLines: 2, // Optional: for a larger text field
            ),
            const SizedBox(height: 16),

             TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Achievement Description',
                icon: Icon(Icons.description),
              ),
              maxLines: 2, // Optional: for a larger text field
            ),
            const SizedBox(height: 16),

            // Field 3: Description
            // Inside your Column:

          Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Aligns icon with the top
            children: [
              // 1. The icon
              Padding(
                padding: const EdgeInsets.only(top: 8.0), // Adjust to vertically align
                child: const Icon(Icons.category),
              ),

              // 2. The space
              const SizedBox(width: 16),

              // 3. The DropdownMenu
              Expanded(
                child: DropdownMenu<String>(
                  width: MediaQuery.of(context).size.width * 0.2,
                  label: const Text('Category'),
                  onSelected: (String? value) {
                    // ...
                  },
                  dropdownMenuEntries: const <DropdownMenuEntry<String>>[
                    DropdownMenuEntry(value: 'html', label: 'HTML'),
                    DropdownMenuEntry(value: 'css', label: 'CSS'),
                    DropdownMenuEntry(value: 'js', label: 'JS'),
                  ],
                ),
              ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Aligns icon with the top
              children: [
                // 1. The icon
                Padding(
                  padding: const EdgeInsets.only(
                    top: 8.0,
                  ), // Adjust to vertically align
                  child: const Icon(Icons.category),
                ),

                // 2. The space
                const SizedBox(width: 16),

                // 3. The DropdownMenu
                Expanded(
                  child: DropdownMenu<String>(
                    width: MediaQuery.of(context).size.width * 0.2,
                    label: const Text('Level Name'),
                    onSelected: (String? value) {
                      setState(() {
                        _selectedLevel = value;
                      });
                    },
                    dropdownMenuEntries: const <DropdownMenuEntry<String>>[
                      DropdownMenuEntry(
                        value: 'html',
                        label: 'Placeholder Level 1',
                      ),
                      DropdownMenuEntry(
                        value: 'css',
                        label: 'Placeholder Level 2',
                      ),
                      DropdownMenuEntry(
                        value: 'js',
                        label: 'Placeholder Level 3',
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Field 4: Category
            
            const SizedBox(height: 16),

            

            const SizedBox(height: 16),
            AchievementTypeRadio(
              initialValue: _selectedAchievementType,
              onTypeSelected: (AchievementType? newType) {
                // Save the new type to your state variable
                setState(() {
                  _selectedAchievementType = newType;
                });
              },
            ),
          ],
        ),
      ),

      actions: <Widget>[
        // Cancel Button
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(); // Just close the dialog
          },
        ),
        // Save Button
        FilledButton(
          onPressed: _submitForm, // Call the submit logic
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// 1. Define the options for your radio buttons
enum AchievementType { level, quiz }

// 2. This is the reusable widget class
class AchievementTypeRadio extends StatefulWidget {
  const AchievementTypeRadio({
    super.key,
    this.initialValue,
    required this.onTypeSelected,
  });

  // Use this to pre-select a value (e.g., when editing a form)
  final AchievementType? initialValue;

  // This is the callback function to send the data back to the parent form
  final void Function(AchievementType? selectedType) onTypeSelected;

  @override
  State<AchievementTypeRadio> createState() => _AchievementTypeRadioState();
}

class _AchievementTypeRadioState extends State<AchievementTypeRadio> {
  // 3. This variable holds the currently selected value
  AchievementType? _selectedType;

  @override
  void initState() {
    super.initState();
    // 4. Set the initial value when the widget is first created
    _selectedType = widget.initialValue;
  }

  // 5. This function updates the state and calls the callback
  void _onChanged(AchievementType? value) {
    setState(() {
      _selectedType = value;
    });
    // Send the new value back to the parent widget
    widget.onTypeSelected(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A simple label for the group
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0, top: 16.0),
          child: Text(
            'Achievement Type',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),

        // 6. The RadioListTile widgets
        RadioListTile<AchievementType>(
          title: const Text('Level'),
          subtitle: const Text('A single level in the syllabus'),
          value: AchievementType.level,
          groupValue: _selectedType,
          onChanged: _onChanged,
        ),
        RadioListTile<AchievementType>(
          title: const Text('Quiz'),
          subtitle: const Text('A custom quiz'),
          value: AchievementType.quiz,
          groupValue: _selectedType,
          onChanged: _onChanged,
        ),
      ],
    );
  }
}
