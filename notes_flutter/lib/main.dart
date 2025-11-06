import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Figma to Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006399)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
      ),
      home: const TopicListPage(), // <--- Starts on Page 1
      debugShowCheckedModeBanner: false,
    );
  }
}

// ===================================================================
//
// PAGE 1: TOPIC LIST SCREEN
// (Based on your first design)
//
// ===================================================================

class TopicListPage extends StatefulWidget {
  const TopicListPage({super.key});

  @override
  State<TopicListPage> createState() => _TopicListPageState();
}

class _TopicListPageState extends State<TopicListPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail on the left
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.note_outlined),
                selectedIcon: Icon(Icons.note),
                label: Text('Note'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.military_tech_outlined),
                selectedIcon: Icon(Icons.military_tech),
                label: Text('Achievements'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.label_outline),
                selectedIcon: Icon(Icons.label),
                label: Text('Label'),
              ),
            ],
          ),

          // Main content area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: _buildCustomAppBar(),
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilterChips(),
                      const SizedBox(height: 16),
                      _buildSearchRow(),
                      const SizedBox(height: 24),
                      // This main card is now clickable
                      _buildMainCard(context),
                      const SizedBox(height: 24),
                      // This list of items is now clickable
                      _buildSubItemList(context),
                    ],
                  ),
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () {},
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets for Page 1 ---

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          const Text(
            'Note',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(label: const Text('3.1 HTML'), selected: false, onSelected: (s) {}),
          const SizedBox(width: 8),
          ChoiceChip(label: const Text('3.2 CSS'), selected: true, onSelected: (s) {}, selectedColor: Theme.of(context).colorScheme.primaryContainer),
          const SizedBox(width: 8),
          ChoiceChip(label: const Text('JS'), selected: false, onSelected: (s) {}),
          const SizedBox(width: 8),
          ChoiceChip(label: const Text('PHP'), selected: false, onSelected: (s) {}),
          const SizedBox(width: 8),
          IconButton.outlined(icon: const Icon(Icons.add), onPressed: () {}, iconSize: 18)
        ],
      ),
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        TextButton.icon(icon: const Icon(Icons.topic_outlined), label: const Text('Topic'), onPressed: () {}),
        const Spacer(),
        IconButton(icon: const Icon(Icons.search), onPressed: () {}),
      ],
    );
  }

  // MODIFIED: Wrapped in InkWell to make it clickable
  Widget _buildMainCard(BuildContext context) {
    return InkWell(
      onTap: () {
        // --- NAVIGATION CODE ---
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NoteDetailPage()),
        );
      },
      child: Card(
        color: Colors.grey[200],
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 150,
                decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(8.0)),
                child: Center(child: Icon(Icons.image_aspect_ratio, size: 60, color: Colors.grey[600])),
              ),
              const SizedBox(height: 16),
              const Text('BAB 3.1: CSS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text('Subtitle'),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton.icon(icon: const Icon(Icons.edit_outlined), label: const Text('EDIT'), onPressed: () {}),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('DELETE'),
                    onPressed: () {},
                    style: FilledButton.styleFrom(backgroundColor: Colors.grey[400], foregroundColor: Colors.black),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubItemList(BuildContext context) {
    return Column(
      children: [
        _buildSubItem(
          context: context,
          title: '3.1.1',
          subtitle: 'Category • S\$ - 1.2 miles away',
        ),
        const Divider(),
        _buildSubItem(
          context: context,
          title: '3.1.2',
          subtitle: 'Category • S\$ - 1.2 miles away',
        ),
        const Divider(),
        _buildSubItem(
          context: context,
          title: '3.1.3',
          subtitle: 'Category • S\$ - 1.2 miles away',
        ),
      ],
    );
  }

  // MODIFIED: Added onTap to make it clickable
  Widget _buildSubItem({
    required BuildContext context,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.image_outlined, color: Colors.grey[500]),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: IconButton(icon: const Icon(Icons.favorite_border_outlined), onPressed: () {}),
      contentPadding: EdgeInsets.zero,
      onTap: () {
        // --- NAVIGATION CODE ---
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NoteDetailPage()),
        );
      },
    );
  }
}

// ===================================================================
//
// PAGE 2: NOTE DETAIL SCREEN
// (Based on your second design)
//
// ===================================================================

