import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_codelab/models/user_data.dart';

// 1. Import Admin View normally
import 'package:flutter_codelab/admin_teacher/widgets/note/admin_view_note_page.dart';

// 2. Import Student View but HIDE conflicting enums
import 'package:flutter_codelab/student/widgets/note/student_view_page.dart' hide ViewLayout, SortType, SortOrder;

class NotePage extends StatefulWidget {
  final UserDetails currentUser;

  const NotePage({super.key, required this.currentUser});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  final List<String> _topics = ['All', 'HTML', 'CSS', 'JS', 'PHP'];
  String _selectedTopic = 'All'; 
  String _searchQuery = ''; 
  ViewLayout _viewLayout = ViewLayout.grid; 

  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _activateSearch() {
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): _activateSearch,
      },
      child: Focus(
        autofocus: true,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                // FIX: Align everything to the left (Start) instead of Center
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Notes", style: Theme.of(context).textTheme.headlineMedium),
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.search), onPressed: _activateSearch),
                          const SizedBox(width: 8),
                          SegmentedButton<ViewLayout>(
                            segments: const [
                              ButtonSegment(value: ViewLayout.list, icon: Icon(Icons.menu)),
                              ButtonSegment(value: ViewLayout.grid, icon: Icon(Icons.grid_view)),
                            ],
                            selected: {_viewLayout},
                            onSelectionChanged: (val) => setState(() => _viewLayout = val.first),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Search Bar (Left Aligned due to Column crossAxis) ---
                  SizedBox(
                    width: 300,
                    child: SearchBar(
                      focusNode: _searchFocusNode,
                      hintText: "Search topic or title",
                      onChanged: (val) => setState(() => _searchQuery = val),
                      leading: const Icon(Icons.search), // Optional: Adds search icon inside bar like image 2
                      trailing: [
                        if (_searchQuery.isNotEmpty)
                          IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchQuery = '')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Filter Chips (Left Aligned) ---
                  Wrap(
                    spacing: 10,
                    runSpacing: 10, // Good practice if they wrap to next line
                    alignment: WrapAlignment.start, // Explicitly align start
                    children: _topics.map((topic) => FilterChip(
                      label: Text(topic),
                      selected: _selectedTopic == topic,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedTopic = topic);
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 16),

                  // --- Body ---
                  Expanded(
                    child: widget.currentUser.isStudent
                        ? StudentViewPage(
                            topic: _selectedTopic == 'All' ? '' : _selectedTopic,
                            query: _searchQuery,
                            isGrid: _viewLayout == ViewLayout.grid, 
                          )
                        : AdminViewNotePage(
                            layout: _viewLayout,
                            topic: _selectedTopic == 'All' ? '' : _selectedTopic, 
                            query: _searchQuery, 
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