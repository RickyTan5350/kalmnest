import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_codelab/models/user_data.dart';

// 1. Import Admin View normally
import 'package:flutter_codelab/admin_teacher/widgets/note/admin_view_note_page.dart';

// 2. Import Student View but HIDE conflicting enums
import 'package:flutter_codelab/student/widgets/note/student_view_page.dart';
import 'package:flutter_codelab/enums/sort_enums.dart';

import 'package:flutter_codelab/enums/view_layout.dart';

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
  SortType _sortType = SortType.alphabetical;
  SortOrder _sortOrder = SortOrder.ascending;

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
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _activateSearch,
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
                      Text(
                        "Notes",
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Row(
                        children: [
                          SegmentedButton<ViewLayout>(
                            segments: const [
                              ButtonSegment(
                                value: ViewLayout.list,
                                icon: Icon(Icons.menu),
                              ),
                              ButtonSegment(
                                value: ViewLayout.grid,
                                icon: Icon(Icons.grid_view),
                              ),
                            ],
                            selected: {_viewLayout},
                            onSelectionChanged: (val) =>
                                setState(() => _viewLayout = val.first),
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
                      leading: const Icon(
                        Icons.search,
                      ), // Optional: Adds search icon inside bar like image 2
                      trailing: [
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ''),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Filter Chips & Sort Button ---
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.start,
                          children: _topics
                              .map(
                                (topic) => FilterChip(
                                  label: Text(topic),
                                  selected: _selectedTopic == topic,
                                  onSelected: (selected) {
                                    if (selected)
                                      setState(() => _selectedTopic = topic);
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      // Sort/Filter Menu Function in Icon
                      PopupMenuButton<void>(
                        icon: const Icon(Icons.filter_list_rounded),
                        tooltip: "Sort Options",
                        itemBuilder: (context) => <PopupMenuEntry<void>>[
                          const PopupMenuItem(
                            enabled: false,
                            child: Text(
                              "Sort By",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            child: ListTile(
                              leading: Icon(
                                _sortType == SortType.alphabetical
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                size: 20,
                              ),
                              title: const Text("Name"),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              onTap: () {
                                setState(
                                  () => _sortType = SortType.alphabetical,
                                );
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          PopupMenuItem(
                            child: ListTile(
                              leading: Icon(
                                _sortType == SortType.number
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                size: 20,
                              ),
                              title: const Text("ID"),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              onTap: () {
                                setState(() => _sortType = SortType.number);
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            child: ListTile(
                              leading: Icon(
                                _sortOrder == SortOrder.ascending
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 20,
                              ),
                              title: Text(
                                _sortOrder == SortOrder.ascending
                                    ? "Ascending"
                                    : "Descending",
                              ),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              onTap: () {
                                setState(() {
                                  _sortOrder = _sortOrder == SortOrder.ascending
                                      ? SortOrder.descending
                                      : SortOrder.ascending;
                                });
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Body ---
                  Expanded(
                    child: widget.currentUser.isStudent
                        ? StudentViewPage(
                            topic: _selectedTopic == 'All'
                                ? ''
                                : _selectedTopic,
                            query: _searchQuery,
                            isGrid: _viewLayout == ViewLayout.grid,
                            sortType: _sortType,
                            sortOrder: _sortOrder,
                          )
                        : AdminViewNotePage(
                            layout: _viewLayout,
                            topic: _selectedTopic == 'All'
                                ? ''
                                : _selectedTopic,
                            query: _searchQuery,
                            sortType: _sortType,
                            sortOrder: _sortOrder,
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