class NoteDetailPage extends StatefulWidget {
  const NoteDetailPage({super.key});

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  int _selectedIndex = 0;
  String _selectedItemTitle = '3.1.1'; // Default selected item

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(icon: Icon(Icons.note_outlined), selectedIcon: Icon(Icons.note), label: Text('Note')),
              NavigationRailDestination(icon: Icon(Icons.military_tech_outlined), selectedIcon: Icon(Icons.military_tech), label: Text('Achievements')),
              NavigationRailDestination(icon: Icon(Icons.label_outline), selectedIcon: Icon(Icons.label), label: Text('Label')),
            ],
          ),
          // Main content area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.0)),
              child: Row(
                children: [
                  // --- LEFT PANEL (Master List) ---
                  Expanded(
                    flex: 1,
                    child: Scaffold(
                      backgroundColor: Colors.transparent,
                      body: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPage2CustomAppBar(),
                            _buildPage2FilterChips(),
                            const SizedBox(height: 16),
                            _buildPage2SearchRow(),
                            const SizedBox(height: 24),
                            _buildPage2SubItemList(),
                          ],
                        ),
                      ),
                      floatingActionButton: FloatingActionButton(
                        onPressed: () {}, // This button doesn't navigate
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1.0, thickness: 1.0),
                  // --- RIGHT PANEL (Detail View) ---
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: _buildDetailContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets for Page 2 ---

  Widget _buildPage2CustomAppBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          // This back button will take you to Page 1
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context); // Goes back to the previous screen
            },
          ),
          const Text('Note', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('5/11/2025', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {})
        ],
      ),
    );
  }

  Widget _buildPage2FilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(label: const Text('HTML'), selected: false, onSelected: (s) {}),
          const SizedBox(width: 8),
          ChoiceChip(label: const Text('CSS'), selected: true, onSelected: (s) {}, selectedColor: Theme.of(context).colorScheme.primaryContainer),
          const SizedBox(width: 8),
          ChoiceChip(label: const Text('JS'), selected: false, onSelected: (s) {}),
          const SizedBox(width: 8),
          ChoiceChip(label: const Text('PHP'), selected: false, onSelected: (s) {}),
        ],
      ),
    );
  }

  Widget _buildPage2SearchRow() {
    return Row(
      children: [
        TextButton.icon(icon: const Icon(Icons.topic_outlined), label: const Text('Topic'), onPressed: () {}),
        const Spacer(),
        IconButton(icon: const Icon(Icons.search), onPressed: () {}),
      ],
    );
  }

  Widget _buildPage2SubItemList() {
    return Column(
      children: [
        _buildPage2SubItem(title: '3.1.1', subtitle: 'Supporting line text lorem...', time: '5/11/2025', isSelected: _selectedItemTitle == '3.1.1'),
        const Divider(),
        _buildPage2SubItem(title: '3.1.2', subtitle: 'Supporting line text lorem...', time: '10 min', isSelected: _selectedItemTitle == '3.1.2'),
        const Divider(),
        _buildPage2SubItem(title: '3.1.3', subtitle: 'Supporting line text lorem...', time: '10 min', isSelected: _selectedItemTitle == '3.1.3'),
        const Divider(),
        _buildPage2SubItem(title: '3.1.4', subtitle: 'Supporting line text lorem...', time: '10 min', isSelected: _selectedItemTitle == '3.1.4'),
      ],
    );
  }

  Widget _buildPage2SubItem({
    required String title,
    required String subtitle,
    required String time,
    required bool isSelected,
  }) {
    return ListTile(
      tileColor: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(time, style: Theme.of(context).textTheme.bodySmall),
      onTap: () {
        setState(() {
          _selectedItemTitle = title;
        });
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    );
  }

  Widget _buildDetailContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_selectedItemTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('5/11/2025 9.44 p.m', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 24),
        _buildLoremIpsumText(),
        const SizedBox(height: 16),
        _buildLoremIpsumText(),
        const SizedBox(height: 16),
        _buildLoremIpsumText(),
        const SizedBox(height: 16),
        _buildLoremIpsumText(),
        const SizedBox(height: 32),
        _buildUploadSection(),
      ],
    );
  }

  Widget _buildLoremIpsumText() {
    return const Text(
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
      style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
    );
  }

  Widget _buildUploadSection() {
    return Column(
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12.0)),
          child: Center(child: Icon(Icons.group_work_outlined, size: 60, color: Colors.grey[500])),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             FilledButton.tonalIcon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload'),
              onPressed: () {},
            ),
            const SizedBox(width: 12),
             FilledButton.tonalIcon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}