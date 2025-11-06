import 'package:flutter/material.dart';
import 'theme/theme.dart';
import 'theme/util.dart';
// Import your new page
import 'pages/all_note.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = createTextTheme(context, "Roboto Slab", "Roboto Slab");
    MaterialTheme noteTheme = MaterialTheme(textTheme);

    return MaterialApp(
      title: 'Note',
      theme: noteTheme.light(),
      darkTheme: noteTheme.dark(),
      themeMode: ThemeMode.system,
      // Home is now the MainScreen, which controls navigation
      home: const MainScreen(),
    );
  }
}

// This new widget manages the state of the app (which page is selected)
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 0 = Upload Note, 1 = All Notes
  int _selectedIndex = 0;

  // List of the pages to show
  static const List<Widget> _pages = <Widget>[
    UploadNotePage(), // The form page
    AllNotesPage(),   // The new "All Notes" page
  ];

  /// Builds the top Application Bar
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('NOTE', style: TextStyle(fontWeight: FontWeight.bold)),
      actions: [
        Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('John Doe',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Teacher', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(width: 12),
            const CircleAvatar(
              child: Icon(Icons.person),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ],
    );
  }

  /// Builds the static left-side navigation panel
  Widget _buildSidePanel() {
    return Container(
      width: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // Handle back navigation
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Upload Note'),
            selected: _selectedIndex == 0, // Selected if index is 0
            onTap: () {
              // Update the state to show page 0
              setState(() {
                _selectedIndex = 0;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('All Notes'),
            selected: _selectedIndex == 1, // Selected if index is 1
            onTap: () {
              // Update the state to show page 1
              setState(() {
                _selectedIndex = 1;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Row(
        children: [
          // 1. Left Side Navigation Panel
          _buildSidePanel(),
          // Divider
          const VerticalDivider(width: 1, thickness: 1),
          // 2. Main Content
          // This Expanded widget now shows the currently selected page
          Expanded(
            child: _pages.elementAt(_selectedIndex),
          ),
        ],
      ),
    );
  }
}

// This is your original form, just moved into its own widget
// This is your original form, just moved into its own widget
class UploadNotePage extends StatefulWidget {
  const UploadNotePage({super.key});

  @override
  State<UploadNotePage> createState() => _UploadNotePageState();
}

class _UploadNotePageState extends State<UploadNotePage> {
  // State variables to manage form inputs
  String? _selectedTopic;
  bool _isNoteVisible = true;
  final _formKey = GlobalKey<FormState>();

  // Dummy data for the dropdown
  final List<String> _topics = ['HTML', 'CSS', 'JAVASCRIPT', 'PHP'];

  @override
  Widget build(BuildContext context) {
    // The main form content is now the root widget
    return Padding(
      // 1. This Padding adds space AROUND the card
      padding: const EdgeInsets.all(24.0),
      child: Card(
        // 2. This is the new Card widget
        // You can adjust elevation, shape, etc., based on your theme
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          // You might want a slight border to match your theme
          // side: BorderSide(color: Colors.grey[300]!) 
        ),
        clipBehavior: Clip.antiAlias, // Ensures content respects the rounded corners
        child: SingleChildScrollView(
          child: Padding(
            // 3. This Padding adds space INSIDE the card
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Upload New Note',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  //Text(
                  //'Add educational materials: interactive code lessons and markdown notes',
                  //style: Theme.of(context).textTheme.titleSmall,
                  //),
                  const SizedBox(height: 24),

                  // Topic Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedTopic,
                    decoration: const InputDecoration(
                      labelText: 'Topic *',
                    ),
                    hint: const Text('Select a topic'),
                    items: _topics.map((String topic) {
                      return DropdownMenuItem<String>(
                        value: topic,
                        child: Text(topic),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedTopic = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Title Field
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      hintText: 'Select existing or type new title',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Markdown & Media Section
                  const Text('Markdown Notes (Optional)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Media Files',
                          style: TextStyle(color: Colors.black54)),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Upload Media'),
                        onPressed: () {
                          // Handle media upload
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Live Preview
                  const Text('Live Preview',
                      style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Text('hi'),
                  ),
                  const SizedBox(height: 24),

                  // Interactive Code Editor
                  const Text('Code Editor (Optional)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Text(
                      'Please select a topic first to enable the code editor',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Upload By Field
                  TextFormField(
                    initialValue: 'John Doe',
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Upload By *',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Visibility Toggle
                  SwitchListTile(
                    title: const Text('Note Visibility'),
                    subtitle: const Text('Make this note visible to students'),
                    value: _isNoteVisible,
                    onChanged: (bool value) {
                      setState(() {
                        _isNoteVisible = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    activeColor: Colors.blue,
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload Note'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        // Handle form submission
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}